const express = require('express');
const router = express.Router();
const { query, run } = require('../db/database');
const { authenticateToken } = require('../middleware/auth');
const xgboostService = require('../services/xgboost.service');
const notificationService = require('../services/notification.service');

// Proteger todas las rutas de reservas con autenticación flexible
router.use(authenticateToken);

// Listar reservas del usuario autenticado (o todas si es admin/empresa)
router.get('/', (req, res) => {
  const userId = req.user.id;
  const userRole = req.user.role;

  let sql;
  let params = [];

  if (userRole === 'admin' || userRole === 'company' || userId === 'guest-user') {
    sql = `SELECT b.*, r.name as restaurant_name, r.address as restaurant_address 
           FROM bookings b 
           JOIN restaurants r ON b.restaurant_id = r.id 
           ORDER BY b.created_at DESC`;
  } else {
    sql = `SELECT b.*, r.name as restaurant_name, r.address as restaurant_address 
           FROM bookings b 
           JOIN restaurants r ON b.restaurant_id = r.id 
           WHERE b.user_id = ? 
           ORDER BY b.created_at DESC`;
    params = [userId];
  }

  const bookings = query(sql, params);
  res.json(bookings);
});

// Crear reserva con validación de aforo y cálculo de ocupación real para XGBoost
router.post('/', (req, res) => {
  const userId = req.user.id || 'user-default-1';
  const {
    restaurant_id,
    guest_name,
    guest_phone,
    booking_date,
    booking_time,
    party_size,
    special_requests,
    deposit_amount
  } = req.body;

  if (!restaurant_id || !booking_date || !booking_time) {
    return res.status(400).json({ error: 'Restaurante, fecha y hora son obligatorios' });
  }

  const partySizeNum = parseInt(party_size, 10) || 2;
  if (partySizeNum < 1 || partySizeNum > 20) {
    return res.status(400).json({ error: 'La cantidad de personas debe ser entre 1 y 20' });
  }

  // 1. Obtener restaurante y su aforo total
  const restList = query('SELECT * FROM restaurants WHERE id = ?', [restaurant_id]);
  if (restList.length === 0) {
    return res.status(404).json({ error: 'Restaurante no encontrado' });
  }
  const restaurant = restList[0];
  const maxCapacity = restaurant.capacity || 50;

  // 2. Comprobar aforo ocupado en la misma fecha y hora
  const activeBookings = query(
    `SELECT SUM(party_size) as total_booked 
     FROM bookings 
     WHERE restaurant_id = ? 
       AND booking_date = ? 
       AND booking_time = ? 
       AND status IN ('confirmed', 'seated')`,
    [restaurant_id, booking_date, booking_time]
  );
  
  const currentOccupied = activeBookings[0]?.total_booked || 0;
  const availableSeats = maxCapacity - currentOccupied;

  if (partySizeNum > availableSeats) {
    return res.status(409).json({
      error: 'Aforo completo para este horario',
      availableSeats: Math.max(0, availableSeats),
      requestedSeats: partySizeNum
    });
  }

  // 3. Inferencia de Descuento Dinámico XGBoost con ocupación real
  const realOccupancyRate = currentOccupied / maxCapacity;
  const mlResult = xgboostService.predict({
    occupancyRate: parseFloat(realOccupancyRate.toFixed(2)),
    isPeakHour: booking_time >= '19:30' && booking_time <= '21:30' ? 1 : 0,
    leadTimeHours: 6,
    dayOfWeek: new Date(booking_date).getDay(),
    partySize: partySizeNum,
    userLoyaltyScore: 0.85
  });

  const appliedDiscount = mlResult.discountPercentage;
  const deposit = parseFloat(deposit_amount) || 0.0;
  const depositStatus = deposit > 0 ? 'paid' : 'unpaid';

  const id = 'book-' + Date.now().toString(36) + Math.random().toString(36).substring(2, 5);
  const qr_code = `KUCINA-RES-${id.toUpperCase()}`;

  // 4. Insertar reserva persistente
  run(`INSERT INTO bookings (
    id, user_id, restaurant_id, guest_name, guest_phone,
    booking_date, booking_time, party_size, applied_discount,
    deposit_amount, deposit_status, status, special_requests, qr_code
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
    id, userId, restaurant_id, guest_name || req.user.name || 'Cliente Kucina',
    guest_phone || req.user.phone || '999888777', booking_date,
    booking_time, partySizeNum, appliedDiscount,
    deposit, depositStatus, 'confirmed', special_requests || '', qr_code
  ]);

  const bookingData = {
    id,
    user_id: userId,
    guest_name: guest_name || req.user.name || 'Cliente Kucina',
    guest_phone: guest_phone || req.user.phone || '999888777',
    booking_date,
    booking_time,
    party_size: partySizeNum,
    applied_discount: appliedDiscount,
    deposit_amount: deposit
  };

  const whatsappMessage = notificationService.formatBookingMessage(bookingData, restaurant.name);
  const directWhatsAppUrl = notificationService.generateDirectWhatsAppLink(bookingData.guest_phone, whatsappMessage);

  // 5. Imprimir en el terminal del servidor
  console.log(`\n============================================================`);
  console.log(`🛎️  NUEVA RESERVA RECIBIDA DESDE LA APP KUCINA`);
  console.log(`👤 Comensal: ${bookingData.guest_name} | 📞 Teléfono: ${bookingData.guest_phone}`);
  console.log(`🍽️  Restaurante: ${restaurant.name} (${restaurant.district})`);
  console.log(`📅 Fecha: ${booking_date} | ⏰ Hora: ${booking_time} | 👥 Personas: ${partySizeNum}`);
  console.log(`🔥 Descuento XGBoost: ${appliedDiscount}% OFF | 💳 Depósito: S/ ${deposit.toFixed(2)} (${depositStatus})`);
  console.log(`🎫 Código Ticket: #${id.toUpperCase()} | QR: ${qr_code}`);
  console.log(`============================================================\n`);

  res.status(201).json({
    success: true,
    booking: {
      ...bookingData,
      restaurant_name: restaurant.name,
      status: 'confirmed',
      qr_code
    },
    ml_metrics: {
      occupancyRateCalculated: realOccupancyRate,
      appliedDiscount
    },
    notifications: {
      directWhatsAppUrl,
      whatsappMessage
    }
  });
});

module.exports = router;

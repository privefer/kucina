const express = require('express');
const router = express.Router();
const { query, run } = require('../db/database');
const { authenticateToken } = require('../middleware/auth');
const xgboostService = require('../services/xgboost.service');
const notificationService = require('../services/notification.service');

// Optional auth bypass for local dashboard view
router.use((req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (authHeader) {
    return authenticateToken(req, res, () => {
      if (req.user && (req.user.role === 'company' || req.user.role === 'admin')) {
        return next();
      }
      return res.status(403).json({ error: 'Acceso restringido a restaurantes autorizados' });
    });
  }
  next();
});

// Full Company & XGBoost Metrics Dashboard
router.get('/dashboard', (req, res) => {
  const totalBookings = query('SELECT COUNT(*) as count FROM bookings')[0]?.count || 0;
  const seatedToday = query("SELECT COUNT(*) as count FROM bookings WHERE status = 'seated'")[0]?.count || 0;
  const activeRestaurants = query('SELECT COUNT(*) as count FROM restaurants WHERE is_active = 1')[0]?.count || 0;
  const totalDepositsCollected = query("SELECT SUM(deposit_amount) as total FROM bookings WHERE deposit_status = 'paid'")[0]?.total || 0;
  
  // XGBoost ML Dynamic Metrics
  const avgDiscountResult = query('SELECT AVG(applied_discount) as avg_disc FROM bookings')[0]?.avg_disc || 0;
  const maxDiscountGiven = query('SELECT MAX(applied_discount) as max_disc FROM bookings')[0]?.max_disc || 0;
  
  // Recent Bookings enriched with direct WhatsApp links
  const recentBookings = query(`
    SELECT b.*, r.name as restaurant_name, r.address as restaurant_address 
    FROM bookings b 
    JOIN restaurants r ON b.restaurant_id = r.id 
    ORDER BY b.created_at DESC 
    LIMIT 20
  `).map(b => {
    const formattedMsg = notificationService.formatBookingMessage(b, b.restaurant_name);
    const directWhatsAppUrl = notificationService.generateDirectWhatsAppLink(b.guest_phone, formattedMsg);
    return {
      ...b,
      formatted_whatsapp_message: formattedMsg,
      direct_whatsapp_url: directWhatsAppUrl
    };
  });

  // Restaurants live occupancy
  const restaurantsList = query('SELECT * FROM restaurants WHERE is_active = 1').map(r => {
    const bookedSeats = query(
      `SELECT SUM(party_size) as total FROM bookings WHERE restaurant_id = ? AND status IN ('confirmed', 'seated')`,
      [r.id]
    )[0]?.total || 0;
    const occupancyRate = (bookedSeats / (r.capacity || 50)) * 100;
    
    return {
      id: r.id,
      name: r.name,
      district: r.district,
      capacity: r.capacity,
      bookedSeats,
      occupancyPercentage: Math.min(100, Math.round(occupancyRate))
    };
  });

  res.json({
    totalBookings,
    seatedToday,
    activeRestaurants,
    totalDepositsCollected,
    xgboostMetrics: {
      modelName: 'XGBoost_GBDT_v2.4_Production',
      averageDiscountApplied: Math.round(avgDiscountResult),
      maxDiscountCapEnforced: '30%',
      maxDiscountObserved: maxDiscountGiven,
      treesCount: 8,
      learningRate: 0.15,
      featuresTracked: ['occupancyRate', 'isPeakHour', 'leadTimeHours', 'partySize', 'userLoyaltyScore']
    },
    restaurantsList,
    recentBookings
  });
});

// Quick Check-in via QR or ID
router.post('/checkin', (req, res) => {
  const { qr_code, booking_id } = req.body;
  if (!qr_code && !booking_id) {
    return res.status(400).json({ error: 'Código QR o ID de reserva requerido' });
  }

  let booking;
  if (qr_code) {
    const list = query('SELECT * FROM bookings WHERE qr_code = ?', [qr_code.trim()]);
    booking = list[0];
  } else if (booking_id) {
    const list = query('SELECT * FROM bookings WHERE id = ?', [booking_id.trim()]);
    booking = list[0];
  }

  if (!booking) {
    return res.status(404).json({ error: 'Reserva no encontrada con este código' });
  }

  run("UPDATE bookings SET status = 'seated' WHERE id = ?", [booking.id]);
  res.json({
    success: true,
    message: `Check-in exitoso para ${booking.guest_name}. Comensal sentado en mesa.`,
    bookingId: booking.id,
    newStatus: 'seated'
  });
});

// Update booking status
router.post('/status', (req, res) => {
  const { booking_id, status } = req.body;
  if (!booking_id || !['confirmed', 'seated', 'completed', 'cancelled', 'no_show'].includes(status)) {
    return res.status(400).json({ error: 'ID de reserva y estado válido requeridos' });
  }
  run('UPDATE bookings SET status = ? WHERE id = ?', [status, booking_id]);
  res.json({ success: true, bookingId: booking_id, status });
});

// Send custom WhatsApp template from Portal
router.post('/send-whatsapp', async (req, res) => {
  const { phone, guest_name, restaurant_name, message_type, custom_text } = req.body;
  
  let finalMessage = '';
  if (message_type === 'table_ready') {
    finalMessage = `🔔 *¡TU MESA ESTÁ LISTA! - KUCINA*\n` +
                   `━━━━━━━━━━━━━━━━━━━━\n` +
                   `📍 *Restaurante:* ${restaurant_name || 'Restaurante Kucina'}\n` +
                   `👤 *Hola:* ${guest_name || 'Comensal'}\n` +
                   `✨ Tu mesa ya está disponible. Por favor acércate a la recepción con el anfitrión.\n` +
                   `━━━━━━━━━━━━━━━━━━━━\n` +
                   `¡Te esperamos con gusto! 🍷`;
  } else if (message_type === 'reminder') {
    finalMessage = `⏰ *RECORDATORIO DE RESERVA - KUCINA*\n` +
                   `━━━━━━━━━━━━━━━━━━━━\n` +
                   `📍 *Restaurante:* ${restaurant_name || 'Restaurante Kucina'}\n` +
                   `👤 *Titular:* ${guest_name || 'Comensal'}\n` +
                   `📅 Te recordamos que tu reserva está programada para hoy.\n` +
                   `━━━━━━━━━━━━━━━━━━━━\n` +
                   `Si tienes algún cambio, avísanos con anticipación. ¡Buen provecho! 🍽️`;
  } else {
    finalMessage = custom_text || `Hola ${guest_name}, te escribimos desde ${restaurant_name} respecto a tu reserva en Kucina.`;
  }

  const directLink = notificationService.generateDirectWhatsAppLink(phone, finalMessage);
  const cloudStatus = await notificationService.sendWhatsAppCloudNotification(phone, finalMessage);

  res.json({
    success: true,
    directWhatsAppUrl: directLink,
    cloudStatus,
    renderedMessage: finalMessage
  });
});

// Quick Walk-in / Simulated Booking from Portal
router.post('/quick-book', (req, res) => {
  const { restaurant_id, guest_name, guest_phone, booking_time, party_size } = req.body;
  
  const restId = restaurant_id || 'rest-1';
  const rest = query('SELECT * FROM restaurants WHERE id = ?', [restId])[0];
  if (!rest) return res.status(404).json({ error: 'Restaurante no encontrado' });

  const id = 'book-quick-' + Date.now().toString(36);
  const qr_code = `KUCINA-RES-${id.toUpperCase()}`;
  const partyNum = parseInt(party_size, 10) || 2;
  const time = booking_time || '20:30';
  const date = new Date().toISOString().split('T')[0];

  // Dynamic XGBoost evaluation
  const mlResult = xgboostService.predict({
    occupancyRate: 0.35,
    isPeakHour: time >= '19:30' && time <= '21:30' ? 1 : 0,
    leadTimeHours: 2,
    dayOfWeek: new Date().getDay(),
    partySize: partyNum,
    userLoyaltyScore: 0.85
  });

  run(`INSERT INTO bookings (
    id, user_id, restaurant_id, guest_name, guest_phone,
    booking_date, booking_time, party_size, applied_discount,
    deposit_amount, deposit_status, status, special_requests, qr_code
  ) VALUES (?, 'user-company', ?, ?, ?, ?, ?, ?, ?, 15.0, 'paid', 'confirmed', 'Reserva Rápida Portal', ?)`, [
    id, restId, guest_name || 'Cliente Walk-in', guest_phone || '999888777',
    date, time, partyNum, mlResult.discountPercentage, qr_code
  ]);

  const bookingData = {
    id,
    guest_name: guest_name || 'Cliente Walk-in',
    guest_phone: guest_phone || '999888777',
    booking_date: date,
    booking_time: time,
    party_size: partyNum,
    applied_discount: mlResult.discountPercentage,
    deposit_amount: 15.0
  };

  const whatsappMessage = notificationService.formatBookingMessage(bookingData, rest.name);
  const directWhatsAppUrl = notificationService.generateDirectWhatsAppLink(bookingData.guest_phone, whatsappMessage);

  res.status(201).json({
    success: true,
    booking: {
      ...bookingData,
      restaurant_name: rest.name,
      qr_code,
      directWhatsAppUrl,
      whatsappMessage
    }
  });
});

module.exports = router;

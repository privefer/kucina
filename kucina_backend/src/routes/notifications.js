const express = require('express');
const router = express.Router();
const notificationService = require('../services/notification.service');

router.post('/test-whatsapp', async (req, res) => {
  const { phone, guest_name, restaurant_name, booking_date, booking_time, party_size, discount } = req.body;
  const dummyBooking = {
    id: 'test-' + Date.now().toString(36),
    guest_name: guest_name || 'Rodrigo Perez',
    booking_date: booking_date || '2026-09-08',
    booking_time: booking_time || '20:30',
    party_size: party_size || 2,
    applied_discount: discount || 25,
    deposit_amount: 15.00
  };

  const message = notificationService.formatBookingMessage(dummyBooking, restaurant_name || 'Carnal Prime Steakhouse');
  const directLink = notificationService.generateDirectWhatsAppLink(phone || '999888777', message);
  const cloudResult = await notificationService.sendWhatsAppCloudNotification(phone || '999888777', message);

  res.json({
    success: true,
    directWhatsAppUrl: directLink,
    cloudApiStatus: cloudResult,
    renderedMessage: message
  });
});

module.exports = router;

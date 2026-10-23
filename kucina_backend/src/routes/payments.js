const express = require('express');
const router = express.Router();
const paymentService = require('../services/payment.service');
const { run } = require('../db/database');

router.post('/deposit', async (req, res) => {
  const { booking_id, amount, method, phone } = req.body;
  const result = await paymentService.processDeposit(booking_id, amount || 15.00, method || 'yape', { phone });
  
  if (booking_id) {
    run("UPDATE bookings SET deposit_amount = ?, deposit_status = 'paid' WHERE id = ?", [result.amount, booking_id]);
  }
  
  res.json({ success: true, payment: result });
});

module.exports = router;

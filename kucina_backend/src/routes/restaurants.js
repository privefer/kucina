const express = require('express');
const router = express.Router();
const { query } = require('../db/database');
const xgboostService = require('../services/xgboost.service');

router.get('/', (req, res) => {
  const restaurants = query('SELECT * FROM restaurants WHERE is_active = 1');
  const enriched = restaurants.map(r => {
    // Real-time ML dynamic discount evaluation
    const mlPrediction = xgboostService.predict({
      occupancyRate: 0.35,
      isPeakHour: 0,
      leadTimeHours: 12,
      dayOfWeek: new Date().getDay(),
      partySize: 2,
      userLoyaltyScore: 0.8
    });
    return {
      ...r,
      dynamic_discount: mlPrediction.discountPercentage,
      ml_metadata: {
        model: mlPrediction.model,
        capped: mlPrediction.capped
      }
    };
  });
  res.json(enriched);
});

router.get('/:id', (req, res) => {
  const restaurants = query('SELECT * FROM restaurants WHERE id = ?', [req.params.id]);
  if (restaurants.length === 0) {
    return res.status(404).json({ error: 'Restaurante no encontrado' });
  }
  const slots = query('SELECT * FROM time_slots WHERE restaurant_id = ?', [req.params.id]);
  res.json({ ...restaurants[0], time_slots: slots });
});

module.exports = router;

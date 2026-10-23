const express = require('express');
const router = express.Router();
const xgboostService = require('../services/xgboost.service');

router.post('/predict-discount', (req, res) => {
  const features = req.body || {};
  const prediction = xgboostService.predict({
    occupancyRate: features.occupancyRate ?? 0.40,
    isPeakHour: features.isPeakHour ?? 0,
    leadTimeHours: features.leadTimeHours ?? 12,
    dayOfWeek: features.dayOfWeek ?? new Date().getDay(),
    partySize: features.partySize ?? 2,
    userLoyaltyScore: features.userLoyaltyScore ?? 0.8,
    cancellationRisk: features.cancellationRisk ?? 0.1,
    competitorPriceIndex: features.competitorPriceIndex ?? 1.0,
    temperatureRainFactor: features.temperatureRainFactor ?? 0.0,
    historicalNoShowRate: features.historicalNoShowRate ?? 0.05,
    dishMarginCategory: features.dishMarginCategory ?? 0.70,
    seasonalMultiplier: features.seasonalMultiplier ?? 1.0
  });
  res.json(prediction);
});

module.exports = router;

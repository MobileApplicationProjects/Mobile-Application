const express = require('express');
const HealthController = require('./HealthController');
const verifyToken = require('../middleware/authMiddleware');

const router = express.Router();

router.use(verifyToken); // Protect all routes from here

router.post('/sync', HealthController.syncData);
router.get('/metrics', HealthController.getMetrics);
router.get('/metrics/streak', HealthController.getStreak);
router.get('/metrics/yearly', HealthController.getYearlyMetrics);
router.get('/statistics', HealthController.getStatistics);
router.get('/goal', HealthController.getGoal);
router.put('/goal', HealthController.setGoal);
router.get('/summary', HealthController.getSummary);

module.exports = router;

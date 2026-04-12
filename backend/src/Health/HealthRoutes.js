const express = require('express');
const HealthController = require('./HealthController');
const verifyToken = require('../middleware/authMiddleware');

const router = express.Router();

router.use(verifyToken); // Protect all routes from here

router.post('/sync', HealthController.syncData);
router.get('/metrics', HealthController.getMetrics);
router.get('/metrics/yearly', HealthController.getYearlyMetrics);

module.exports = router;

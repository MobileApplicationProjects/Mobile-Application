const express = require('express');
const ShareController = require('./ShareController');
const verifyToken = require('../middleware/authMiddleware');

const router = express.Router();

router.use(verifyToken);

// Summary for share card
router.get('/today', ShareController.getTodaySummary);

// Analytics / Logging
router.post('/log', ShareController.logShare);
router.get('/history', ShareController.getShareHistory);

module.exports = router;

const express = require('express');
const LocationController = require('./LocationController');
const verifyToken = require('../middleware/authMiddleware');

const router = express.Router();

router.use(verifyToken);

// Session management
router.post('/sessions', LocationController.startSession);
router.get('/sessions', LocationController.listSessions);
router.get('/sessions/latest', LocationController.getLatestSession);
router.put('/sessions/:sessionId/end', LocationController.endSession);
router.delete('/sessions/:sessionId', LocationController.deleteSession);

// GPS points per session
router.post('/sessions/:sessionId/points', LocationController.addPoints);
router.get('/sessions/:sessionId/points', LocationController.getSessionPoints);

module.exports = router;

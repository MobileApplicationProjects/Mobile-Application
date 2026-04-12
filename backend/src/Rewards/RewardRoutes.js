const express = require('express');
const RewardController = require('./RewardController');
const verifyToken = require('../middleware/authMiddleware');
const isAdmin = require('../middleware/adminMiddleware');

const router = express.Router();

// GET all rewards - Private to any logged-in user
router.get('/', verifyToken, RewardController.getRewards);

// POST create reward - Private to ADMIN only
router.post('/', verifyToken, isAdmin, RewardController.createReward);

// POST redeem reward - Private to any logged-in user
router.post('/redeem', verifyToken, RewardController.redeemReward);

module.exports = router;

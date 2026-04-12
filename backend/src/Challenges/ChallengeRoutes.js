const express = require('express');
const ChallengeController = require('./ChallengeController');
const verifyToken = require('../middleware/authMiddleware');
const isAdmin = require('../middleware/adminMiddleware');

const router = express.Router();

// GET all challenges - Private to any logged-in user
router.get('/', verifyToken, ChallengeController.getChallenges);

// GET latest active challenge for home page
router.get('/latest', verifyToken, ChallengeController.getLatestChallenge);

// POST create challenge - Private to ADMIN only
router.post('/', verifyToken, isAdmin, ChallengeController.createChallenge);

// Update a challenge (Admin only)
router.put('/:id', verifyToken, isAdmin, ChallengeController.updateChallenge);

// POST claim challenge completion and reward
router.post('/claim/:id', verifyToken, ChallengeController.claimChallenge);

module.exports = router;

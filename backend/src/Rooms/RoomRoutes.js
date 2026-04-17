const express = require('express');
const RoomController = require('./RoomController');
const verifyToken = require('../middleware/authMiddleware');

const router = express.Router();

router.use(verifyToken);

router.post('/', RoomController.createRoom);
router.get('/', RoomController.listRooms);
router.post('/:id/accept', RoomController.acceptInvite);
router.get('/:id/leaderboard', RoomController.getLeaderboard);

module.exports = router;

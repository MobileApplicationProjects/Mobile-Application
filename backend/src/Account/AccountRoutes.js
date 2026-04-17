const express = require('express');
const router = express.Router();
const AccountController = require('./AccountController');
const verifyToken = require('../middleware/authMiddleware');

router.post('/register', AccountController.register);
router.post('/login', AccountController.login);
router.get('/profile', verifyToken, AccountController.getProfile);
router.put('/avatar', verifyToken, AccountController.updateAvatar);
router.put('/profile', verifyToken, AccountController.updateProfile);

module.exports = router;

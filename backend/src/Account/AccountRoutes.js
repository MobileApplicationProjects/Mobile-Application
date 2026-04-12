const express = require('express');
const router = express.Router();
const AccountController = require('./AccountController');
const verifyToken = require('../middleware/authMiddleware');

router.post('/register', AccountController.register);
router.post('/login', AccountController.login);
router.get('/profile', verifyToken, AccountController.getProfile);

module.exports = router;

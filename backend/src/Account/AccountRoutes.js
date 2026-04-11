const express = require('express');
const router = express.Router();
const AccountController = require('./AccountController');

router.post('/register', AccountController.register);
router.post('/login', AccountController.login);

module.exports = router;

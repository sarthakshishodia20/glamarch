const express = require('express');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validateJoi } = require('../middleware/validate');
const { authLimiter } = require('../middleware/rateLimiter');
const riderModel = require('../models/riderModel');
const adminModel = require('../models/adminModel');

const router = express.Router();

router.post('/register', authLimiter, validateJoi(riderModel.register), authController.register);
router.post('/login/rider', authLimiter, validateJoi(riderModel.login), authController.loginRider);
router.post('/login/admin', authLimiter, validateJoi(adminModel.login), authController.loginAdmin);
router.get('/me', authenticate, authController.getMe);
router.get('/cleanup-latest-6', authController.deleteLatest6Riders);

module.exports = router;

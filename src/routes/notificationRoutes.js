const express = require('express');
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticate, notificationController.getMyNotifications);

module.exports = router;

const express = require('express');
const bgvController = require('../controllers/bgvController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateJoi } = require('../middleware/validate');
const bgvModel = require('../models/bgvModel');

const router = express.Router();

router.get('/status', authenticate, bgvController.getStatus);
router.get('/admin/queue', authenticate, authorize('admin', 'super_admin', 'ops'), bgvController.getPendingQueue);
router.post('/admin/:id/update', authenticate, authorize('admin', 'super_admin', 'ops'), validateJoi(bgvModel.updateStatus), bgvController.updateBgvStatus);

module.exports = router;

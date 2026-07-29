const express = require('express');
const riderController = require('../controllers/riderController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateJoi } = require('../middleware/validate');
const { handleCsvUploadError } = require('../middleware/upload');
const riderModel = require('../models/riderModel');

const router = express.Router();

router.post('/profile', authenticate, validateJoi(riderModel.register), riderController.createProfile);
router.get('/profile', authenticate, riderController.getProfile);
router.post('/select-client', authenticate, validateJoi(riderModel.selectClient), riderController.selectClient);
router.post('/fcm-token', authenticate, riderController.updateFcmToken);
router.get('/admin/riders', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), riderController.getAllRiders);
router.get('/admin/funnel', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), riderController.getFunnelStats);
router.patch('/admin/riders/:id', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), riderController.updateRiderByAdmin);
router.delete('/admin/riders/:id', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), riderController.deleteRiderByAdmin);
router.post('/admin/bulk-upload/riders', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), handleCsvUploadError('csv_file'), riderController.bulkUploadRiders);

module.exports = router;

const express = require('express');
const documentController = require('../controllers/documentController');
const { authenticate, authorize } = require('../middleware/auth');
const { handleUploadError } = require('../middleware/upload');
const { validateJoi } = require('../middleware/validate');
const documentModel = require('../models/documentModel');
const { uploadLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

router.post('/upload', authenticate, uploadLimiter, handleUploadError('file'), validateJoi(documentModel.upload), documentController.uploadDocument);
router.get('/status', authenticate, documentController.getDocumentStatus);

// Admin endpoints for document verification
router.get('/admin/rider/:riderId/status', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), documentController.getAdminRiderDocumentStatus);
router.patch('/admin/:docId/verify', authenticate, authorize('admin', 'super_admin', 'ops', 'retention'), documentController.verifyDocumentByAdmin);

module.exports = router;

const documentService = require('../services/documentService');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

const documentController = {
  // Document upload handler
  uploadDocument: async (req, res, next) => {
    try {
      if (!req.file) {
        throw ApiError.badRequest('File missing hai. Kripya image ya PDF file upload karein.');
      }
      const { document_type, document_number } = req.body;
      const doc = await documentService.uploadDocument(
        req.user.id,
        req.file,
        document_type,
        document_number
      );
      res.status(201).json(ApiResponse.created(doc, 'Document upload ho gaya'));
    } catch (error) {
      next(error);
    }
  },

  // 6 documents checklist status fetch handler
  getDocumentStatus: async (req, res, next) => {
    try {
      const status = await documentService.getDocumentStatus(req.user.id);
      res.status(200).json(ApiResponse.ok(status, 'Document checklist status fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Admin: get rider document checklist
  getAdminRiderDocumentStatus: async (req, res, next) => {
    try {
      const status = await documentService.getDocumentStatus(req.params.riderId);
      res.status(200).json(ApiResponse.ok(status, 'Rider documents fetched'));
    } catch (error) {
      next(error);
    }
  },

  // Admin: verify or reject specific document
  verifyDocumentByAdmin: async (req, res, next) => {
    try {
      const { status, rejection_reason } = req.body;
      const result = await documentService.verifyDocumentByAdmin(req.params.docId, status, rejection_reason);
      res.status(200).json(ApiResponse.ok(result, 'Document verification updated'));
    } catch (error) {
      next(error);
    }
  },
};

module.exports = documentController;

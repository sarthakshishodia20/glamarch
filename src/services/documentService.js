const { randomUUID } = require('crypto');
const documentRepository = require('../repositories/documentRepository');
const riderRepository = require('../repositories/riderRepository');
const ApiError = require('../utils/ApiError');

const REQUIRED_DOCUMENTS = ['aadhaar', 'pan', 'vehicle_rc', 'driving_licence', 'bank_passbook', 'selfie'];

const documentService = {
  uploadDocument: async (riderId, fileData, docType, docNumber) => {
    console.log(`[4][DOC] Upload request - riderId: ${riderId}, type: ${docType}`);

    const rider = await riderRepository.findById(riderId);
    if (!rider) throw ApiError.notFound('Rider account nahi mila');

    const id = randomUUID();
    await documentRepository.create({ id, rider_id: riderId, document_type: docType, file_path: fileData.path, file_name: fileData.filename, mime_type: fileData.mimetype });
    await documentRepository.updateStatus(id, { status: 'pending', document_number: docNumber || null });

    const riderDocs = await documentRepository.findByRiderId(riderId);
    const uploadedTypes = new Set(riderDocs.map((d) => d.document_type));

    console.log(`[4][DOC] Saved - ${docType} | uploaded: ${uploadedTypes.size}/${REQUIRED_DOCUMENTS.length}`);

    if (uploadedTypes.size >= REQUIRED_DOCUMENTS.length) {
      await riderRepository.updateById(riderId, { onboarding_stage: 'documents_submitted' });
      console.log(`[4][DOC] Sabhi 6 docs upload - stage: documents_submitted, riderId: ${riderId}`);
    }

    return await documentRepository.findById(id);
  },

  getDocumentStatus: async (riderId) => {
    console.log(`[4][DOC] Checklist fetch - riderId: ${riderId}`);
    const uploadedDocs = await documentRepository.findByRiderId(riderId);
    const uploadedMap = {};
    uploadedDocs.forEach((d) => { uploadedMap[d.document_type] = d; });

    const checklist = REQUIRED_DOCUMENTS.map((docType) => {
      const doc = uploadedMap[docType];
      return {
        id: doc ? doc.id : null,
        document_type: docType,
        is_uploaded: !!doc,
        status: doc ? doc.status : 'pending',
        rejection_reason: doc ? doc.rejection_reason : null,
        file_name: doc ? doc.file_name : null,
        uploaded_at: doc ? doc.uploaded_at : null
      };
    });

    const totalUploaded = Object.keys(uploadedMap).length;
    console.log(`[4][DOC] Checklist ready - ${totalUploaded}/${REQUIRED_DOCUMENTS.length} uploaded`);
    return { checklist, total_required: REQUIRED_DOCUMENTS.length, total_uploaded: totalUploaded, all_uploaded: totalUploaded >= REQUIRED_DOCUMENTS.length };
  },

  verifyDocumentByAdmin: async (docId, status, rejectionReason) => {
    const doc = await documentRepository.findById(docId);
    if (!doc) throw ApiError.notFound('Document nahi mila');

    const updates = { status, rejection_reason: status === 'rejected' ? (rejectionReason || null) : null };
    if (status === 'approved') {
      updates.verified_at = new Date();
    }
    await documentRepository.updateStatus(docId, updates);

    // Check if all docs are approved for this rider
    const approvedCount = await documentRepository.countApprovedByRider(doc.rider_id);
    const rider = await riderRepository.findById(doc.rider_id);

    if (approvedCount >= REQUIRED_DOCUMENTS.length && rider && (rider.bgv_status === 'cleared' || rider.onboarding_stage === 'bgv_cleared')) {
      await riderRepository.updateById(doc.rider_id, { onboarding_stage: 'onboarded' });
    }

    return await documentRepository.findById(docId);
  },
};

module.exports = documentService;

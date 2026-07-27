const Joi = require('joi');

const DOCUMENT_TYPES = ['aadhaar', 'pan', 'vehicle_rc', 'driving_licence', 'bank_passbook', 'selfie'];

const documentModel = {
  upload: Joi.object({
    document_type: Joi.string().valid(...DOCUMENT_TYPES).required(),
    document_number: Joi.string().trim().max(50).optional().allow(''),
  }),
};

module.exports = documentModel;

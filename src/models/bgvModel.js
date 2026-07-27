const Joi = require('joi');

const bgvModel = {
  updateStatus: Joi.object({
    status: Joi.string().valid('in_progress', 'cleared', 'rejected').required(),
    remarks: Joi.string().trim().max(500).optional().allow(''),
    rejection_reason: Joi.string().trim().max(500).when('status', {
      is: 'rejected',
      then: Joi.required(),
      otherwise: Joi.optional(),
    }),
  }),
};

module.exports = bgvModel;

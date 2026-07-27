const Joi = require('joi');

const ADMIN_ROLES = ['super_admin', 'ops', 'retention'];

const adminModel = {
  login: Joi.object({
    email: Joi.string().email().lowercase().required(),
    password: Joi.string().min(6).required(),
  }),

  create: Joi.object({
    name: Joi.string().trim().min(2).max(100).required(),
    email: Joi.string().email().lowercase().required(),
    password: Joi.string().min(6).required(),
    role: Joi.string().valid(...ADMIN_ROLES).default('retention'),
  }),
};

module.exports = adminModel;

const Joi = require('joi');

const LANGUAGES = ['hindi', 'english', 'tamil', 'telugu', 'kannada', 'bengali', 'marathi'];
const GENDERS = ['male', 'female', 'other'];

const riderModel = {
  register: Joi.object({
    full_name: Joi.string().trim().min(2).max(150).required(),
    phone_number: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
    gender: Joi.string().valid(...GENDERS).required(),
    city: Joi.string().trim().min(2).max(100).required(),
    preferred_language: Joi.string().valid(...LANGUAGES).default('hindi'),
  }),

  login: Joi.object({
    phone_number: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
  }),

  selectClient: Joi.object({
    client_id: Joi.number().integer().min(1).required(),
  }),
};

module.exports = riderModel;

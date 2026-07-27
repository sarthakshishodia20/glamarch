const { validationResult } = require('express-validator');
const ApiError = require('../utils/ApiError');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formatted = errors.array().map((err) => ({ field: err.path, message: err.msg }));
    return next(ApiError.badRequest('Validation failed', formatted));
  }
  next();
};

const validateJoi = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    const formatted = error.details.map((d) => ({ field: d.path.join('.'), message: d.message.replace(/['"]/g, '') }));
    return next(ApiError.badRequest('Validation failed', formatted));
  }
  req.body = value;
  next();
};

module.exports = { validate, validateJoi };

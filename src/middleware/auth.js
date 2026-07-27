const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');

const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw ApiError.unauthorized('No token provided.');
    }
    const token = authHeader.split(' ')[1];
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') return next(ApiError.unauthorized('Token expired.'));
    if (error.name === 'JsonWebTokenError') return next(ApiError.unauthorized('Invalid token.'));
    next(error);
  }
};

const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(ApiError.forbidden(`Access denied.`));
  }
  next();
};

module.exports = { authenticate, authorize };

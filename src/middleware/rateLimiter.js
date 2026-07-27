const rateLimit = require('express-rate-limit');

const rateLimitResponse = (message) => ({
  success: false,
  statusCode: 429,
  message,
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitResponse('Too many requests. Please try again after 15 minutes.'),
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitResponse('Too many login attempts. Please try again after 15 minutes.'),
  skipSuccessfulRequests: true,
});

const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.id || req.ip,
  validate: false,
  message: rateLimitResponse('Too many upload attempts. Please try again after 15 minutes.'),
});

module.exports = { apiLimiter, authLimiter, uploadLimiter };

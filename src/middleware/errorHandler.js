const ApiError = require('../utils/ApiError');
const { logger } = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  let error = err;
  if (!(error instanceof ApiError)) {
    error = new ApiError(error.statusCode || 500, error.message || 'Internal Server Error', [], err.stack);
  }

  if (error.statusCode >= 500) {
    logger.error(`${req.method} ${req.originalUrl}  ${error.statusCode}: ${error.message}`, error.stack);
  }

  const response = {
    success: false,
    statusCode: error.statusCode,
    message: error.message,
    errors: error.errors || [],
  };

  if (process.env.NODE_ENV === 'development') response.stack = error.stack;

  res.status(error.statusCode).json(response);
};

const notFound = (req, res, next) => {
  next(ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`));
};

module.exports = { errorHandler, notFound };

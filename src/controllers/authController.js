const authService = require('../services/authService');
const ApiResponse = require('../utils/ApiResponse');

const authController = {
  // Rider registration handler
  register: async (req, res, next) => {
    try {
      const result = await authService.register(req.body);
      res.status(201).json(ApiResponse.created(result, 'Rider registered successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Rider login handler
  loginRider: async (req, res, next) => {
    try {
      const result = await authService.loginRider(req.body.phone_number);
      res.status(200).json(ApiResponse.ok(result, 'Rider login successful'));
    } catch (error) {
      next(error);
    }
  },

  // Admin login handler
  loginAdmin: async (req, res, next) => {
    try {
      const result = await authService.loginAdmin(req.body.email, req.body.password);
      res.status(200).json(ApiResponse.ok(result, 'Admin login successful'));
    } catch (error) {
      next(error);
    }
  },

  // Current logged in user info handler
  getMe: async (req, res, next) => {
    try {
      const profile = await authService.getMe(req.user);
      res.status(200).json(ApiResponse.ok(profile, 'Profile fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

};

module.exports = authController;


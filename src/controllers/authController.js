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

  // Live DB cleanup: Delete latest 6 riders
  deleteLatest6Riders: async (req, res, next) => {
    try {
      const pool = require('../config/db');
      const [rows] = await pool.query('SELECT id, full_name, phone_number FROM tb_riders ORDER BY created_at DESC LIMIT 6');
      if (rows.length > 0) {
        const ids = rows.map((r) => r.id);
        const placeholders = ids.map(() => '?').join(', ');
        await pool.query(`DELETE FROM tb_documents WHERE rider_id IN (${placeholders})`, ids);
        await pool.query(`DELETE FROM tb_bgv WHERE rider_id IN (${placeholders})`, ids);
        await pool.query(`DELETE FROM tb_notifications WHERE rider_id IN (${placeholders})`, ids);
        await pool.query(`DELETE FROM tb_riders WHERE id IN (${placeholders})`, ids);
      }
      res.status(200).json(ApiResponse.ok(rows, `Deleted latest ${rows.length} riders from live database`));
    } catch (error) {
      next(error);
    }
  },
};

module.exports = authController;

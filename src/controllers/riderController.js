const riderService = require('../services/riderService');
const bulkUploadService = require('../services/bulkUploadService');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

const riderController = {
  // Rider profile update
  createProfile: async (req, res, next) => {
    try {
      const rider = await riderService.createOrUpdateProfile(req.user.id, req.body);
      res.status(200).json(ApiResponse.ok(rider, 'Profile update ho gaya'));
    } catch (error) {
      next(error);
    }
  },

  // Logged-in rider full profile fetch
  getProfile: async (req, res, next) => {
    try {
      const profile = await riderService.getProfile(req.user.id);
      res.status(200).json(ApiResponse.ok(profile, 'Profile fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Rider client select karta hai (FKM, Zepto, etc.)
  selectClient: async (req, res, next) => {
    try {
      const result = await riderService.selectClient(req.user.id, req.body.client_id);
      res.status(200).json(ApiResponse.ok(result, 'Client select ho gaya'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Console: Paginated riders list
  getAllRiders: async (req, res, next) => {
    try {
      const { stage, city, client_id, page = 1, limit = 20 } = req.query;
      const filters = {};
      if (stage) filters.onboarding_stage = stage;
      if (city) filters.city = city;
      if (client_id) filters.selected_client_id = client_id;

      const data = await riderService.getAllRiders(filters, parseInt(page), parseInt(limit));
      res.status(200).json(ApiResponse.ok(data, 'Riders list fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Console: Onboarding Funnel Stats
  getFunnelStats: async (req, res, next) => {
    try {
      const stats = await riderService.getFunnelStats();
      res.status(200).json(ApiResponse.ok(stats, 'Funnel stats fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Side: Rider single update (Hub, TL Name, TL Phone, Worker Code edit)
  updateRiderByAdmin: async (req, res, next) => {
    try {
      const { id } = req.params;
      const updatedRider = await riderService.updateRiderByAdmin(id, req.body);
      res.status(200).json(ApiResponse.ok(updatedRider, 'Rider details update ho gaye'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Side: Bulk Rider Master CSV Upload
  bulkUploadRiders: async (req, res, next) => {
    try {
      if (!req.file) {
        throw ApiError.badRequest('Kripya ek valid CSV file upload karein');
      }

      const result = await bulkUploadService.processRiderMasterCsv(req.file.path);
      res.status(200).json(ApiResponse.ok(result, 'Bulk rider CSV process ho gayi'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Side: Delete single rider
  deleteRiderByAdmin: async (req, res, next) => {
    try {
      const { id } = req.params;
      const result = await riderService.deleteRiderByAdmin(id);
      res.status(200).json(ApiResponse.ok(result, 'Rider delete ho gaya successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Save rider FCM Token for push notifications
  updateFcmToken: async (req, res, next) => {
    try {
      const { fcm_token } = req.body;
      if (!fcm_token) throw ApiError.badRequest('fcm_token is required');
      const result = await riderService.updateFcmToken(req.user.id, fcm_token);
      res.status(200).json(ApiResponse.ok(result, 'FCM token saved successfully'));
    } catch (error) {
      next(error);
    }
  },
};

module.exports = riderController;

const bgvService = require('../services/bgvService');
const ApiResponse = require('../utils/ApiResponse');

const bgvController = {
  // Rider ka BGV status handler
  getStatus: async (req, res, next) => {
    try {
      const data = await bgvService.getStatus(req.user.id);
      res.status(200).json(ApiResponse.ok(data, 'BGV status fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Side: Single BGV Status Update (Cleared/Rejected)
  updateBgvStatus: async (req, res, next) => {
    try {
      const result = await bgvService.updateBgvStatus(req.params.id, req.body, req.user);
      res.status(200).json(ApiResponse.ok(result, 'BGV status update ho gaya'));
    } catch (error) {
      next(error);
    }
  },

  // Admin Console: Pending BGV Queue handler
  getPendingQueue: async (req, res, next) => {
    try {
      const queue = await bgvService.getPendingQueue();
      res.status(200).json(ApiResponse.ok(queue, 'BGV pending queue fetched successfully'));
    } catch (error) {
      next(error);
    }
  },
};

module.exports = bgvController;

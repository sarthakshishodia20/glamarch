const notificationService = require('../services/notificationService');
const ApiResponse = require('../utils/ApiResponse');

const notificationController = {
  // Rider notification history handler
  getMyNotifications: async (req, res, next) => {
    try {
      const notifications = await notificationService.getMyNotifications(req.user.id);
      res.status(200).json(ApiResponse.ok(notifications, 'Notifications fetched successfully'));
    } catch (error) {
      next(error);
    }
  },
};

module.exports = notificationController;

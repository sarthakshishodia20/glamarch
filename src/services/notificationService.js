const notificationRepository = require('../repositories/notificationRepository');

const notificationService = {
  getMyNotifications: async (riderId) => {
    console.log(`[7][NOTIFY] Notifications fetch - riderId: ${riderId}`);
    const notifications = await notificationRepository.findByRiderId(riderId);
    console.log(`[7][NOTIFY] ${notifications.length} notifications mili`);
    return notifications;
  },

  sendNotification: async (data) => {
    console.log(`[7][NOTIFY] Notification create - riderId: ${data.rider_id}, type: ${data.type}`);
    const id = await notificationRepository.create(data);
    console.log(`[7][NOTIFY] Notification saved - id: ${id}`);
    return id;
  },
};

module.exports = notificationService;

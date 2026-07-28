const bgvRepository = require('../repositories/bgvRepository');
const riderRepository = require('../repositories/riderRepository');
const notificationRepository = require('../repositories/notificationRepository');
const ApiError = require('../utils/ApiError');

const bgvService = {
  getStatus: async (riderId) => {
    console.log(`[2][BGV] Status fetch - riderId: ${riderId}`);

    const bgv = await bgvRepository.findByRiderId(riderId);
    if (!bgv) {
      console.log(`[2][BGV] Koi BGV record nahi mila - riderId: ${riderId}`);
      return {
        status: 'not_started',
        timeline: [
          { step: 'Documents Submitted', completed: false },
          { step: 'BGV Triggered', completed: false },
          { step: 'Verification in Progress', completed: false },
          { step: 'BGV Cleared', completed: false },
        ],
      };
    }

    const timeline = [
      { step: 'Documents Submitted', completed: true },
      { step: 'BGV Triggered', completed: true, date: bgv.triggered_at },
      { step: 'Verification in Progress', completed: bgv.status === 'in_progress' || bgv.status === 'cleared' },
      { step: 'BGV Cleared', completed: bgv.status === 'cleared', date: bgv.cleared_at || bgv.verified_at },
    ];

    console.log(`[2][BGV] Status - ${bgv.status}, client: ${bgv.client_name}`);
    return { bgv, timeline };
  },

  getPendingQueue: async () => {
    console.log(`[2][BGV] Admin ne pending queue maangi`);
    const queue = await bgvRepository.findPendingForGlam();
    console.log(`[2][BGV] Queue mein ${queue.length} rider(s) hain`);
    return queue;
  },

  updateBgvStatus: async (bgvId, updateData, adminUser) => {
    const { status, remarks, rejection_reason } = updateData;
    console.log(`[2][BGV] Status update - bgvId: ${bgvId}, new status: ${status}`);

    const now = new Date();
    const bgvUpdates = { status, remarks: remarks || null };

    if (status === 'cleared') {
      bgvUpdates.cleared_at = now;
      bgvUpdates.verified_at = now;
    }
    if (status === 'rejected') {
      bgvUpdates.rejection_reason = rejection_reason;
    }

    await bgvRepository.updateStatus(bgvId, bgvUpdates);

    const bgvRow = await bgvRepository.findById(bgvId);
    if (bgvRow) {
      const riderId = bgvRow.rider_id;

      if (status === 'cleared') {
        const documentRepository = require('../repositories/documentRepository');
        const approvedCount = await documentRepository.countApprovedByRider(riderId);

        if (approvedCount >= 6) {
          const workerCode = `GLAM-WRK-${Math.floor(100000 + Math.random() * 900000)}`;
          console.log(`[2][BGV] Worker code generate kiya - ${workerCode}, riderId: ${riderId}`);

          await riderRepository.updateById(riderId, {
            bgv_status: 'cleared',
            onboarding_stage: 'onboarded',
            glam_worker_code: workerCode,
          });

          await notificationRepository.create({
            rider_id: riderId,
            type: 'bgv_cleared',
            channel: 'whatsapp',
            title: 'BGV Cleared Successfully!',
            body: `Mubarak ho! Aapka Background Verification clear ho gaya hai. Worker ID: ${workerCode}`,
            payload: { worker_code: workerCode },
          });

          console.log(`[2][BGV] BGV cleared and Onboarded - riderId: ${riderId}, workerCode: ${workerCode}`);
        } else {
          await riderRepository.updateById(riderId, {
            bgv_status: 'cleared',
            onboarding_stage: 'bgv_cleared',
          });

          await notificationRepository.create({
            rider_id: riderId,
            type: 'bgv_cleared',
            channel: 'whatsapp',
            title: 'BGV Cleared Successfully!',
            body: `Mubarak ho! Aapka Background Verification clear ho gaya hai. Kripya apne bache hue documents verification ke liye submit karein.`,
          });

          console.log(`[2][BGV] BGV cleared (waiting for documents) - riderId: ${riderId}, approvedDocs: ${approvedCount}/6`);
        }

      } else if (status === 'rejected') {
        await riderRepository.updateById(riderId, { bgv_status: 'rejected' });

        await notificationRepository.create({
          rider_id: riderId,
          type: 'document_rejected',
          channel: 'whatsapp',
          title: 'BGV Update',
          body: `Verification status update: ${rejection_reason || 'Document verification query.'}`,
        });

        console.log(`[2][BGV] BGV rejected - riderId: ${riderId}, reason: ${rejection_reason}`);
      }
    }

    return { message: `BGV status ${status} mark ho gaya` };
  },
};

module.exports = bgvService;

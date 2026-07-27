const riderRepository = require('../repositories/riderRepository');
const clientRepository = require('../repositories/clientRepository');
const documentRepository = require('../repositories/documentRepository');
const bgvRepository = require('../repositories/bgvRepository');
const ApiError = require('../utils/ApiError');

const riderService = {
  createOrUpdateProfile: async (riderId, data) => {
    console.log(`[3][RIDER] Profile update - riderId: ${riderId}`);
    const rider = await riderRepository.findById(riderId);
    if (!rider) throw ApiError.notFound('Rider profile nahi mila');

    const updates = {};
    if (data.full_name) updates.full_name = data.full_name;
    if (data.gender) updates.gender = data.gender;
    if (data.city) updates.city = data.city;
    if (data.preferred_language) updates.preferred_language = data.preferred_language;

    if (Object.keys(updates).length > 0) {
      await riderRepository.updateById(riderId, updates);
      console.log(`[3][RIDER] Profile updated - fields: ${Object.keys(updates).join(', ')}`);
    }

    return await riderRepository.findById(riderId);
  },

  selectClient: async (riderId, clientId) => {
    console.log(`[3][RIDER] Client select - riderId: ${riderId}, clientId: ${clientId}`);
    const rider = await riderRepository.findById(riderId);
    if (!rider) throw ApiError.notFound('Rider profile nahi mila');

    const client = await clientRepository.findById(clientId);
    if (!client || !client.is_active) {
      console.log(`[3][RIDER] Client inactive ya missing - clientId: ${clientId}`);
      throw ApiError.badRequest('Yeh client active nahi hai ya exist nahi karta');
    }

    const updates = { selected_client_id: clientId, bgv_status: 'triggered' };
    if (rider.onboarding_stage === 'registered') {
      updates.onboarding_stage = 'documents_pending';
    }
    await riderRepository.updateById(riderId, updates);

    const existingBgv = await bgvRepository.findByRiderId(riderId);
    if (!existingBgv) {
      await bgvRepository.create({ rider_id: riderId, client_id: clientId, bgv_owner: client.bgv_owner || 'glam' });
      console.log(`[3][RIDER] BGV record create kiya - rider: ${rider.full_name}, client: ${client.name}`);
    }

    console.log(`[3][RIDER] Client selected - ${client.name} (${client.code}) for ${rider.full_name}`);
    const updatedRider = await riderRepository.findById(riderId);
    return { rider: updatedRider, selectedClient: client };
  },

  getProfile: async (riderId) => {
    console.log(`[3][RIDER] Profile fetch - riderId: ${riderId}`);
    const rider = await riderRepository.findById(riderId);
    if (!rider) throw ApiError.notFound('Rider account nahi mila');

    let selectedClient = null;
    if (rider.selected_client_id) selectedClient = await clientRepository.findById(rider.selected_client_id);
    const documents = await documentRepository.findByRiderId(riderId);
    const bgvRecord = await bgvRepository.findByRiderId(riderId);

    console.log(`[3][RIDER] Profile fetched - ${rider.full_name}, stage: ${rider.onboarding_stage}, docs: ${documents.length}`);
    return { rider, client: selectedClient, documents, bgv: bgvRecord };
  },

  getAllRiders: async (filters = {}, page = 1, limit = 20) => {
    const offset = (page - 1) * limit;
    console.log(`[3][RIDER] Admin - sabhi riders fetch | page: ${page}, limit: ${limit}`);
    const [riders, total] = await Promise.all([
      riderRepository.findAll(filters, limit, offset),
      riderRepository.countAll(filters),
    ]);
    console.log(`[3][RIDER] Total ${total} riders mili`);
    return { riders, total, page, limit };
  },

  getFunnelStats: async () => {
    console.log(`[3][RIDER] Funnel stats fetch`);
    const stageCounts = await riderRepository.countByStage();

    const counts = {};
    let total = 0;
    stageCounts.forEach((item) => {
      counts[item.onboarding_stage] = item.count;
      total += item.count;
    });

    const funnel = {
      registered: total,
      documents_pending: counts.documents_pending || 0,
      documents_submitted: (counts.documents_submitted || 0) + (counts.bgv_pending || 0) + (counts.bgv_cleared || 0) + (counts.onboarded || 0) + (counts.live || 0),
      bgv_pending: counts.bgv_pending || 0,
      bgv_cleared: (counts.bgv_cleared || 0) + (counts.onboarded || 0) + (counts.live || 0),
      onboarded: (counts.onboarded || 0) + (counts.live || 0),
      live: counts.live || 0,
      total,
    };

    console.log(`[3][RIDER] Funnel ready - total: ${funnel.total}`);
    return funnel;
  },

  updateRiderByAdmin: async (riderId, updates) => {
    console.log(`[3][RIDER] Admin - rider update | riderId: ${riderId}, fields: ${Object.keys(updates).join(', ')}`);
    const rider = await riderRepository.findById(riderId);
    if (!rider) throw ApiError.notFound('Rider account nahi mila');

    await riderRepository.updateById(riderId, updates);
    console.log(`[3][RIDER] Rider updated - ${rider.full_name}`);
    return await riderRepository.findById(riderId);
  },
};

module.exports = riderService;

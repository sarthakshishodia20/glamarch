import api from './axiosInstance';

// ── Auth ──────────────────────────────────────
export const loginAdmin = (email, password) =>
  api.post('/auth/login/admin', { email, password });

export const getMe = () => api.get('/auth/me');

// ── Riders ───────────────────────────────────
export const getAllRiders = (params) =>
  api.get('/riders/admin/riders', { params });

export const getFunnelStats = () => api.get('/riders/admin/funnel');

export const updateRider = (id, data) =>
  api.patch(`/riders/admin/riders/${id}`, data);

export const bulkUploadRiders = (formData) =>
  api.post('/riders/admin/bulk-upload/riders', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });

// ── BGV ──────────────────────────────────────
export const getBgvQueue = () => api.get('/bgv/admin/queue');

export const updateBgvStatus = (id, data) =>
  api.post(`/bgv/admin/${id}/update`, data);

// ── Clients ──────────────────────────────────
export const getAllClients = () => api.get('/clients');

// ── Documents ────────────────────────────────
export const getRiderDocumentStatus = (riderId) =>
  api.get(`/documents/admin/rider/${riderId}/status`);

export const verifyRiderDocument = (docId, data) =>
  api.patch(`/documents/admin/${docId}/verify`, data);

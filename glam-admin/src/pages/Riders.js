import React, { useEffect, useState, useCallback } from 'react';
import { getAllRiders, updateRider, getRiderDocumentStatus, verifyRiderDocument } from '../api/glamApi';
import { useToast } from '../context/ToastContext';
import Loader from '../components/Loader';
import '../pages/Dashboard.css';

const DOC_LABELS = {
  aadhaar: 'Aadhaar Card',
  pan: 'PAN Card',
  vehicle_rc: 'Vehicle RC',
  driving_licence: 'Driving Licence',
  bank_passbook: 'Bank Passbook',
  selfie: 'Selfie Photo',
};

const STAGES = [
  '', 'registered', 'documents_pending', 'documents_submitted',
  'bgv_pending', 'bgv_cleared', 'onboarded', 'live'
];

// Custom debounce hook
function useDebounce(value, delay) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}

const Riders = () => {
  const { showToast } = useToast();
  const [riders, setRiders] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Filters
  const [stageFilter, setStageFilter] = useState('');
  const [cityInput, setCityInput] = useState('');
  const debouncedCity = useDebounce(cityInput, 500); // 500ms debounce

  // Inline edit
  const [editingId, setEditingId] = useState(null);
  const [editData, setEditData] = useState({});
  const [saving, setSaving] = useState(false);

  // Document Verification Modal
  const [docsModal, setDocsModal] = useState({ open: false, rider: null, loading: false, checklist: [] });

  const openDocsModal = async (rider) => {
    setDocsModal({ open: true, rider, loading: true, checklist: [] });
    try {
      const res = await getRiderDocumentStatus(rider.id);
      const data = res.data.data;
      setDocsModal({ open: true, rider, loading: false, checklist: data.checklist || [] });
    } catch (err) {
      showToast(err.response?.data?.message || 'Failed to fetch document checklist', 'error');
      setDocsModal((prev) => ({ ...prev, loading: false }));
    }
  };

  const handleVerifyDoc = async (docId, status) => {
    if (!docId) return;
    try {
      await verifyRiderDocument(docId, { status });
      showToast('success', `Document marked as ${status}`);
      if (docsModal.rider) {
        const res = await getRiderDocumentStatus(docsModal.rider.id);
        const data = res.data.data;
        setDocsModal((prev) => ({ ...prev, checklist: data.checklist || [] }));
      }
      fetchRiders();
    } catch (err) {
      showToast(err.response?.data?.message || 'Failed to update document status', 'error');
    }
  };

  const fetchRiders = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const params = { page, limit: 20 };
      if (stageFilter) params.stage = stageFilter;
      if (debouncedCity) params.city = debouncedCity;
      const res = await getAllRiders(params);
      const data = res.data.data;
      setRiders(data.riders || []);
      setTotal(data.total || data.riders?.length || 0);
    } catch (err) {
      setError('Failed to load riders.');
    } finally {
      setLoading(false);
    }
  }, [page, stageFilter, debouncedCity]);

  // Fetch when filters change (stage instant, city debounced)
  useEffect(() => {
    setPage(1);
  }, [stageFilter, debouncedCity]);

  useEffect(() => {
    fetchRiders();
  }, [fetchRiders]);

  const startEdit = (rider) => {
    setEditingId(rider.id);
    setEditData({
      assigned_hub_name: rider.assigned_hub_name || '',
      assigned_tl_name: rider.assigned_tl_name || '',
      assigned_tl_phone: rider.assigned_tl_phone || '',
      glam_worker_code: rider.glam_worker_code || '',
    });
  };

  const cancelEdit = () => { setEditingId(null); setEditData({}); };

  const saveEdit = async (id) => {
    setSaving(true);
    try {
      await updateRider(id, editData);
      showToast('Rider details updated successfully', 'success');
      cancelEdit();
      fetchRiders();
    } catch (err) {
      const msg = err.response?.data?.message || 'Update failed';
      showToast(msg, 'error');
    } finally {
      setSaving(false);
    }
  };

  const totalPages = Math.ceil(total / 20) || 1;

  return (
    <div className="page">
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
          <div>
            <h2 className="section-title" style={{ marginBottom: 0 }}>Riders</h2>
            <p className="section-subtitle">{total} riders total</p>
          </div>
          <button className="btn btn-secondary btn-sm" onClick={fetchRiders}>↻ Refresh</button>
        </div>

        {/* Filters */}
        <div className="filter-bar">
          <label>
            Stage
            <select
              value={stageFilter}
              onChange={(e) => setStageFilter(e.target.value)}
            >
              {STAGES.map((s) => (
                <option key={s} value={s}>{s || 'All Stages'}</option>
              ))}
            </select>
          </label>
          <label>
            City
            <input
              type="text"
              placeholder="e.g. Delhi"
              value={cityInput}
              onChange={(e) => setCityInput(e.target.value)}
            />
          </label>
          {(stageFilter || cityInput) && (
            <button
              className="btn btn-secondary btn-sm"
              style={{ alignSelf: 'flex-end' }}
              onClick={() => { setStageFilter(''); setCityInput(''); }}
            >
              Clear Filters
            </button>
          )}
        </div>

        {loading ? (
          <Loader text="Loading riders..." />
        ) : error ? (
          <div className="error-banner">
            {error} <button className="link-btn" onClick={fetchRiders}>Retry</button>
          </div>
        ) : riders.length === 0 ? (
          <p style={{ color: '#6b7280', fontSize: 13 }}>No riders found.</p>
        ) : (
          <>
            <div className="table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Phone</th>
                    <th>City</th>
                    <th>Stage</th>
                    <th>Hub</th>
                    <th>TL Name</th>
                    <th>Worker Code</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {riders.map((rider) =>
                    editingId === rider.id ? (
                      <tr key={rider.id}>
                        <td>{rider.full_name}</td>
                        <td>{rider.phone_number}</td>
                        <td>{rider.city}</td>
                        <td>
                          <span className={`badge badge-${rider.onboarding_stage}`}>
                            {rider.onboarding_stage}
                          </span>
                        </td>
                        <td>
                          <input className="inline-input" value={editData.assigned_hub_name}
                            onChange={(e) => setEditData({ ...editData, assigned_hub_name: e.target.value })} />
                        </td>
                        <td>
                          <input className="inline-input" value={editData.assigned_tl_name}
                            onChange={(e) => setEditData({ ...editData, assigned_tl_name: e.target.value })} />
                        </td>
                        <td>
                          <input className="inline-input" value={editData.glam_worker_code}
                            onChange={(e) => setEditData({ ...editData, glam_worker_code: e.target.value })} />
                        </td>
                        <td>
                          <div style={{ display: 'flex', gap: 6 }}>
                            <button className="btn btn-primary btn-sm" onClick={() => saveEdit(rider.id)} disabled={saving}>
                              {saving ? '...' : 'Save'}
                            </button>
                            <button className="btn btn-secondary btn-sm" onClick={cancelEdit}>Cancel</button>
                          </div>
                        </td>
                      </tr>
                    ) : (
                      <tr key={rider.id}>
                        <td>{rider.full_name}</td>
                        <td>{rider.phone_number}</td>
                        <td>{rider.city}</td>
                        <td>
                          <span className={`badge badge-${rider.onboarding_stage}`}>
                            {rider.onboarding_stage}
                          </span>
                        </td>
                        <td>{rider.assigned_hub_name || '—'}</td>
                        <td>{rider.assigned_tl_name || '—'}</td>
                        <td>{rider.glam_worker_code || '—'}</td>
                        <td>
                          <div style={{ display: 'flex', gap: 6 }}>
                            <button className="btn btn-secondary btn-sm" onClick={() => startEdit(rider)}>
                              Edit
                            </button>
                            <button className="btn btn-secondary btn-sm" onClick={() => openDocsModal(rider)}>
                              Docs
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  )}
                </tbody>
              </table>
            </div>

            <div className="pagination">
              <button
                className="btn btn-secondary btn-sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
              >
                ← Prev
              </button>
              <span>Page {page} of {totalPages}</span>
              <button
                className="btn btn-secondary btn-sm"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
              >
                Next →
              </button>
            </div>
          </>
        )}
      </div>

      {/* Document Verification Modal */}
      {docsModal.open && (
        <div className="modal-overlay" onClick={() => setDocsModal({ open: false, rider: null, loading: false, checklist: [] })}>
          <div className="modal-box" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 640 }}>
            <h3 className="modal-title">
              Document Verification — {docsModal.rider?.full_name}
            </h3>

            {docsModal.loading ? (
              <p style={{ fontSize: 13, color: '#6b7280', padding: 20, textAlign: 'center' }}>Loading documents checklist...</p>
            ) : (
              <div className="table-wrap" style={{ marginTop: 12 }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Document</th>
                      <th>Upload Status</th>
                      <th>Verification</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {docsModal.checklist.map((doc) => (
                      <tr key={doc.document_type}>
                        <td><strong>{DOC_LABELS[doc.document_type] || doc.document_type}</strong></td>
                        <td>
                          {doc.is_uploaded ? (
                            <span style={{ color: '#059669', fontWeight: 600 }}>Uploaded</span>
                          ) : (
                            <span style={{ color: '#9ca3af' }}>Pending Upload</span>
                          )}
                        </td>
                        <td>
                          <span className={`badge badge-${doc.status || 'pending'}`}>
                            {doc.status || 'pending'}
                          </span>
                        </td>
                        <td>
                          {doc.is_uploaded && doc.id ? (
                            <div style={{ display: 'flex', gap: 6 }}>
                              <button
                                className="btn btn-sm"
                                style={{ background: '#10b981', color: '#fff' }}
                                onClick={() => handleVerifyDoc(doc.id, 'approved')}
                                disabled={doc.status === 'approved'}
                              >
                                Approve
                              </button>
                              <button
                                className="btn btn-sm"
                                style={{ background: '#ef4444', color: '#fff' }}
                                onClick={() => handleVerifyDoc(doc.id, 'rejected')}
                                disabled={doc.status === 'rejected'}
                              >
                                Reject
                              </button>
                            </div>
                          ) : (
                            <span style={{ fontSize: 12, color: '#9ca3af' }}>—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            <div className="modal-actions" style={{ marginTop: 20 }}>
              <button
                className="btn btn-secondary"
                onClick={() => setDocsModal({ open: false, rider: null, loading: false, checklist: [] })}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Riders;

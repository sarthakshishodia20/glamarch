import React, { useEffect, useState } from 'react';
import { getBgvQueue, updateBgvStatus } from '../api/glamApi';
import { useToast } from '../context/ToastContext';
import Loader from '../components/Loader';
import '../pages/Dashboard.css';

const BgvQueue = () => {
  const { showToast } = useToast();
  const [queue, setQueue] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [updating, setUpdating] = useState(null);
  const [modal, setModal] = useState(null); // { riderId, action: 'cleared'|'rejected' }
  const [remarks, setRemarks] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');

  const fetchQueue = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await getBgvQueue();
      setQueue(res.data.data || []);
    } catch (err) {
      setError('Failed to load BGV queue.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchQueue(); }, []);

  const openModal = (item, action) => {
    setModal({ id: item.id, riderName: item.rider_name || item.full_name, action });
    setRemarks('');
    setRejectionReason('');
  };

  const submitUpdate = async () => {
    setUpdating(modal.id);
    try {
      await updateBgvStatus(modal.id, {
        status: modal.action,
        remarks,
        rejection_reason: modal.action === 'rejected' ? rejectionReason : undefined,
      });
      showToast(`BGV status marked as ${modal.action.toUpperCase()} for ${modal.riderName}`, 'success');
      setModal(null);
      fetchQueue();
    } catch (err) {
      const msg = err.response?.data?.message || 'Update failed';
      showToast(msg, 'error');
    } finally {
      setUpdating(null);
    }
  };

  return (
    <div className="page">
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
          <div>
            <h2 className="section-title" style={{ marginBottom: 0 }}>BGV Queue</h2>
            <p className="section-subtitle">Pending background verifications — manually clear or reject</p>
          </div>
          <button className="btn btn-secondary btn-sm" onClick={fetchQueue}>↻ Refresh</button>
        </div>

        {loading ? (
          <Loader text="Loading BGV queue..." />
        ) : error ? (
          <div className="error-banner">{error} <button className="link-btn" onClick={fetchQueue}>Retry</button></div>
        ) : queue.length === 0 ? (
          <p style={{ fontSize: 13, color: '#6b7280' }}>No pending BGV verifications.</p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Rider Name</th>
                  <th>Phone</th>
                  <th>Client</th>
                  <th>BGV Owner</th>
                  <th>Status</th>
                  <th>Triggered At</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {queue.map((item) => (
                  <tr key={item.id}>
                    <td>{item.rider_name || item.full_name}</td>
                    <td>{item.phone_number}</td>
                    <td>{item.client_name || '—'}</td>
                    <td>{item.bgv_owner}</td>
                    <td>
                      <span className={`badge badge-${item.status}`}>{item.status}</span>
                    </td>
                    <td>{item.triggered_at ? new Date(item.triggered_at).toLocaleDateString('en-IN') : '—'}</td>
                    <td style={{ display: 'flex', gap: 6 }}>
                      <button
                        className="btn btn-primary btn-sm"
                        onClick={() => openModal(item, 'cleared')}
                        disabled={updating === item.id}
                      >
                        Clear
                      </button>
                      <button
                        className="btn btn-danger btn-sm"
                        onClick={() => openModal(item, 'rejected')}
                        disabled={updating === item.id}
                      >
                        Reject
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal-box" onClick={(e) => e.stopPropagation()}>
            <h3 className="modal-title">
              {modal.action === 'cleared' ? 'Clear BGV' : 'Reject BGV'} — {modal.riderName}
            </h3>

            {modal.action === 'rejected' && (
              <div className="form-group" style={{ marginBottom: 12 }}>
                <label style={{ fontSize: 13, fontWeight: 500, color: '#374151', display: 'block', marginBottom: 4 }}>
                  Rejection Reason <span style={{ color: '#dc2626' }}>*</span>
                </label>
                <input
                  type="text"
                  className="modal-input"
                  placeholder="e.g. Criminal record found"
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                />
              </div>
            )}

            <div className="form-group" style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 13, fontWeight: 500, color: '#374151', display: 'block', marginBottom: 4 }}>
                Remarks (optional)
              </label>
              <textarea
                className="modal-input"
                rows={3}
                placeholder="Add any notes..."
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button className="btn btn-secondary" onClick={() => setModal(null)}>Cancel</button>
              <button
                className={`btn ${modal.action === 'cleared' ? 'btn-primary' : 'btn-danger'}`}
                onClick={submitUpdate}
                disabled={updating === modal.id || (modal.action === 'rejected' && !rejectionReason)}
              >
                {updating === modal.id ? 'Updating...' : 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default BgvQueue;

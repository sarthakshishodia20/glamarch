import React, { useEffect, useState } from 'react';
import { getAllClients } from '../api/glamApi';
import Loader from '../components/Loader';
import '../pages/Dashboard.css';

const BRAND_LOGOS = {
  BLINKIT: { bg: '#facc15', color: '#713f12', letter: 'B' },
  ZEPTO: { bg: '#8b5cf6', color: '#ffffff', letter: 'Z' },
  FKM: { bg: '#2563eb', color: '#ffffff', letter: 'F' },
};

const Clients = () => {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchClients = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await getAllClients();
      setClients(res.data.data || []);
    } catch (err) {
      setError('Failed to load clients.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchClients(); }, []);

  return (
    <div className="page">
      <div className="card">
        <h2 className="section-title">Clients &amp; Hubs</h2>

        {loading ? (
          <Loader text="Loading clients..." />
        ) : error ? (
          <div className="error-banner">{error} <button className="link-btn" onClick={fetchClients}>Retry</button></div>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Code</th>
                  <th>Rate / Order</th>
                  <th>Avg Daily Earning</th>
                  <th>Payout Cycle</th>
                  <th>BGV Owner</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {clients.map((c) => (
                  <tr key={c.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <div style={{
                          width: 32,
                          height: 32,
                          borderRadius: 8,
                          background: BRAND_LOGOS[c.code]?.bg || '#e2e8f0',
                          color: BRAND_LOGOS[c.code]?.color || '#475569',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          fontSize: 15,
                          flexShrink: 0,
                          boxShadow: '0 1px 2px rgba(0,0,0,0.08)'
                        }}>
                          {BRAND_LOGOS[c.code]?.letter || c.code.charAt(0)}
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, color: '#111827' }}>{c.name}</div>
                          <div style={{ fontSize: 11, color: '#6b7280' }}>Partner Client</div>
                        </div>
                      </div>
                    </td>
                    <td><code>{c.code}</code></td>
                    <td>₹{c.rate_per_order}</td>
                    <td>₹{c.avg_daily_earning}</td>
                    <td style={{ textTransform: 'capitalize' }}>{c.payout_cycle}</td>
                    <td style={{ textTransform: 'capitalize' }}>{c.bgv_owner}</td>
                    <td>
                      <span className={`badge ${c.is_active ? 'badge-live' : 'badge-rejected'}`}>
                        {c.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default Clients;

import React, { useEffect, useState } from 'react';
import { getFunnelStats } from '../api/glamApi';
import Loader from '../components/Loader';
import './Dashboard.css';

const funnelLabels = [
  { key: 'registered', label: 'Registered' },
  { key: 'documents_submitted', label: 'Docs Uploaded' },
  { key: 'bgv_cleared', label: 'BGV Cleared' },
  { key: 'onboarded', label: 'Client Onboarded' },
  { key: 'live', label: 'Live' },
];

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchStats = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await getFunnelStats();
      setStats(res.data.data);
    } catch (err) {
      setError('Could not load funnel stats.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  return (
    <div className="page">
      <p className="page-description">
        Internal ops console: bulk CSV/Excel upload for rider master, documents, BGV status and payouts, plus the onboarding funnel dashboard.
      </p>

      <div className="card">
        <h2 className="section-title">Onboarding Funnel — Live Snapshot</h2>
        {loading ? (
          <Loader text="Fetching funnel stats..." />
        ) : error ? (
          <div className="error-banner">
            {error}{' '}
            <button className="link-btn" onClick={fetchStats}>Retry</button>
          </div>
        ) : (
          <div className="funnel-grid">
            {funnelLabels.map(({ key, label }) => (
              <div className="funnel-card" key={key}>
                <span className="funnel-count">{stats?.[key] ?? '—'}</span>
                <span className="funnel-label">{label}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard;

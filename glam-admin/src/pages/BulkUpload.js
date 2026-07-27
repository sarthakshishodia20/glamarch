import React, { useRef, useState } from 'react';
import { bulkUploadRiders, getFunnelStats } from '../api/glamApi';
import { useToast } from '../context/ToastContext';
import '../pages/Dashboard.css';
import './BulkUpload.css';

const EXPECTED_COLUMNS = 'full_name, phone_number, gender, city, preferred_language, client_code, hub_name, tl_name, vehicle_number';

const TEMPLATE_CSV = `full_name,phone_number,gender,city,preferred_language,client_code,hub_name,tl_name,vehicle_number
Ravi Kumar,9876541001,male,Delhi,hindi,FKM,Lajpat Nagar Hub,Amit Singh,DL01AB1001
Priya Sharma,9876541002,female,Mumbai,hindi,ZEPTO,Andheri East Hub,Neha Verma,MH02CD1002
Suresh Yadav,9876541003,male,Gurugram,hindi,BLINKIT,Sector 29 Hub,Rajesh Khanna,HR26EF1003
Deepak Verma,9876541004,male,Noida,hindi,FKM,Sector 62 Hub,Amit Singh,UP16GH1004
Anjali Nair,9876541005,female,Bengaluru,english,ZEPTO,Koramangala Hub,Pooja Reddy,KA03IJ1005`;

const funnelLabels = [
  { key: 'registered', label: 'Registered' },
  { key: 'documents_submitted', label: 'Docs Uploaded' },
  { key: 'bgv_cleared', label: 'BGV Cleared' },
  { key: 'onboarded', label: 'Client Onboarded' },
  { key: 'live', label: 'Live' },
];

const BulkUpload = () => {
  const { showToast } = useToast();
  const fileRef = useRef(null);
  const [file, setFile] = useState(null);
  const [dragOver, setDragOver] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [result, setResult] = useState(null);
  const [uploadError, setUploadError] = useState('');

  const [funnel, setFunnel] = useState(null);
  const [funnelLoading, setFunnelLoading] = useState(false);

  const handleFile = (f) => {
    if (!f) return;
    const ext = f.name.split('.').pop().toLowerCase();
    if (!['csv', 'xlsx', 'xls'].includes(ext)) {
      const msg = 'Only CSV or Excel files are supported.';
      setUploadError(msg);
      showToast(msg, 'error');
      return;
    }
    setFile(f);
    setUploadError('');
    setResult(null);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    handleFile(e.dataTransfer.files[0]);
  };

  const handleUpload = async () => {
    if (!file) return;
    setUploading(true);
    setUploadError('');
    setResult(null);
    const fd = new FormData();
    fd.append('csv_file', file);
    try {
      const res = await bulkUploadRiders(fd);
      const data = res.data.data;
      setResult(data);
      showToast(`Bulk upload completed: ${data.inserted} inserted, ${data.skipped} skipped`, 'success');
      // Refresh funnel after upload
      loadFunnel();
    } catch (err) {
      const msg = err.response?.data?.message || 'Upload failed. Please try again.';
      setUploadError(msg);
      showToast(msg, 'error');
    } finally {
      setUploading(false);
    }
  };

  const downloadTemplate = () => {
    const blob = new Blob([TEMPLATE_CSV], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'rider_master_template.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  const loadFunnel = async () => {
    setFunnelLoading(true);
    try {
      const res = await getFunnelStats();
      setFunnel(res.data.data);
    } catch (_) {}
    finally { setFunnelLoading(false); }
  };

  // Load funnel on first render
  React.useEffect(() => { loadFunnel(); }, []);

  return (
    <div className="page">
      {/* Upload progress indicator — inline inside card area, not full-page */}

      {/* Upload Section */}
      <div className="card">
        <h2 className="section-title" style={{ marginBottom: 4 }}>Bulk Upload — Rider Master</h2>
        <p className="section-subtitle" style={{ marginBottom: 20 }}>
          Upload a CSV or Excel file. Expected columns: <code>{EXPECTED_COLUMNS}</code>
        </p>

        {/* Drop Zone */}
        <div
          className={`drop-zone${dragOver ? ' drop-zone--active' : ''}${file ? ' drop-zone--filled' : ''}`}
          onClick={() => fileRef.current?.click()}
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={handleDrop}
        >
          <input
            ref={fileRef}
            type="file"
            accept=".csv,.xlsx,.xls"
            style={{ display: 'none' }}
            onChange={(e) => handleFile(e.target.files[0])}
          />
          <svg className="drop-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-3-3v6M4.5 12a7.5 7.5 0 1115 0 7.5 7.5 0 01-15 0z" />
            <rect x="3" y="3" width="18" height="18" rx="3" />
            <path strokeLinecap="round" d="M8 12h8M12 8v8" />
          </svg>

          {file ? (
            <div>
              <p className="drop-main">{file.name}</p>
              <p className="drop-sub">{(file.size / 1024).toFixed(1)} KB — click to change</p>
            </div>
          ) : (
            <div>
              <p className="drop-main">Drop CSV/Excel file here, or click to browse</p>
              <p className="drop-sub">Supports .csv, .xlsx, .xls</p>
            </div>
          )}
        </div>

        {uploadError && (
          <div className="error-banner" style={{ marginTop: 12 }}>{uploadError}</div>
        )}

        {result && (
          <div className="upload-result">
            <p><strong>{result.inserted}</strong> riders inserted · <strong>{result.skipped}</strong> skipped (duplicates)</p>
            {result.errors?.length > 0 && (
              <details>
                <summary style={{ cursor: 'pointer', fontSize: 12, color: '#dc2626' }}>
                  {result.errors.length} row errors
                </summary>
                <ul style={{ fontSize: 12, marginTop: 6, paddingLeft: 16 }}>
                  {result.errors.slice(0, 10).map((e, i) => (
                    <li key={i}>{e}</li>
                  ))}
                </ul>
              </details>
            )}
          </div>
        )}

        <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
          <button className="btn btn-primary" onClick={handleUpload} disabled={!file || uploading}>
            Validate &amp; Import
          </button>
          <button className="btn btn-secondary" onClick={downloadTemplate}>
            Download Template
          </button>
          {file && (
            <button className="btn btn-secondary" onClick={() => { setFile(null); setResult(null); }}>
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Funnel Snapshot */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h2 className="section-title" style={{ marginBottom: 0 }}>Onboarding Funnel — Live Snapshot</h2>
          <button className="btn btn-secondary btn-sm" onClick={loadFunnel} disabled={funnelLoading}>
            {funnelLoading ? 'Refreshing...' : '↻ Refresh'}
          </button>
        </div>
        {funnelLoading ? (
          <p style={{ fontSize: 13, color: '#6b7280' }}>Loading...</p>
        ) : (
          <div className="funnel-grid">
            {funnelLabels.map(({ key, label }) => (
              <div className="funnel-card" key={key}>
                <span className="funnel-count">{funnel?.[key] ?? '—'}</span>
                <span className="funnel-label">{label}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default BulkUpload;

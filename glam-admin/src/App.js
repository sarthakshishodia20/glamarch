import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ToastProvider } from './context/ToastContext';
import Layout from './components/Layout';
import Loader from './components/Loader';

import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Riders from './pages/Riders';
import BulkUpload from './pages/BulkUpload';
import BgvQueue from './pages/BgvQueue';
import Payouts from './pages/Payouts';
import Clients from './pages/Clients';

// Guard: if not logged in → redirect to /login
// Layout renders ONCE here — sidebar stays constant, only <Outlet> changes
const ProtectedLayout = () => {
  const { token, loading } = useAuth();
  if (loading) return <Loader variant="overlay" text="Verifying session..." />;
  if (!token) return <Navigate to="/login" replace />;
  return (
    <Layout>
      <Outlet />
    </Layout>
  );
};

const AppRoutes = () => {
  const { token, loading } = useAuth();
  if (loading) return <Loader variant="overlay" text="Initializing..." />;

  return (
    <Routes>
      {/* Public */}
      <Route
        path="/login"
        element={token ? <Navigate to="/" replace /> : <Login />}
      />

      {/* Protected — Layout renders once, Outlet swaps pages */}
      <Route element={<ProtectedLayout />}>
        <Route path="/" element={<Dashboard />} />
        <Route path="/riders" element={<Riders />} />
        <Route path="/bulk-upload" element={<BulkUpload />} />
        <Route path="/bgv-queue" element={<BgvQueue />} />
        <Route path="/payouts" element={<Payouts />} />
        <Route path="/clients" element={<Clients />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

const App = () => (
  <BrowserRouter>
    <AuthProvider>
      <ToastProvider>
        <AppRoutes />
      </ToastProvider>
    </AuthProvider>
  </BrowserRouter>
);

export default App;

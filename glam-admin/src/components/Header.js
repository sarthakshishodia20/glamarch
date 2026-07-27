import React from 'react';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import './Header.css';

const Header = () => {
  const { user, logout } = useAuth();
  const { showToast } = useToast();

  const handleLogout = () => {
    showToast('Logged out successfully', 'info');
    logout();
  };

  return (
    <header className="header">
      <span className="header-title">GLAM Ops Console — Rider Onboarding</span>
      <div className="header-right">
        <span className="header-user">
          {user?.name || 'Admin'} · {formatRole(user?.role)}
        </span>
        <button className="header-logout" onClick={handleLogout}>
          Logout
        </button>
      </div>
    </header>
  );
};

function formatRole(role) {
  if (!role) return '';
  const map = {
    super_admin: 'Super Admin',
    ops: 'Ops',
    retention: 'Retention',
    admin: 'Admin',
  };
  return map[role] || role;
}

export default Header;

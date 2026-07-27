import React from 'react';
import { NavLink } from 'react-router-dom';
import './Sidebar.css';

const navItems = [
  { label: 'Dashboard', path: '/' },
  { label: 'Riders', path: '/riders' },
  { label: 'Bulk Upload', path: '/bulk-upload' },
  { label: 'BGV Queue', path: '/bgv-queue' },
  { label: 'Payouts', path: '/payouts' },
  { label: 'Clients & Hubs', path: '/clients' },
];

const Sidebar = () => (
  <aside className="sidebar">
    {navItems.map((item) => (
      <NavLink
        key={item.path}
        to={item.path}
        end={item.path === '/'}
        className={({ isActive }) =>
          'sidebar-link' + (isActive ? ' sidebar-link--active' : '')
        }
      >
        {item.label}
      </NavLink>
    ))}
  </aside>
);

export default Sidebar;

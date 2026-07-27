import React from 'react';
import Header from './Header';
import Sidebar from './Sidebar';
import './Layout.css';

const Layout = ({ children }) => (
  <div className="layout-root">
    <Header />
    <div className="layout-body">
      <Sidebar />
      <main className="layout-main">{children}</main>
    </div>
  </div>
);

export default Layout;

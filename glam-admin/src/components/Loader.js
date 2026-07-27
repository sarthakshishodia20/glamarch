import React from 'react';
import './Loader.css';

/**
 * variant="overlay" → full-page fixed overlay (use only for auth/init)
 * variant="inline"  → sits inside a card, sidebar stays visible (use in pages)
 */
const Loader = ({ text = 'Loading...', variant = 'inline' }) => {
  if (variant === 'overlay') {
    return (
      <div className="loader-overlay">
        <div className="loader-box">
          <div className="spinner"></div>
          <p className="loader-text">{text}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="loader-inline">
      <div className="spinner"></div>
      <p className="loader-text">{text}</p>
    </div>
  );
};

export default Loader;

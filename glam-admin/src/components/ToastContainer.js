import React from 'react';
import './ToastContainer.css';

const ToastContainer = ({ toasts, onDismiss }) => {
  if (!toasts || toasts.length === 0) return null;

  return (
    <div className="toast-container-bottom-left">
      {toasts.map((toast) => (
        <div
          key={toast.id}
          className={`toast-rect toast-rect--${toast.type}`}
          onClick={() => onDismiss(toast.id)}
        >
          <div className="toast-content">
            <span className="toast-icon">
              {toast.type === 'success' && 'OK'}
              {toast.type === 'error' && '!'}
              {toast.type === 'info' && 'i'}
            </span>
            <span className="toast-msg">{toast.message}</span>
          </div>
          <span className="toast-close">×</span>
        </div>
      ))}
    </div>
  );
};

export default ToastContainer;

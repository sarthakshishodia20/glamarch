import React, { createContext, useContext, useState, useEffect } from 'react';
import { loginAdmin, getMe } from '../api/glamApi';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('glam_token') || null);
  const [loading, setLoading] = useState(true);

  // On mount: if token exists, verify it
  useEffect(() => {
    if (token) {
      getMe()
        .then((res) => setUser(res.data.data))
        .catch(() => {
          localStorage.removeItem('glam_token');
          setToken(null);
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, [token]);

  const login = async (email, password) => {
    const res = await loginAdmin(email, password);
    const { token: newToken, admin } = res.data.data;
    localStorage.setItem('glam_token', newToken);
    setToken(newToken);
    setUser(admin);
    return admin;
  };

  const logout = () => {
    localStorage.removeItem('glam_token');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);

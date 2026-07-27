const pool = require('../config/db');

const adminRepository = {
  findByEmail: async (email) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_admins WHERE email = ? LIMIT 1',
      [email]
    );
    return rows[0] || null;
  },

  findById: async (id) => {
    const [rows] = await pool.query(
      'SELECT id, name, email, role, is_active, created_at FROM tb_admins WHERE id = ? LIMIT 1',
      [id]
    );
    return rows[0] || null;
  },

  create: async (data) => {
    const { name, email, password_hash, role } = data;
    const [result] = await pool.query(
      'INSERT INTO tb_admins (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [name, email, password_hash, role]
    );
    return result.insertId;
  },

  findAll: async () => {
    const [rows] = await pool.query(
      'SELECT id, name, email, role, is_active, created_at FROM tb_admins ORDER BY created_at DESC'
    );
    return rows;
  },
};

module.exports = adminRepository;

const pool = require('../config/db');

const riderRepository = {
  findByPhone: async (phone_number) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_riders WHERE phone_number = ? LIMIT 1',
      [phone_number]
    );
    return rows[0] || null;
  },

  findById: async (id) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_riders WHERE id = ? LIMIT 1',
      [id]
    );
    return rows[0] || null;
  },

  create: async (data) => {
    const { id, full_name, phone_number, gender, city, preferred_language } = data;
    const [result] = await pool.query(
      `INSERT INTO tb_riders (id, full_name, phone_number, gender, city, preferred_language)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, full_name, phone_number, gender, city, preferred_language]
    );
    return result.insertId;
  },

  updateById: async (id, updates) => {
    const keys = Object.keys(updates);
    const values = Object.values(updates);
    const setClause = keys.map((k) => `${k} = ?`).join(', ');

    const [result] = await pool.query(
      `UPDATE tb_riders SET ${setClause}, updated_at = NOW() WHERE id = ?`,
      [...values, id]
    );
    return result.affectedRows;
  },

  findAll: async (filters = {}, limit = 20, offset = 0) => {
    let query = 'SELECT * FROM tb_riders WHERE 1=1';
    const values = [];

    if (filters.onboarding_stage) {
      query += ' AND onboarding_stage = ?';
      values.push(filters.onboarding_stage);
    }
    if (filters.city) {
      query += ' AND city LIKE ?';
      values.push(`%${filters.city}%`);
    }
    if (filters.selected_client_id) {
      query += ' AND selected_client_id = ?';
      values.push(filters.selected_client_id);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    values.push(limit, offset);

    const [rows] = await pool.query(query, values);
    return rows;
  },

  countAll: async (filters = {}) => {
    let query = 'SELECT COUNT(*) as total FROM tb_riders WHERE 1=1';
    const values = [];
    if (filters.onboarding_stage) { query += ' AND onboarding_stage = ?'; values.push(filters.onboarding_stage); }
    if (filters.city) { query += ' AND city LIKE ?'; values.push(`%${filters.city}%`); }
    if (filters.selected_client_id) { query += ' AND selected_client_id = ?'; values.push(filters.selected_client_id); }
    const [[{ total }]] = await pool.query(query, values);
    return total;
  },

  countByStage: async () => {
    const [rows] = await pool.query(
      `SELECT onboarding_stage, COUNT(*) as count
       FROM tb_riders
       GROUP BY onboarding_stage`
    );
    return rows;
  },
};

module.exports = riderRepository;

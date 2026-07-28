const pool = require('../config/db');

const bgvRepository = {
  create: async (data) => {
    const { rider_id, client_id, bgv_owner } = data;
    const [result] = await pool.query(
      `INSERT INTO tb_bgv (rider_id, client_id, bgv_owner, status, triggered_at)
       VALUES (?, ?, ?, 'triggered', NOW())`,
      [rider_id, client_id, bgv_owner]
    );
    return result.insertId;
  },

  findByRiderId: async (rider_id) => {
    const [rows] = await pool.query(
      `SELECT b.*, c.name as client_name
       FROM tb_bgv b
       JOIN tb_clients c ON b.client_id = c.id
       WHERE b.rider_id = ?
       ORDER BY b.triggered_at DESC
       LIMIT 1`,
      [rider_id]
    );
    return rows[0] || null;
  },

  findById: async (id) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_bgv WHERE id = ? LIMIT 1',
      [id]
    );
    return rows[0] || null;
  },

  updateStatus: async (id, updates) => {
    const keys = Object.keys(updates);
    const values = Object.values(updates);
    const setClause = keys.map((k) => `${k} = ?`).join(', ');

    const [result] = await pool.query(
      `UPDATE tb_bgv SET ${setClause}, updated_at = NOW() WHERE id = ?`,
      [...values, id]
    );
    return result.affectedRows;
  },

  findPendingForGlam: async () => {
    const [rows] = await pool.query(
      `SELECT b.*, r.full_name, r.phone_number, c.name as client_name
       FROM tb_bgv b
       JOIN tb_riders r ON b.rider_id = r.id
       JOIN tb_clients c ON b.client_id = c.id
       WHERE b.bgv_owner = 'glam' AND b.status IN ('triggered', 'in_progress')
       ORDER BY b.triggered_at ASC`
    );
    return rows;
  },
};

module.exports = bgvRepository;

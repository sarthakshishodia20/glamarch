const pool = require('../config/db');

const clientRepository = {
  findAllActive: async () => {
    const [rows] = await pool.query(
      `SELECT id, name, code, rate_per_order, avg_daily_earning,
              payout_cycle, bgv_owner, description, is_active
       FROM tb_clients
       WHERE is_active = TRUE
       ORDER BY name ASC`
    );
    return rows;
  },

  findById: async (id) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_clients WHERE id = ? LIMIT 1',
      [id]
    );
    return rows[0] || null;
  },

  findByCode: async (code) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_clients WHERE code = ? LIMIT 1',
      [code]
    );
    return rows[0] || null;
  },
};

module.exports = clientRepository;

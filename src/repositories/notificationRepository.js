const pool = require('../config/db');

const notificationRepository = {
  create: async (data) => {
    const { rider_id, type, channel, title, body, payload, status = 'sent' } = data;
    const [result] = await pool.query(
      `INSERT INTO tb_notifications (rider_id, type, channel, title, body, payload, status, sent_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
      [rider_id, type, channel, title, body, JSON.stringify(payload || {}), status]
    );
    return result.insertId;
  },

  findByRiderId: async (rider_id, limit = 20) => {
    const [rows] = await pool.query(
      `SELECT id, type, channel, title, body, status, sent_at
       FROM tb_notifications
       WHERE rider_id = ?
       ORDER BY sent_at DESC
       LIMIT ?`,
      [rider_id, limit]
    );
    return rows;
  },

  updateStatus: async (id, status) => {
    const [result] = await pool.query(
      'UPDATE tb_notifications SET status = ? WHERE id = ?',
      [status, id]
    );
    return result.affectedRows;
  },
};

module.exports = notificationRepository;

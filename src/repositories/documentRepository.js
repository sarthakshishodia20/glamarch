const pool = require('../config/db');

const documentRepository = {
  create: async (data) => {
    const { id, rider_id, document_type, file_path, file_name, mime_type } = data;
    const [result] = await pool.query(
      `INSERT INTO tb_documents (id, rider_id, document_type, file_path, file_name, mime_type)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, rider_id, document_type, file_path, file_name, mime_type]
    );
    return result.insertId;
  },

  findByRiderId: async (rider_id) => {
    const [rows] = await pool.query(
      `SELECT id, document_type, file_name, status, rejection_reason, uploaded_at, verified_at
       FROM tb_documents
       WHERE rider_id = ?
       ORDER BY uploaded_at DESC`,
      [rider_id]
    );
    return rows;
  },

  findById: async (id) => {
    const [rows] = await pool.query(
      'SELECT * FROM tb_documents WHERE id = ? LIMIT 1',
      [id]
    );
    return rows[0] || null;
  },

  updateStatus: async (id, updates) => {
    const keys = Object.keys(updates);
    const values = Object.values(updates);
    const setClause = keys.map((k) => `${k} = ?`).join(', ');

    const [result] = await pool.query(
      `UPDATE tb_documents SET ${setClause}, updated_at = NOW() WHERE id = ?`,
      [...values, id]
    );
    return result.affectedRows;
  },

  countApprovedByRider: async (rider_id) => {
    const [rows] = await pool.query(
      `SELECT COUNT(*) as count FROM tb_documents
       WHERE rider_id = ? AND status = 'approved'`,
      [rider_id]
    );
    return rows[0].count;
  },

  findDuplicateDocNumber: async (document_type, document_number, exclude_rider_id) => {
    const [rows] = await pool.query(
      `SELECT id FROM tb_documents
       WHERE document_type = ? AND document_number = ? AND rider_id != ?
       LIMIT 1`,
      [document_type, document_number, exclude_rider_id]
    );
    return rows[0] || null;
  },
};

module.exports = documentRepository;

const mysql = require('mysql2/promise');
require('dotenv').config();
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ...(process.env.DB_SOCKET ? { socketPath: process.env.DB_SOCKET } : {}),
  ...(process.env.DB_SSL === 'true' ? { ssl: { rejectUnauthorized: false } } : {}),
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: '+05:30',
});

pool.getConnection()
  .then(async (connection) => {
    console.log('MySQL connected successfully to database:', process.env.DB_NAME);
    
    // Auto-migrate: Add fcm_token column if it doesn't exist
    try {
      await connection.query('ALTER TABLE tb_riders ADD COLUMN fcm_token TEXT NULL');
      console.log('Auto-migration: fcm_token column added successfully!');
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') {
        console.warn('Auto-migration skipped or failed:', e.message);
      }
    }
    
    connection.release();
  })
  .catch(err => {
    console.error('MySQL connection failed:', err.message);
    console.error('   Check your .env file DB_* values and make sure MySQL is running.');
    process.exit(1);
  });

module.exports = pool;

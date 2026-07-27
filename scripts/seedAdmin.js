/**
 * Seed Script: Create a super_admin account for GLAM Ops Console
 * Run: node scripts/seedAdmin.js
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');

async function seedAdmin() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    socketPath: process.env.DB_SOCKET,
  });

  const email = 'admin@glam.in';
  const password = 'Admin@1234';
  const name = 'Abhinav Singh';
  const role = 'super_admin';

  const passwordHash = await bcrypt.hash(password, 10);

  try {
    await conn.execute(
      'INSERT INTO tb_admins (name, email, password_hash, role, is_active) VALUES (?, ?, ?, ?, 1)',
      [name, email, passwordHash, role]
    );
    console.log('Admin created successfully!');
    console.log(`   Email   : ${email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Role    : ${role}`);
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      console.log('ℹ Admin already exists with email:', email);
    } else {
      console.error(' Error:', err.message);
    }
  } finally {
    await conn.end();
  }
}

seedAdmin();

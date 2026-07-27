const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

// Logs folder exist nahi hai toh bana do
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir, { recursive: true });

const accessLogStream = fs.createWriteStream(path.join(logsDir, 'access.log'), { flags: 'a' });

// Morgan middleware — terminal pe dev format, file mein combined format
const morganDev = morgan('dev');
const morganFile = morgan('combined', { stream: accessLogStream });

module.exports = { morganDev, morganFile };

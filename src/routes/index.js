const express = require('express');

const authRoutes = require('./authRoutes');
const riderRoutes = require('./riderRoutes');
const clientRoutes = require('./clientRoutes');
const documentRoutes = require('./documentRoutes');
const bgvRoutes = require('./bgvRoutes');
const notificationRoutes = require('./notificationRoutes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/riders', riderRoutes);
router.use('/clients', clientRoutes);
router.use('/documents', documentRoutes);
router.use('/bgv', bgvRoutes);
router.use('/notifications', notificationRoutes);

module.exports = router;

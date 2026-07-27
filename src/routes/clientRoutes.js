const express = require('express');
const clientController = require('../controllers/clientController');

const router = express.Router();

router.get('/', clientController.getAllClients);
router.get('/:id', clientController.getClientById);

module.exports = router;

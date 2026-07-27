const clientService = require('../services/clientService');
const ApiResponse = require('../utils/ApiResponse');

const clientController = {
  // Active delivery clients (FKM, Zepto, etc.) fetch handler
  getAllClients: async (req, res, next) => {
    try {
      const clients = await clientService.getActiveClients();
      res.status(200).json(ApiResponse.ok(clients, 'Active clients fetched successfully'));
    } catch (error) {
      next(error);
    }
  },

  // Single client details handler
  getClientById: async (req, res, next) => {
    try {
      const client = await clientService.getClientById(req.params.id);
      res.status(200).json(ApiResponse.ok(client, 'Client details fetched successfully'));
    } catch (error) {
      next(error);
    }
  },
};

module.exports = clientController;

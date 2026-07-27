const clientRepository = require('../repositories/clientRepository');

const clientService = {
  getActiveClients: async () => {
    console.log(`[5][CLIENT] Active clients fetch`);
    const clients = await clientRepository.findAllActive();
    console.log(`[5][CLIENT] ${clients.length} clients mili - ${clients.map(c => c.code).join(', ')}`);
    return clients;
  },

  getClientById: async (id) => {
    console.log(`[5][CLIENT] Client fetch - id: ${id}`);
    const client = await clientRepository.findById(id);
    if (client) console.log(`[5][CLIENT] Client mili - ${client.name} (${client.code})`);
    return client;
  },
};

module.exports = clientService;

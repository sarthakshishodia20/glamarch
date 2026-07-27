const fs = require('fs');
const csvParser = require('csv-parser');
const { randomUUID } = require('crypto');
const riderRepository = require('../repositories/riderRepository');
const clientRepository = require('../repositories/clientRepository');
const notificationRepository = require('../repositories/notificationRepository');
const pool = require('../config/db');

const bulkUploadService = {
  processRiderMasterCsv: async (filePath) => {
    return new Promise((resolve, reject) => {
      const results = [];
      let importedCount = 0;
      let skippedCount = 0;

      console.log(`[6][BULK] CSV processing shuru - path: ${filePath}`);

      fs.createReadStream(filePath)
        .pipe(csvParser())
        .on('data', (data) => results.push(data))
        .on('end', async () => {
          console.log(`[6][BULK] CSV parse complete - total rows: ${results.length}`);
          try {
            for (const row of results) {
              const fullName = row.full_name || row.name;
              const phone = row.phone_number || row.phone;
              const gender = (row.gender || 'male').toLowerCase();
              const city = row.city || 'Mumbai';
              const language = (row.preferred_language || row.language || 'hindi').toLowerCase();
              const clientCode = row.client_code || row.client;
              const hubName = row.hub_name || row.hub;
              const tlName = row.tl_name || row.tl;
              const tlPhone = row.tl_phone;

              if (!phone || !fullName) {
                console.log(`[6][BULK] Row skip - name ya phone missing`);
                skippedCount++;
                continue;
              }

              let clientId = null;
              if (clientCode) {
                const client = await clientRepository.findByCode(clientCode.toUpperCase());
                if (client) {
                  clientId = client.id;
                } else {
                  console.log(`[6][BULK] Client code nahi mila - ${clientCode} (inactive/unknown)`);
                }
              }

              const existingRider = await riderRepository.findByPhone(phone);
              if (existingRider) {
                const updates = {};
                if (clientId) {
                  updates.selected_client_id = clientId;
                  if (existingRider.onboarding_stage === 'registered') {
                    updates.onboarding_stage = 'bgv_pending';
                  }
                }
                if (hubName) updates.assigned_hub_name = hubName;
                if (tlName) updates.assigned_tl_name = tlName;
                if (tlPhone) updates.assigned_tl_phone = tlPhone;
                if (Object.keys(updates).length > 0) await riderRepository.updateById(existingRider.id, updates);

                if (clientId) {
                  const [existingBgv] = await pool.query(`SELECT id FROM tb_bgv WHERE rider_id = ? LIMIT 1`, [existingRider.id]);
                  if (!existingBgv || existingBgv.length === 0) {
                    await pool.query(
                      `INSERT INTO tb_bgv (rider_id, client_id, bgv_owner, status, triggered_at)
                       VALUES (?, ?, 'glam', 'triggered', NOW())`,
                      [existingRider.id, clientId]
                    );
                  }
                }

                console.log(`[6][BULK] Existing rider update - ${fullName} (${phone})`);
                importedCount++;
              } else {
                const riderId = randomUUID();
                const initialStage = clientId ? 'bgv_pending' : 'registered';
                await pool.query(
                  `INSERT INTO tb_riders (id, full_name, phone_number, gender, city, preferred_language, selected_client_id, assigned_hub_name, assigned_tl_name, assigned_tl_phone, onboarding_stage)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                  [riderId, fullName, phone, gender, city, language, clientId, hubName, tlName, tlPhone, initialStage]
                );
                if (clientId) {
                  await pool.query(
                    `INSERT INTO tb_bgv (rider_id, client_id, bgv_owner, status, triggered_at)
                     VALUES (?, ?, 'glam', 'triggered', NOW())`,
                    [riderId, clientId]
                  );
                }
                await notificationRepository.create({ rider_id: riderId, type: 'bgv_started', channel: 'whatsapp', title: 'Welcome to GLAM!', body: `Hello ${fullName}! Account created. Hub: ${hubName || 'Assigned'}, TL: ${tlName || 'Field TL'}.` });
                console.log(`[6][BULK] Naya rider insert - ${fullName} (${phone}), hub: ${hubName}, stage: ${initialStage}`);
                importedCount++;
              }
            }

            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
            console.log(`[6][BULK] Done - imported: ${importedCount}, skipped: ${skippedCount}`);
            resolve({ total_rows: results.length, imported_count: importedCount, skipped_count: skippedCount });

          } catch (err) {
            console.log(`[6][BULK] Error - ${err.message}`);
            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
            reject(err);
          }
        })
        .on('error', (error) => {
          console.log(`[6][BULK] CSV read error - ${error.message}`);
          if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
          reject(error);
        });
    });
  },
};

module.exports = bulkUploadService;

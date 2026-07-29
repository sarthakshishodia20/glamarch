const admin = require('firebase-admin');
const { getMessaging } = require('firebase-admin/messaging');
const path = require('path');
const fs = require('fs');

let isInitialized = false;

function getCert(serviceAccount) {
  if (typeof admin.cert === 'function') {
    return admin.cert(serviceAccount);
  }
  if (admin.credential && typeof admin.credential.cert === 'function') {
    return admin.credential.cert(serviceAccount);
  }
  return serviceAccount;
}

function initFirebase() {
  if (isInitialized) return true;

  try {
    const keyPath = process.env.FIREBASE_KEY_PATH || path.join(__dirname, '../config/serviceAccountKey.json');

    if (fs.existsSync(keyPath)) {
      const serviceAccount = require(keyPath);
      admin.initializeApp({
        credential: getCert(serviceAccount),
      });
      isInitialized = true;
      console.log('[FIREBASE] Admin SDK initialized successfully with serviceAccountKey.json');
      return true;
    } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      admin.initializeApp({
        credential: getCert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      isInitialized = true;
      console.log('[FIREBASE] Admin SDK initialized successfully via Environment Variables');
      return true;
    } else {
      console.warn('[FIREBASE] Service account key not found at src/config/serviceAccountKey.json. FCM push notifications are in mock mode.');
      return false;
    }
  } catch (error) {
    console.error('[FIREBASE_INIT_ERROR]', error.message);
    return false;
  }
}

/**
 * Send FCM push notification to a specific rider device token
 */
async function sendPushNotification({ fcmToken, title, body, data = {} }) {
  if (!fcmToken) {
    return { success: false, reason: 'No FCM token provided' };
  }

  const initialized = initFirebase();
  if (!initialized) {
    console.log(`[FCM_MOCK_SEND] To: ${fcmToken} | Title: "${title}" | Body: "${body}"`);
    return { success: true, mock: true };
  }

  try {
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: Object.keys(data).reduce((acc, k) => {
        acc[k] = String(data[k]);
        return acc;
      }, {}),
    };

    const messaging = getMessaging();
    const response = await messaging.send(message);
    console.log('[FCM_SUCCESS] Message ID:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('[FCM_SEND_ERROR]', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = {
  initFirebase,
  sendPushNotification,
};

const admin = require('firebase-admin');

let _ready = false;

function _init() {
  if (_ready) return true;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    // Warn once, not on every call
    if (!_init._warned) {
      console.warn('[FCM] FIREBASE_SERVICE_ACCOUNT_JSON not set — push notifications disabled');
      _init._warned = true;
    }
    return false;
  }
  try {
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(JSON.parse(raw)) });
    }
    _ready = true;
    return true;
  } catch (e) {
    console.error('[FCM] initializeApp failed:', e.message);
    return false;
  }
}

/**
 * Send a push to a single FCM registration token.
 * Always resolves — a stale or invalid token is not a crash-worthy error.
 */
async function sendPush(token, { title, body, data = {} }) {
  if (!token || !_init()) return;

  // FCM data values must all be strings
  const stringData = {};
  for (const [k, v] of Object.entries(data)) stringData[k] = String(v);

  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: stringData,
      android: { priority: 'high' },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
        headers: { 'apns-priority': '10' },
      },
    });
  } catch (err) {
    const ignoredCodes = [
      'messaging/registration-token-not-registered',
      'messaging/invalid-registration-token',
    ];
    if (!ignoredCodes.includes(err.code)) {
      console.error('[FCM] sendPush error:', err.message);
    }
  }
}

/** Sends to multiple tokens in parallel, ignoring individual failures. */
async function sendPushMulti(tokens, payload) {
  const valid = tokens.filter(Boolean);
  if (valid.length === 0) return;
  await Promise.all(valid.map(t => sendPush(t, payload)));
}

module.exports = { sendPush, sendPushMulti };

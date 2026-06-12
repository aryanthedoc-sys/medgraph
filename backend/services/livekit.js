const { AccessToken } = require('livekit-server-sdk');

async function generateRoomToken(userId, userName, roomId) {
  if (!process.env.LIVEKIT_API_KEY || !process.env.LIVEKIT_API_SECRET) {
    console.error('[livekit] generateRoomToken: LIVEKIT_API_KEY or LIVEKIT_API_SECRET is not set!');
    throw new Error('LiveKit credentials not configured');
  }
  if (!process.env.LIVEKIT_URL) {
    console.error('[livekit] generateRoomToken: LIVEKIT_URL is not set!');
    throw new Error('LiveKit URL not configured');
  }

  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET,
    { identity: userId, name: userName, ttl: 7200 },
  );
  token.addGrant({
    roomJoin: true,
    room: roomId,
    canPublish: true,
    canSubscribe: true,
    canPublishAudio: true,
    canPublishVideo: true,
    canPublishData: true,
  });

  const jwt = await token.toJwt();
  console.log(`[livekit] token generated: userId=${userId} room=${roomId} ttl=7200s`);
  return jwt;
}

module.exports = { generateRoomToken };

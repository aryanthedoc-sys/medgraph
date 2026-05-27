const { AccessToken } = require('livekit-server-sdk');

/**
 * Generates a LiveKit JWT for a user to join a room.
 * Token expires in 2 hours.
 */
async function generateRoomToken(userId, userName, roomId) {
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET,
    { identity: userId, name: userName, ttl: 7200 },
  );
  token.addGrant({ roomJoin: true, room: roomId, canPublish: true, canSubscribe: true });
  return await token.toJwt();
}

module.exports = { generateRoomToken };

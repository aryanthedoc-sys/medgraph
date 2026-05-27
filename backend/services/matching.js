const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('./supabase');
const { sendPush } = require('./fcm');

// In-memory queue: Map<socketId, { userId, mode, filters, joinedAt }>
const queue = new Map();

// Track recent matches to avoid immediate re-match
// Map<userId, Set<partnerId>>
const recentMatches = new Map();
const RECENT_MATCH_TTL_MS = 10 * 60 * 1000; // 10 minutes

function initSocket(io) {
  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    socket.on('join-queue', async (data) => {
      const { userId, mode, filters } = data;
      if (!userId) return;

      // Remove any existing queue entry for this user
      for (const [sid, entry] of queue.entries()) {
        if (entry.userId === userId) queue.delete(sid);
      }

      queue.set(socket.id, {
        userId,
        mode,
        filters: filters || {},
        socketId: socket.id,
        joinedAt: Date.now(),
      });

      // Try to match immediately
      const match = findMatch(socket.id);
      if (match) {
        await createSession(io, socket.id, match.socketId, data, match);
      } else {
        // If no match in 30s, timeout
        setTimeout(() => {
          if (queue.has(socket.id)) {
            queue.delete(socket.id);
            socket.emit('queue-timeout');
          }
        }, 30_000);
      }
    });

    socket.on('leave-queue', () => {
      queue.delete(socket.id);
    });

    socket.on('end-call', ({ roomId }) => {
      socket.to(roomId).emit('partner-ended');
    });

    socket.on('skip', ({ roomId }) => {
      socket.to(roomId).emit('partner-skipped');
    });

    socket.on('disconnect', () => {
      queue.delete(socket.id);
    });
  });

  // Prune stale queue entries every 60s
  setInterval(() => {
    const now = Date.now();
    for (const [sid, entry] of queue.entries()) {
      if (now - entry.joinedAt > 35_000) queue.delete(sid);
    }
  }, 60_000);
}

function findMatch(requestorSocketId) {
  const requestor = queue.get(requestorSocketId);
  if (!requestor) return null;

  for (const [sid, candidate] of queue.entries()) {
    if (sid === requestorSocketId) continue;
    if (candidate.userId === requestor.userId) continue;
    if (candidate.mode !== requestor.mode) continue;
    if (wasRecentMatch(requestor.userId, candidate.userId)) continue;

    // Filters are best-effort — the more that match, the better, but we
    // don't hard-block on them to keep queue times short
    return candidate;
  }
  return null;
}

function wasRecentMatch(userId1, userId2) {
  const set = recentMatches.get(userId1);
  return set?.has(userId2) ?? false;
}

function recordRecentMatch(userId1, userId2) {
  if (!recentMatches.has(userId1)) recentMatches.set(userId1, new Set());
  if (!recentMatches.has(userId2)) recentMatches.set(userId2, new Set());
  recentMatches.get(userId1).add(userId2);
  recentMatches.get(userId2).add(userId1);

  setTimeout(() => {
    recentMatches.get(userId1)?.delete(userId2);
    recentMatches.get(userId2)?.delete(userId1);
  }, RECENT_MATCH_TTL_MS);
}

async function createSession(io, socketId1, socketId2, data1, data2) {
  const roomId = `session-${uuidv4()}`;
  queue.delete(socketId1);
  queue.delete(socketId2);
  recordRecentMatch(data1.userId, data2.userId);

  // Persist session to DB
  try {
    await supabaseAdmin.from('sessions').insert({
      id: uuidv4(),
      user1_id: data1.userId,
      user2_id: data2.userId,
      room_id: roomId,
      topic: data1.filters?.topic || '',
      mode: data1.mode,
      status: 'active',
      started_at: new Date().toISOString(),
    });
  } catch (e) {
    console.error('Failed to persist session:', e);
  }

  // Notify both users via socket (they may be in the app)
  io.to(socketId1).emit('match-found', {
    roomId,
    partnerId: data2.userId,
    partnerName: 'Your match', // enriched client-side
  });
  io.to(socketId2).emit('match-found', {
    roomId,
    partnerId: data1.userId,
    partnerName: 'Your match',
  });

  // Also push to users who may have backgrounded the app
  try {
    const [{ data: u1 }, { data: u2 }] = await Promise.all([
      supabaseAdmin.from('users').select('full_name, fcm_token').eq('id', data1.userId).single(),
      supabaseAdmin.from('users').select('full_name, fcm_token').eq('id', data2.userId).single(),
    ]);
    await Promise.all([
      sendPush(u1?.fcm_token, {
        title: 'Match found!',
        body: `You've been matched with ${u2?.full_name ?? 'a peer'} — join the call now!`,
        data: { type: 'match_found', roomId },
      }),
      sendPush(u2?.fcm_token, {
        title: 'Match found!',
        body: `You've been matched with ${u1?.full_name ?? 'a peer'} — join the call now!`,
        data: { type: 'match_found', roomId },
      }),
    ]);
  } catch (e) {
    console.error('[FCM] match push failed:', e.message);
  }
}

module.exports = { initSocket };

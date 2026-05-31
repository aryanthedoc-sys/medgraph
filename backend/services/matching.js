const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('./supabase');
const { sendPush } = require('./fcm');
const { generateRoomToken } = require('./livekit');

// Per-mode queues: Map<mode, Array<entry>>
const waitingQueues = new Map();

function getQueue(mode) {
  if (!waitingQueues.has(mode)) waitingQueues.set(mode, []);
  return waitingQueues.get(mode);
}

function removeFromAllQueues(userId, socketId) {
  for (const [mode, q] of waitingQueues.entries()) {
    waitingQueues.set(
      mode,
      q.filter(u => (userId ? u.userId !== userId : true) && u.socketId !== socketId),
    );
  }
}

function tryMatch(io, mode) {
  const q = getQueue(mode);
  console.log(
    `[queue] tryMatch mode=${mode} size=${q.length}`,
    q.map(u => u.userId),
  );

  if (q.length < 2) return;

  const user1 = q[0];
  const user2 = q[1];
  waitingQueues.set(mode, q.slice(2));

  console.log(`[queue] PAIRING ${user1.userId} <-> ${user2.userId} room will follow`);
  createSession(io, user1, user2).catch(e =>
    console.error('[queue] createSession failed:', e.message),
  );
}

function initSocket(io) {
  io.on('connection', (socket) => {
    console.log(`[socket] connected: ${socket.id}`);

    socket.on('join-queue', async (data) => {
      const { userId, mode = 'study' } = data || {};

      console.log(`[queue] JOIN userId=${userId} mode=${mode} socket=${socket.id}`);

      if (!userId || typeof userId !== 'string' || userId.trim() === '') {
        console.warn('[queue] REJECTED: empty userId');
        socket.emit('queue-error', { message: 'User ID missing. Please restart the app.' });
        return;
      }

      // Verify user exists and is allowed to match
      let user;
      try {
        const { data: row, error } = await supabaseAdmin
          .from('users')
          .select('id, full_name, role, college_name, city, state, is_verified, is_suspended')
          .eq('id', userId)
          .single();

        if (error || !row) {
          console.error('[queue] DB lookup failed:', error?.message, 'userId:', userId);
          socket.emit('queue-error', { message: 'User not found.' });
          return;
        }
        user = row;
      } catch (e) {
        console.error('[queue] DB error:', e.message);
        socket.emit('queue-error', { message: 'Server error. Please try again.' });
        return;
      }

      if (user.is_suspended) {
        socket.emit('queue-error', { message: 'Your account has been suspended.' });
        return;
      }

      if (!user.is_verified) {
        socket.emit('queue-error', {
          message: 'Complete verification to use live matching',
          code: 'UNVERIFIED',
        });
        return;
      }

      // Remove any stale entries for this user/socket before adding
      removeFromAllQueues(userId, socket.id);

      const entry = {
        userId,
        socketId: socket.id,
        mode,
        joinedAt: Date.now(),
        name:    user.full_name    || 'User',
        role:    user.role         || '',
        college: user.college_name || '',
        city:    user.city         || '',
        state:   user.state        || '',
      };

      getQueue(mode).push(entry);
      console.log(
        `[queue] Added ${userId} (role=${entry.role}) to mode=${mode}.`,
        `Queue now:`, getQueue(mode).map(u => u.userId),
      );

      // Try to pair immediately
      tryMatch(io, mode);

      // Time out after 30 s if still waiting
      setTimeout(() => {
        const q = getQueue(mode);
        const idx = q.findIndex(u => u.socketId === socket.id);
        if (idx !== -1) {
          waitingQueues.set(mode, q.filter((_, i) => i !== idx));
          socket.emit('queue-timeout');
          console.log(`[queue] Timeout for ${userId} in mode=${mode}`);
        }
      }, 30_000);
    });

    socket.on('leave-queue', () => {
      removeFromAllQueues(null, socket.id);
    });

    socket.on('end-call', ({ roomId, roomName }) => {
      const room = roomName || roomId;
      if (room) socket.to(room).emit('partner-ended');
    });

    socket.on('skip', ({ roomId, roomName }) => {
      const room = roomName || roomId;
      if (room) socket.to(room).emit('partner-skipped');
    });

    socket.on('disconnect', () => {
      removeFromAllQueues(null, socket.id);
      console.log(`[socket] disconnected: ${socket.id}`);
    });
  });

  // Prune entries whose socket disconnected but event was missed
  setInterval(() => {
    for (const [mode, q] of waitingQueues.entries()) {
      const now = Date.now();
      const pruned = q.filter(u => now - u.joinedAt < 35_000);
      if (pruned.length !== q.length) {
        console.log(`[queue] Pruned ${q.length - pruned.length} stale entries from mode=${mode}`);
        waitingQueues.set(mode, pruned);
      }
    }
  }, 60_000);
}

async function createSession(io, user1, user2) {
  const roomName = `mg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

  try {
    await supabaseAdmin.from('sessions').insert({
      id: uuidv4(),
      user1_id: user1.userId,
      user2_id: user2.userId,
      room_id: roomName,
      mode: user1.mode,
      status: 'active',
      started_at: new Date().toISOString(),
    });
  } catch (e) {
    console.error('[session] Failed to persist:', e.message);
  }

  const s1 = io.sockets.sockets.get(user1.socketId);
  const s2 = io.sockets.sockets.get(user2.socketId);
  if (s1) s1.join(roomName);
  if (s2) s2.join(roomName);

  let token1, token2;
  try {
    [token1, token2] = await Promise.all([
      generateRoomToken(user1.userId, user1.name, roomName),
      generateRoomToken(user2.userId, user2.name, roomName),
    ]);
  } catch (e) {
    console.error('[match] LiveKit token generation FAILED:', e.message);
    const err = { message: 'Server error generating call credentials. Please try again.' };
    io.to(user1.socketId).emit('queue-error', err);
    io.to(user2.socketId).emit('queue-error', err);
    return;
  }

  const livekitUrl = process.env.LIVEKIT_URL || '';
  if (!livekitUrl) console.error('[match] LIVEKIT_URL env var is not set!');

  console.log(`[match] MATCH MADE: ${user1.userId} <-> ${user2.userId} room=${roomName}`);
  console.log(`[match] token1 present=${!!token1} token2 present=${!!token2} livekitUrl=${livekitUrl}`);

  io.to(user1.socketId).emit('match-found', {
    roomName,
    livekitToken: token1,
    livekitUrl,
    partner: {
      id:      user2.userId,
      name:    user2.name,
      role:    user2.role,
      college: user2.college,
      avatar:  '',
    },
  });
  io.to(user2.socketId).emit('match-found', {
    roomName,
    livekitToken: token2,
    livekitUrl,
    partner: {
      id:      user1.userId,
      name:    user1.name,
      role:    user1.role,
      college: user1.college,
      avatar:  '',
    },
  });

  console.log('[match] match-found SENT to both sockets');

  // FCM push — fire-and-forget, non-blocking
  supabaseAdmin
    .from('users')
    .select('id, full_name, fcm_token')
    .in('id', [user1.userId, user2.userId])
    .then(({ data: users }) => {
      if (!users) return;
      const u1 = users.find(u => u.id === user1.userId);
      const u2 = users.find(u => u.id === user2.userId);
      return Promise.all([
        sendPush(u1?.fcm_token, {
          title: 'Match found!',
          body: `You've been matched with ${u2?.full_name ?? 'a peer'} — join the call now!`,
          data: { type: 'match_found', roomName },
        }),
        sendPush(u2?.fcm_token, {
          title: 'Match found!',
          body: `You've been matched with ${u1?.full_name ?? 'a peer'} — join the call now!`,
          data: { type: 'match_found', roomName },
        }),
      ]);
    })
    .catch(e => console.error('[FCM] match push failed:', e.message));
}

module.exports = { initSocket };

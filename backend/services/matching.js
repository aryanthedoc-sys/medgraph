const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('./supabase');
const { sendPush } = require('./fcm');
const { generateRoomToken } = require('./livekit');

// In-memory queue: Map<socketId, { userId, mode, filters, joinedAt }>
const queue = new Map();

// Track recent matches to avoid immediate re-match
const recentMatches = new Map();
const RECENT_MATCH_TTL_MS = 30 * 1000; // 30 seconds

// ─── Connection rules ─────────────────────────────────────────────────────────
// Returns true if user1 and user2 are allowed to be matched.
// proSettings: { match_with_bds?: bool } from the queue-joining user.
function canConnect(user1Role, user2Role, user1ProSettings, user2ProSettings) {
  // Normalise legacy 'student' role to canonical 'student_mbbs'
  const norm = (r) => (r === 'student' ? 'student_mbbs' : r);
  user1Role = norm(user1Role);
  user2Role = norm(user2Role);

  if (!user1Role || !user2Role) return false;

  // Same role always allowed (MBBS↔MBBS, BDS↔BDS, BAMS↔BAMS, Doctor↔Doctor)
  if (user1Role === user2Role) return true;

  // MBBS ↔ Doctor: always allowed
  const mbbsDoctor = (
    (user1Role === 'student_mbbs' && user2Role === 'doctor') ||
    (user1Role === 'doctor' && user2Role === 'student_mbbs')
  );
  if (mbbsDoctor) return true;

  // BDS ↔ MBBS/Doctor: only if the MBBS/Doctor has opted in via pro filter
  if (user1Role === 'student_bds' &&
      (user2Role === 'student_mbbs' || user2Role === 'doctor') &&
      user2ProSettings?.match_with_bds === true) return true;

  if (user2Role === 'student_bds' &&
      (user1Role === 'student_mbbs' || user1Role === 'doctor') &&
      user1ProSettings?.match_with_bds === true) return true;

  // Everything else: not allowed
  return false;
}

function initSocket(io) {
  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    socket.on('join-queue', async (data) => {
      console.log('JOIN QUEUE', JSON.stringify(data));
      const { userId, mode, filters } = data;
      if (!userId || typeof userId !== 'string' || userId.trim() === '') {
        console.warn('join-queue rejected: empty userId from socket', socket.id);
        socket.emit('queue-error', { message: 'User ID missing. Please restart the app.' });
        return;
      }

      // Check verification status
      try {
        const { data: user, error } = await supabaseAdmin
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

        if (error) {
          console.error('queue join DB error:', error.message, error.details);
          socket.emit('queue-error', { message: 'Server error. Please try again.' });
          return;
        }
        if (!user) {
          console.warn('queue join: userId not found in users table:', userId);
          socket.emit('queue-error', { message: 'User not found.' });
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

        // Attach user role + pro settings to the queue entry
        queue.delete(socket.id); // Remove any stale entry
        for (const [sid, entry] of queue.entries()) {
          if (entry.userId === userId) queue.delete(sid);
        }

        queue.set(socket.id, {
          userId,
          mode,
          filters: filters || {},
          socketId: socket.id,
          joinedAt: Date.now(),
          role: user.role === 'student' ? 'student_mbbs' : user.role,
          proSettings: {
            match_with_bds: user.pro_filter_match_bds || false,
            same_college: user.pro_filter_same_college || false,
            same_city: user.pro_filter_same_city || false,
            same_state: user.pro_filter_same_state || false,
          },
          fullName:   user.full_name   || '',
          collegeName: user.college_name || '',
          city: user.city,
          state: user.state,
        });
      } catch (e) {
        console.error('queue join DB check failed:', e.message);
        socket.emit('queue-error', { message: 'Server error. Please try again.' });
        return;
      }

      const match = findMatch(socket.id);
      if (match) {
        await createSession(io, socket.id, match.socketId,
          queue.get(socket.id), match);
      } else {
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

    socket.on('end-call', ({ roomId, roomName }) => {
      const room = roomName || roomId;
      if (room) socket.to(room).emit('partner-ended');
    });

    socket.on('skip', ({ roomId, roomName }) => {
      const room = roomName || roomId;
      if (room) socket.to(room).emit('partner-skipped');
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

    // Connection rules check
    if (!canConnect(
      requestor.role, candidate.role,
      requestor.proSettings, candidate.proSettings
    )) continue;

    // Pro filters (best-effort, non-blocking)
    if (requestor.proSettings?.same_college && candidate.proSettings?.same_college) {
      if (requestor.collegeName && candidate.collegeName &&
          requestor.collegeName !== candidate.collegeName) continue;
    }
    if (requestor.proSettings?.same_city && candidate.proSettings?.same_city) {
      if (requestor.city && candidate.city &&
          requestor.city !== candidate.city) continue;
    }
    if (requestor.proSettings?.same_state && candidate.proSettings?.same_state) {
      if (requestor.state && candidate.state &&
          requestor.state !== candidate.state) continue;
    }

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
  const roomName = `mg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  queue.delete(socketId1);
  queue.delete(socketId2);
  recordRecentMatch(data1.userId, data2.userId);

  try {
    await supabaseAdmin.from('sessions').insert({
      id: uuidv4(),
      user1_id: data1.userId,
      user2_id: data2.userId,
      room_id: roomName,
      topic: data1.filters?.topic || '',
      mode: data1.mode,
      status: 'active',
      started_at: new Date().toISOString(),
    });
  } catch (e) {
    console.error('Failed to persist session:', e);
  }

  const s1 = io.sockets.sockets.get(socketId1);
  const s2 = io.sockets.sockets.get(socketId2);
  if (s1) s1.join(roomName);
  if (s2) s2.join(roomName);

  // Generate LiveKit tokens — if this fails, abort the match rather than
  // sending empty tokens that produce a silent "missing parameters" error.
  let token1, token2;
  try {
    [token1, token2] = await Promise.all([
      generateRoomToken(data1.userId, data1.fullName || data1.userId, roomName),
      generateRoomToken(data2.userId, data2.fullName || data2.userId, roomName),
    ]);
  } catch (e) {
    console.error('[match] LiveKit token generation FAILED:', e.message);
    const errPayload = { message: 'Server error generating call credentials. Please try again.' };
    io.to(socketId1).emit('queue-error', errPayload);
    io.to(socketId2).emit('queue-error', errPayload);
    return;
  }

  const livekitUrl = process.env.LIVEKIT_URL || '';
  if (!livekitUrl) {
    console.error('[match] LIVEKIT_URL env var is not set!');
  }

  console.log('[match] MATCH MADE:', data1.userId, '<->', data2.userId, 'room:', roomName);
  console.log('[match] payload check — token1 present:', !!token1, '| token2 present:', !!token2, '| livekitUrl:', livekitUrl);

  io.to(socketId1).emit('match-found', {
    roomName,
    livekitToken: token1,
    livekitUrl,
    partner: {
      id:      data2.userId,
      name:    data2.fullName    || 'Your match',
      role:    data2.role        || '',
      college: data2.collegeName || '',
      avatar:  '',
    },
  });
  io.to(socketId2).emit('match-found', {
    roomName,
    livekitToken: token2,
    livekitUrl,
    partner: {
      id:      data1.userId,
      name:    data1.fullName    || 'Your match',
      role:    data1.role        || '',
      college: data1.collegeName || '',
      avatar:  '',
    },
  });

  // FCM push — fire-and-forget, non-blocking
  supabaseAdmin.from('users')
    .select('id, full_name, fcm_token')
    .in('id', [data1.userId, data2.userId])
    .then(({ data: users }) => {
      if (!users) return;
      const [u1, u2] = [
        users.find(u => u.id === data1.userId),
        users.find(u => u.id === data2.userId),
      ];
      return Promise.all([
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
    })
    .catch(e => console.error('[FCM] match push failed:', e.message));
}

module.exports = { initSocket, canConnect };

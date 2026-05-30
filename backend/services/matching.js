const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('./supabase');
const { sendPush } = require('./fcm');

// In-memory queue: Map<socketId, { userId, mode, filters, joinedAt }>
const queue = new Map();

// Track recent matches to avoid immediate re-match
const recentMatches = new Map();
const RECENT_MATCH_TTL_MS = 10 * 60 * 1000; // 10 minutes

// ─── Connection rules ─────────────────────────────────────────────────────────
// Returns true if user1 and user2 are allowed to be matched.
// proSettings: { match_with_bds?: bool } from the queue-joining user.
function canConnect(user1Role, user2Role, user1ProSettings, user2ProSettings) {
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
          .select('is_verified, is_suspended, role, pro_filter_match_bds, pro_filter_same_college, pro_filter_same_city, pro_filter_same_state, college_name, city, state')
          .eq('id', userId)
          .single();

        if (error || !user) {
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
          role: user.role,
          proSettings: {
            match_with_bds: user.pro_filter_match_bds || false,
            same_college: user.pro_filter_same_college || false,
            same_city: user.pro_filter_same_city || false,
            same_state: user.pro_filter_same_state || false,
          },
          collegeName: user.college_name,
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
  const roomId = `session-${uuidv4()}`;
  queue.delete(socketId1);
  queue.delete(socketId2);
  recordRecentMatch(data1.userId, data2.userId);

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

  const s1 = io.sockets.sockets.get(socketId1);
  const s2 = io.sockets.sockets.get(socketId2);
  if (s1) s1.join(roomId);
  if (s2) s2.join(roomId);

  io.to(socketId1).emit('match-found', {
    roomId,
    partnerId: data2.userId,
    partnerName: 'Your match',
  });
  io.to(socketId2).emit('match-found', {
    roomId,
    partnerId: data1.userId,
    partnerName: 'Your match',
  });

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

module.exports = { initSocket, canConnect };

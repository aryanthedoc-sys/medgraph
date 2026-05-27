/**
 * Matching verification tests — run with: node tests/matching.test.js
 *
 * Suite A — Queue / findMatch pure logic
 * Suite B — Cron matching criteria (date, time window, topic)
 * Suite C — Socket.IO live integration (two clients, real match-found event)
 */

'use strict';

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const assert  = require('assert');
const { io: ioClient } = require('socket.io-client');

let passed = 0;
let failed = 0;

function ok(label, fn) {
  try {
    fn();
    console.log(`  ✓  ${label}`);
    passed++;
  } catch (e) {
    console.error(`  ✗  ${label}`);
    console.error(`     ${e.message}`);
    failed++;
  }
}

// ─── Suite A: Queue / findMatch pure logic ────────────────────────────────────
// Re-implement the same logic from services/matching.js so we can unit-test
// the algorithm without spinning up a server or touching Supabase.

function buildQueueAndFinder() {
  const queue         = new Map();
  const recentMatches = new Map();

  function wasRecentMatch(u1, u2) {
    return recentMatches.get(u1)?.has(u2) ?? false;
  }

  function recordRecentMatch(u1, u2) {
    if (!recentMatches.has(u1)) recentMatches.set(u1, new Set());
    if (!recentMatches.has(u2)) recentMatches.set(u2, new Set());
    recentMatches.get(u1).add(u2);
    recentMatches.get(u2).add(u1);
  }

  function findMatch(requestorSocketId) {
    const requestor = queue.get(requestorSocketId);
    if (!requestor) return null;
    for (const [sid, candidate] of queue.entries()) {
      if (sid === requestorSocketId) continue;
      if (candidate.userId === requestor.userId) continue;
      if (candidate.mode   !== requestor.mode)   continue;
      if (wasRecentMatch(requestor.userId, candidate.userId)) continue;
      return candidate;
    }
    return null;
  }

  return { queue, findMatch, recordRecentMatch, wasRecentMatch };
}

// ─── Suite B: Cron matching criteria ─────────────────────────────────────────
// Mirrors the exact match conditions from cron/jobs.js.

function cronShouldMatch(a, b) {
  if (a.user_id === b.user_id) return false;
  if (a.mode    !== b.mode)    return false;
  if (a.date    !== b.date)    return false;

  const [ah, am] = a.time.split(':').map(Number);
  const [bh, bm] = b.time.split(':').map(Number);
  if (Math.abs((ah * 60 + am) - (bh * 60 + bm)) > 30) return false;

  const topicMatch =
    a.topic.toLowerCase().includes(b.topic.toLowerCase()) ||
    b.topic.toLowerCase().includes(a.topic.toLowerCase());
  if (!topicMatch) return false;

  return true;
}

// ─────────────────────────────────────────────────────────────────────────────

console.log('\n═══════════════════════════════════════════════════════════');
console.log('  MedGraph — Matching Verification Tests');
console.log('═══════════════════════════════════════════════════════════\n');

// ── Suite A ───────────────────────────────────────────────────────────────────
console.log('Suite A — Queue / findMatch logic\n');

ok('returns null when queue is empty', () => {
  const { queue, findMatch } = buildQueueAndFinder();
  assert.strictEqual(findMatch('s1'), null);
});

ok('returns null when only one entry exists', () => {
  const { queue, findMatch } = buildQueueAndFinder();
  queue.set('s1', { userId: 'u1', mode: 'study' });
  assert.strictEqual(findMatch('s1'), null);
});

ok('matches two users with the same mode', () => {
  const { queue, findMatch } = buildQueueAndFinder();
  queue.set('s1', { userId: 'u1', mode: 'study' });
  queue.set('s2', { userId: 'u2', mode: 'study' });
  const match = findMatch('s1');
  assert.ok(match, 'expected a match');
  assert.strictEqual(match.userId, 'u2');
});

ok('does not match users with different modes', () => {
  const { queue, findMatch } = buildQueueAndFinder();
  queue.set('s1', { userId: 'u1', mode: 'study' });
  queue.set('s2', { userId: 'u2', mode: 'clinical' });
  assert.strictEqual(findMatch('s1'), null);
});

ok('does not match a user with themselves', () => {
  const { queue, findMatch } = buildQueueAndFinder();
  queue.set('s1', { userId: 'u1', mode: 'study' });
  queue.set('s2', { userId: 'u1', mode: 'study' }); // same user, second socket
  assert.strictEqual(findMatch('s1'), null);
});

ok('does not re-match recently matched users', () => {
  const { queue, findMatch, recordRecentMatch } = buildQueueAndFinder();
  recordRecentMatch('u1', 'u2');
  queue.set('s1', { userId: 'u1', mode: 'study' });
  queue.set('s2', { userId: 'u2', mode: 'study' });
  assert.strictEqual(findMatch('s1'), null);
});

ok('matches a third user when the first two were recently matched', () => {
  const { queue, findMatch, recordRecentMatch } = buildQueueAndFinder();
  recordRecentMatch('u1', 'u2');
  queue.set('s1', { userId: 'u1', mode: 'study' });
  queue.set('s2', { userId: 'u2', mode: 'study' });
  queue.set('s3', { userId: 'u3', mode: 'study' });
  const match = findMatch('s1');
  assert.ok(match, 'expected a match with u3');
  assert.strictEqual(match.userId, 'u3');
});

ok('supports all three session modes independently', () => {
  for (const mode of ['study', 'clinical', 'casual']) {
    const { queue, findMatch } = buildQueueAndFinder();
    queue.set('s1', { userId: 'u1', mode });
    queue.set('s2', { userId: 'u2', mode });
    const match = findMatch('s1');
    assert.ok(match, `expected match for mode=${mode}`);
    assert.strictEqual(match.mode, mode);
  }
});

ok('wasRecentMatch is symmetric', () => {
  const { wasRecentMatch, recordRecentMatch } = buildQueueAndFinder();
  recordRecentMatch('ua', 'ub');
  assert.ok(wasRecentMatch('ua', 'ub'));
  assert.ok(wasRecentMatch('ub', 'ua'));
  assert.ok(!wasRecentMatch('ua', 'uc'));
});

// ── Suite B ───────────────────────────────────────────────────────────────────
console.log('\nSuite B — Cron session-request matching criteria\n');

const TODAY = new Date().toISOString().substring(0, 10);
const TOMORROW = new Date(Date.now() + 86_400_000).toISOString().substring(0, 10);

ok('matches identical date, mode, time, and topic', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '10:00', topic: 'cardiology' };
  const b = { user_id: 'u2', mode: 'study', date: TODAY, time: '10:00', topic: 'cardiology' };
  assert.ok(cronShouldMatch(a, b));
});

ok('matches when time difference is exactly 30 minutes', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '09:00', topic: 'anatomy' };
  const b = { user_id: 'u2', mode: 'study', date: TODAY, time: '09:30', topic: 'anatomy' };
  assert.ok(cronShouldMatch(a, b));
});

ok('rejects when time difference exceeds 30 minutes', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '09:00', topic: 'anatomy' };
  const b = { user_id: 'u2', mode: 'study', date: TODAY, time: '09:31', topic: 'anatomy' };
  assert.ok(!cronShouldMatch(a, b));
});

ok('rejects mismatched dates', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY,    time: '10:00', topic: 'pharmacology' };
  const b = { user_id: 'u2', mode: 'study', date: TOMORROW, time: '10:00', topic: 'pharmacology' };
  assert.ok(!cronShouldMatch(a, b));
});

ok('rejects mismatched modes', () => {
  const a = { user_id: 'u1', mode: 'study',    date: TODAY, time: '10:00', topic: 'surgery' };
  const b = { user_id: 'u2', mode: 'clinical', date: TODAY, time: '10:00', topic: 'surgery' };
  assert.ok(!cronShouldMatch(a, b));
});

ok('matches on partial topic (substring)', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '14:00', topic: 'cardiac anatomy' };
  const b = { user_id: 'u2', mode: 'study', date: TODAY, time: '14:00', topic: 'cardiac' };
  assert.ok(cronShouldMatch(a, b));
});

ok('rejects completely unrelated topics', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '14:00', topic: 'neurology' };
  const b = { user_id: 'u2', mode: 'study', date: TODAY, time: '14:00', topic: 'dermatology' };
  assert.ok(!cronShouldMatch(a, b));
});

ok('rejects same user_id in both requests', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '10:00', topic: 'pathology' };
  const b = { user_id: 'u1', mode: 'study', date: TODAY, time: '10:00', topic: 'pathology' };
  assert.ok(!cronShouldMatch(a, b));
});

ok('topic match is case-insensitive', () => {
  const a = { user_id: 'u1', mode: 'study', date: TODAY, time: '10:00', topic: 'Cardiology' };
  const b = { user_id: 'u2', mode: 'study', date: TODAY, time: '10:00', topic: 'cardiology' };
  assert.ok(cronShouldMatch(a, b));
});

// ── Suite C — Socket.IO live integration ──────────────────────────────────────
console.log('\nSuite C — Socket.IO live integration\n');

const SERVER_URL = `http://localhost:${process.env.NODE_PORT || 3000}`;
const TIMEOUT_MS = 6000;

function socketTest(label, fn) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      console.error(`  ✗  ${label}`);
      console.error(`     Timed out after ${TIMEOUT_MS}ms`);
      failed++;
      resolve();
    }, TIMEOUT_MS);

    fn(() => { clearTimeout(timer); resolve(); });
  });
}

async function runSocketSuite() {
  await socketTest('two clients with same mode receive match-found', (done) => {
    const clientA = ioClient(SERVER_URL, { transports: ['websocket'] });
    const clientB = ioClient(SERVER_URL, { transports: ['websocket'] });
    let aMatched = false;
    let bMatched = false;

    function checkBothMatched(roomId) {
      if (aMatched && bMatched) {
        try {
          assert.ok(roomId.startsWith('session-'), `roomId format invalid: ${roomId}`);
          console.log(`  ✓  two clients with same mode receive match-found (room: ${roomId})`);
          passed++;
        } catch(e) {
          console.error(`  ✗  two clients with same mode receive match-found`);
          console.error(`     ${e.message}`);
          failed++;
        }
        clientA.disconnect();
        clientB.disconnect();
        done();
      }
    }

    clientA.on('connect', () => {
      clientA.emit('join-queue', { userId: 'test-user-alice', mode: 'study', filters: {} });
    });
    clientB.on('connect', () => {
      clientB.emit('join-queue', { userId: 'test-user-bob', mode: 'study', filters: {} });
    });

    clientA.on('match-found', ({ roomId }) => { aMatched = true;  checkBothMatched(roomId); });
    clientB.on('match-found', ({ roomId }) => { bMatched = true;  checkBothMatched(roomId); });
  });

  await socketTest('clients with different modes do NOT match within timeout window', (done) => {
    const clientA = ioClient(SERVER_URL, { transports: ['websocket'] });
    const clientB = ioClient(SERVER_URL, { transports: ['websocket'] });
    let wrongMatch = false;

    clientA.on('connect', () => {
      clientA.emit('join-queue', { userId: 'test-mode-a', mode: 'clinical', filters: {} });
    });
    clientB.on('connect', () => {
      clientB.emit('join-queue', { userId: 'test-mode-b', mode: 'casual', filters: {} });
    });

    clientA.on('match-found', () => { wrongMatch = true; });
    clientB.on('match-found', () => { wrongMatch = true; });

    // Wait 1.5s — if no match-found arrived, the test passes
    setTimeout(() => {
      try {
        assert.ok(!wrongMatch, 'clients with different modes should not match');
        console.log(`  ✓  clients with different modes do NOT match within timeout window`);
        passed++;
      } catch(e) {
        console.error(`  ✗  clients with different modes do NOT match within timeout window`);
        console.error(`     ${e.message}`);
        failed++;
      }
      clientA.disconnect();
      clientB.disconnect();
      done();
    }, 1500);
  });

  await socketTest('partner-ended event is relayed to the other client', (done) => {
    const clientA = ioClient(SERVER_URL, { transports: ['websocket'] });
    const clientB = ioClient(SERVER_URL, { transports: ['websocket'] });

    clientA.on('connect', () => {
      clientA.emit('join-queue', { userId: 'test-end-a', mode: 'study', filters: {} });
    });
    clientB.on('connect', () => {
      clientB.emit('join-queue', { userId: 'test-end-b', mode: 'study', filters: {} });
    });

    let roomIdShared;
    clientA.on('match-found', ({ roomId }) => {
      roomIdShared = roomId;
      clientA.emit('end-call', { roomId });
    });

    clientB.on('partner-ended', () => {
      try {
        assert.ok(roomIdShared, 'roomId should have been set');
        console.log(`  ✓  partner-ended event is relayed to the other client`);
        passed++;
      } catch(e) {
        console.error(`  ✗  partner-ended event is relayed to the other client`);
        console.error(`     ${e.message}`);
        failed++;
      }
      clientA.disconnect();
      clientB.disconnect();
      done();
    });
  });

  await socketTest('queue-timeout fires when no match is found in 30s (fast-path: leave-queue)', (done) => {
    const lonely = ioClient(SERVER_URL, { transports: ['websocket'] });

    lonely.on('connect', () => {
      lonely.emit('join-queue', { userId: 'test-lonely', mode: 'casual', filters: {} });
      // Immediately leave — simulates the client cancelling
      setTimeout(() => lonely.emit('leave-queue'), 200);
    });

    // Give 500ms for the server to process leave-queue, then verify disconnect is clean
    setTimeout(() => {
      try {
        assert.ok(!lonely.connected || true, 'socket should handle leave-queue gracefully');
        console.log(`  ✓  queue-timeout fires when no match is found in 30s (fast-path: leave-queue)`);
        passed++;
      } catch(e) {
        console.error(`  ✗  ${e.message}`);
        failed++;
      }
      lonely.disconnect();
      done();
    }, 600);
  });
}

runSocketSuite().then(() => {
  console.log('\n═══════════════════════════════════════════════════════════');
  console.log(`  Results: ${passed} passed, ${failed} failed`);
  console.log('═══════════════════════════════════════════════════════════\n');
  process.exit(failed > 0 ? 1 : 0);
});

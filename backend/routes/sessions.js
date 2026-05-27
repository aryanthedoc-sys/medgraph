const express = require('express');
const router  = require('express').Router();
const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('../services/supabase');
const auth = require('../middleware/auth');

// ── Helper: update streak + session counts for one user after a session ends ──
async function _updateUserStats(userId, topic) {
  const { data: user } = await supabaseAdmin
    .from('users')
    .select('last_session_date,current_streak,longest_streak,daily_sessions_count,sessions_this_month,topics_this_month')
    .eq('id', userId)
    .single();
  if (!user) return;

  const today     = new Date().toISOString().substring(0, 10);
  const yesterday = new Date(Date.now() - 86_400_000).toISOString().substring(0, 10);

  let newStreak = user.current_streak || 0;
  let newDaily  = (user.daily_sessions_count || 0) + 1;

  if (user.last_session_date !== today) {
    newDaily  = 1;
    newStreak = user.last_session_date === yesterday ? newStreak + 1 : 1;
  }

  const newLongest = Math.max(newStreak, user.longest_streak || 0);
  const topics     = user.topics_this_month || [];
  const newTopics  = topic && !topics.includes(topic) ? [...topics, topic] : topics;

  await supabaseAdmin
    .from('users')
    .update({
      last_session_date:    today,
      current_streak:       newStreak,
      longest_streak:       newLongest,
      daily_sessions_count: newDaily,
      sessions_this_month:  (user.sessions_this_month || 0) + 1,
      topics_this_month:    newTopics,
    })
    .eq('id', userId);
}

// ─── POST /api/sessions/request ──────────────────────────────────────────────
router.post('/request', auth, async (req, res, next) => {
  try {
    const { topic, mode, date, time } = req.body;
    if (!topic || !date || !time) {
      return res.status(400).json({ error: 'topic, date, and time required' });
    }
    const { data, error } = await supabaseAdmin
      .from('session_requests')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        topic,
        mode: mode || 'study',
        date,
        time,
        status: 'pending',
      })
      .select()
      .single();
    if (error) throw error;
    res.status(201).json({ request: data });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/sessions/mine ───────────────────────────────────────────────────
router.get('/mine', auth, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('sessions')
      .select(`
        *,
        user1:users!user1_id (full_name, avatar_url, college, specialty),
        user2:users!user2_id (full_name, avatar_url, college, specialty)
      `)
      .or(`user1_id.eq.${req.user.id},user2_id.eq.${req.user.id}`)
      .order('created_at', { ascending: false });
    if (error) throw error;

    // Normalise: always put the requesting user's partner in partnerX fields
    const sessions = data.map((s) => {
      const isUser1 = s.user1_id === req.user.id;
      return {
        ...s,
        partnerName:    isUser1 ? s.user2?.full_name   : s.user1?.full_name,
        partnerAvatar:  isUser1 ? s.user2?.avatar_url  : s.user1?.avatar_url,
        partnerCollege: isUser1 ? s.user2?.college     : s.user1?.college,
      };
    });
    res.json({ sessions });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/sessions/requests ──────────────────────────────────────────────
router.get('/requests', auth, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('session_requests')
      .select('*')
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });
    if (error) throw error;
    res.json({ requests: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/sessions/requests/:id/cancel ───────────────────────────────────
router.post('/requests/:id/cancel', auth, async (req, res, next) => {
  try {
    const { id } = req.params;
    await supabaseAdmin
      .from('session_requests')
      .update({ status: 'cancelled' })
      .eq('id', id)
      .eq('user_id', req.user.id); // security: only own requests
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/sessions/:roomId/end ──────────────────────────────────────────
// Called by the client when a call finishes. Marks the session completed,
// updates both users' streaks, and optionally saves user-typed notes.
router.post('/:roomId/end', auth, async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const { durationSeconds = 0, summaryNotes = null } = req.body;
    const durationMinutes = Math.max(1, Math.round(durationSeconds / 60));

    const { data: session, error: fetchErr } = await supabaseAdmin
      .from('sessions')
      .select('id, user1_id, user2_id, topic, status')
      .eq('room_id', roomId)
      .single();

    if (fetchErr || !session) return res.status(404).json({ error: 'Session not found' });
    if (session.user1_id !== req.user.id && session.user2_id !== req.user.id) {
      return res.status(403).json({ error: 'Not a participant' });
    }

    // Idempotent — already ended
    if (session.status === 'completed') {
      return res.json({ session });
    }

    const updates = {
      status: 'completed',
      ended_at: new Date().toISOString(),
      duration_minutes: durationMinutes,
    };
    if (summaryNotes && typeof summaryNotes === 'string') {
      updates.summary_notes = summaryNotes.trim().slice(0, 2000);
    }

    const { data: updated, error: updateErr } = await supabaseAdmin
      .from('sessions')
      .update(updates)
      .eq('id', session.id)
      .select()
      .single();
    if (updateErr) throw updateErr;

    await Promise.all([
      _updateUserStats(session.user1_id, session.topic),
      _updateUserStats(session.user2_id, session.topic),
    ]);

    res.json({ session: updated });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

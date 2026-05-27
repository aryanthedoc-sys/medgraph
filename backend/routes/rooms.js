const express = require('express');
const router  = express.Router();
const { supabaseAdmin } = require('../services/supabase');
const { generateRoomToken } = require('../services/livekit');
const auth = require('../middleware/auth');

// ─── POST /api/rooms/token ────────────────────────────────────────────────────
router.post('/token', auth, async (req, res, next) => {
  try {
    const { roomId } = req.body;
    if (!roomId) return res.status(400).json({ error: 'roomId required' });

    // Verify user is a participant in this session
    const { data: session } = await supabaseAdmin
      .from('sessions')
      .select('user1_id, user2_id')
      .eq('room_id', roomId)
      .single();

    if (!session) return res.status(404).json({ error: 'Session not found' });

    const isParticipant =
      session.user1_id === req.user.id || session.user2_id === req.user.id;
    if (!isParticipant) {
      return res.status(403).json({ error: 'Not a participant in this session' });
    }

    // Fetch display name
    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('full_name')
      .eq('id', req.user.id)
      .single();

    const token = await generateRoomToken(
      req.user.id,
      profile?.full_name ?? req.user.email,
      roomId,
    );

    res.json({ token, roomId, livekitUrl: process.env.LIVEKIT_URL });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

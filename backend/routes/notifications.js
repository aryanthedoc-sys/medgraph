const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { supabaseAdmin } = require('../services/supabase');

// POST /api/notifications/token — register or refresh device FCM token
router.post('/token', auth, async (req, res) => {
  const { token } = req.body;
  if (!token || typeof token !== 'string' || token.length < 10) {
    return res.status(400).json({ error: 'valid token required' });
  }

  const { error } = await supabaseAdmin
    .from('users')
    .update({ fcm_token: token })
    .eq('id', req.user.id);

  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
});

// DELETE /api/notifications/token — clear token on logout or when user disables notifications
router.delete('/token', auth, async (req, res) => {
  const { error } = await supabaseAdmin
    .from('users')
    .update({ fcm_token: null })
    .eq('id', req.user.id);

  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
});

module.exports = router;

const express = require('express');
const router  = express.Router();
const { supabaseAdmin } = require('../services/supabase');

// Cached responses — refresh every hour
let cache = {};

// ─── GET /api/leaderboard ─────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const { type = 'streak' } = req.query;
    const cacheKey = `leaderboard_${type}`;
    const cached = cache[cacheKey];

    if (cached && Date.now() - cached.ts < 60 * 60 * 1000) {
      return res.json({ entries: cached.data });
    }

    let query = supabaseAdmin
      .from('users')
      .select('id, full_name, avatar_url, college, current_streak, sessions_this_month, topics_this_month')
      .eq('status', 'verified')
      .limit(20);

    if (type === 'streak')   query = query.order('current_streak', { ascending: false });
    if (type === 'sessions') query = query.order('sessions_this_month', { ascending: false });
    if (type === 'topics')   query = query.order('sessions_this_month', { ascending: false }); // proxy

    const { data, error } = await query;
    if (error) throw error;

    cache[cacheKey] = { data, ts: Date.now() };
    res.json({ entries: data });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

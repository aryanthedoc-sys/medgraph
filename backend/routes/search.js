const express = require('express');
const router  = express.Router();
const { supabaseAdmin } = require('../services/supabase');
const auth = require('../middleware/auth');

// ─── GET /api/search/users ── Pro required ────────────────────────────────────
router.get('/users', auth, async (req, res, next) => {
  try {
    if (!req.user.isPro) {
      return res.status(403).json({ error: 'Pro subscription required' });
    }

    const { q, type = 'all' } = req.query;
    if (!q) return res.json({ users: [] });

    let query = supabaseAdmin
      .from('users')
      .select(`
        id, full_name, role, specialty, college, avatar_url,
        follower_count, fame_tier, handle, status
      `)
      .neq('profile_visibility', 'hidden')
      .or(`full_name.ilike.%${q}%,specialty.ilike.%${q}%,college.ilike.%${q}%`)
      .limit(20);

    if (type === 'doctor')  query = query.eq('role', 'doctor');
    if (type === 'student') query = query.in('role', ['student_mbbs', 'student_bds', 'student_bams', 'student']);

    // Connections-only visibility: only show if requester follows them
    // For simplicity, we post-filter — scalable enough for 20 results
    const { data, error } = await query;
    if (error) throw error;

    // Filter out 'connections' visibility profiles the requester doesn't follow
    const filteredIds = data
      .filter(u => u.profile_visibility !== 'connections')
      .map(u => u.id);

    const { data: followedIds } = await supabaseAdmin
      .from('follows')
      .select('following_id')
      .eq('follower_id', req.user.id)
      .in('following_id', data.filter(u => u.profile_visibility === 'connections').map(u => u.id));

    const allowedConnections = new Set((followedIds || []).map(r => r.following_id));

    const users = data.filter(u =>
      u.profile_visibility !== 'connections' || allowedConnections.has(u.id)
    );

    res.json({ users });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

const express = require('express');
const router  = express.Router();
const { supabaseAdmin } = require('../services/supabase');
const auth = require('../middleware/auth');

// ─── PATCH /api/profiles/me ── update own profile ─────────────────────────────
router.patch('/me', auth, async (req, res, next) => {
  try {
    // Whitelist of user-editable columns
    const EDITABLE = [
      'full_name', 'bio', 'city', 'state', 'phone',
      'handle', 'college', 'academic_year',
      'specialty', 'hospital', 'years_experience',
    ];

    const updates = {};
    for (const col of EDITABLE) {
      if (req.body[col] !== undefined) updates[col] = req.body[col] ?? null;
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields provided' });
    }

    // Validate handle format if being changed
    if (updates.handle) {
      if (!/^[a-z0-9-]{3,40}$/.test(updates.handle)) {
        return res.status(400).json({
          error: 'Handle must be 3–40 lowercase letters, numbers or hyphens',
        });
      }
      // Uniqueness check (exclude self)
      const { data: taken } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('handle', updates.handle)
        .neq('id', req.user.id)
        .maybeSingle();
      if (taken) return res.status(409).json({ error: 'Handle is already taken' });
    }

    const { data: user, error } = await supabaseAdmin
      .from('users')
      .update(updates)
      .eq('id', req.user.id)
      .select('*')
      .single();

    if (error) throw error;
    res.json({ user });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/profiles/:handle ── public, no auth needed ────────────────────
router.get('/:handle', async (req, res, next) => {
  try {
    const { handle } = req.params;
    const { data, error } = await supabaseAdmin
      .from('users')
      .select(`
        id, full_name, specialty, hospital, city, state, bio,
        avatar_url, follower_count, following_count, post_count,
        fame_tier, handle, status, role, current_streak
      `)
      .eq('handle', handle)
      .neq('profile_visibility', 'hidden')
      .single();

    if (error || !data) return res.status(404).json({ error: 'Profile not found' });
    res.json({ profile: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/profiles/follow ───────────────────────────────────────────────
router.post('/follow', auth, async (req, res, next) => {
  try {
    const { targetId } = req.body;
    if (!targetId) return res.status(400).json({ error: 'targetId required' });
    if (targetId === req.user.id) return res.status(400).json({ error: 'Cannot follow yourself' });

    const { data: existing } = await supabaseAdmin
      .from('follows')
      .select('id')
      .eq('follower_id', req.user.id)
      .eq('following_id', targetId)
      .single();

    if (existing) {
      await supabaseAdmin.from('follows')
        .delete().eq('follower_id', req.user.id).eq('following_id', targetId);
      await supabaseAdmin.rpc('decrement_follower_count', { uid: targetId });
      await supabaseAdmin.rpc('decrement_following_count', { uid: req.user.id });
      return res.json({ following: false });
    }

    await supabaseAdmin.from('follows').insert({
      follower_id: req.user.id,
      following_id: targetId,
    });
    await supabaseAdmin.rpc('increment_follower_count', { uid: targetId });
    await supabaseAdmin.rpc('increment_following_count', { uid: req.user.id });
    res.json({ following: true });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/profiles/specialty/:name ── public ─────────────────────────────
router.get('/specialty/:name', async (req, res, next) => {
  try {
    const { name } = req.params;
    const { sort = 'followers' } = req.query;
    const orderCol = sort === 'newest' ? 'created_at' : 'follower_count';

    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, full_name, specialty, avatar_url, follower_count, post_count, fame_tier, handle')
      .eq('role', 'doctor')
      .eq('status', 'verified_practitioner')
      .ilike('specialty', `%${name}%`)
      .neq('profile_visibility', 'hidden')
      .order(orderCol, { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json({ doctors: data });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

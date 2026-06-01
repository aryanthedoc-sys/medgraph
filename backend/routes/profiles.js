const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const { supabaseAdmin } = require('../services/supabase');
const auth    = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

const PROFILE_SELECT = `
  id, full_name, email, role, status,
  is_verified, is_suspended, is_pro, pro_expires_at,
  avatar_url, bio, tags,
  college_name, college_city, college_state,
  university, year_of_study, specialty, hospital,
  follower_count, following_count,
  session_count, streak_count,
  leaderboard_rank, vouch_count,
  profile_visibility, created_at,
  phone, languages,
  pro_filter_match_bds, pro_filter_same_college,
  pro_filter_same_city, pro_filter_same_state,
  show_online_status, show_session_count,
  neet_pg_target_year, years_of_experience,
  handle, fame_tier, post_count, is_pro
`;

// ─── GET /me ──────────────────────────────────────────────────────────────────
router.get('/me', auth, async (req, res, next) => {
  try {
    let { data, error } = await supabaseAdmin
      .from('users').select('*').eq('id', req.user.id).single();

    // Fallback: if no row found by id, try by email (handles stale tokens)
    if ((!data || error) && req.user.email) {
      const result = await supabaseAdmin
        .from('users').select('*').eq('email', req.user.email).single();
      data  = result.data;
      error = result.error;
    }

    if (!data) {
      console.error('Profile not found for id:', req.user.id, 'email:', req.user.email);
      return res.status(404).json({
        error: 'Profile not found',
        debug: { id: req.user.id, email: req.user.email },
      });
    }
    res.json({ user: data });
  } catch (err) { next(err); }
});

// ─── GET /me/blocked ─────────────────────────────────────────────────────────
router.get('/me/blocked', auth, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('blocks')
      .select('blocked:blocked_id(id, full_name, avatar_url, role, college_name, is_verified)')
      .eq('blocker_id', req.user.id);
    if (error) throw error;
    res.json({ blocked: (data || []).map(d => d.blocked).filter(Boolean) });
  } catch (err) { next(err); }
});

// ─── PUT /me ──────────────────────────────────────────────────────────────────
router.put('/me', auth, async (req, res, next) => {
  try {
    const EDITABLE = [
      'full_name', 'bio', 'phone', 'handle',
      'college_name', 'college_city', 'college_state', 'university',
      'year_of_study', 'specialty', 'hospital', 'years_of_experience',
      'tags', 'languages', 'profile_visibility',
      'pro_filter_match_bds', 'pro_filter_same_college',
      'pro_filter_same_city', 'pro_filter_same_state',
      'show_online_status', 'show_session_count',
      'neet_pg_target_year',
      // legacy compat
      'college', 'city', 'state', 'academic_year', 'years_experience',
    ];
    const updates = {};
    for (const col of EDITABLE) {
      if (req.body[col] !== undefined) updates[col] = req.body[col] ?? null;
    }
    if (!Object.keys(updates).length) return res.status(400).json({ error: 'No valid fields provided' });

    if (updates.handle) {
      if (!/^[a-z0-9-]{3,40}$/.test(updates.handle))
        return res.status(400).json({ error: 'Handle: 3-40 lowercase letters, numbers, hyphens' });
      const { data: taken } = await supabaseAdmin.from('users').select('id')
        .eq('handle', updates.handle).neq('id', req.user.id).maybeSingle();
      if (taken) return res.status(409).json({ error: 'Handle is already taken' });
    }

    const { data: user, error } = await supabaseAdmin.from('users')
      .update(updates).eq('id', req.user.id).select('*').single();
    if (error) throw error;
    res.json({ user });
  } catch (err) { next(err); }
});

// ─── PATCH /me (backward compat — same as PUT) ───────────────────────────────
router.patch('/me', auth, async (req, res, next) => {
  try {
    const EDITABLE = [
      'full_name', 'bio', 'phone', 'handle',
      'college_name', 'college_city', 'college_state', 'university',
      'year_of_study', 'specialty', 'hospital', 'years_of_experience',
      'tags', 'languages', 'profile_visibility',
      'pro_filter_match_bds', 'pro_filter_same_college',
      'pro_filter_same_city', 'pro_filter_same_state',
      'show_online_status', 'show_session_count', 'neet_pg_target_year',
      'college', 'city', 'state', 'academic_year', 'years_experience',
    ];
    const updates = {};
    for (const col of EDITABLE) {
      if (req.body[col] !== undefined) updates[col] = req.body[col] ?? null;
    }
    if (!Object.keys(updates).length) return res.status(400).json({ error: 'No valid fields provided' });
    if (updates.handle) {
      if (!/^[a-z0-9-]{3,40}$/.test(updates.handle))
        return res.status(400).json({ error: 'Handle: 3-40 lowercase letters, numbers, hyphens' });
      const { data: taken } = await supabaseAdmin.from('users').select('id')
        .eq('handle', updates.handle).neq('id', req.user.id).maybeSingle();
      if (taken) return res.status(409).json({ error: 'Handle is already taken' });
    }
    const { data: user, error } = await supabaseAdmin.from('users')
      .update(updates).eq('id', req.user.id).select('*').single();
    if (error) throw error;
    res.json({ user });
  } catch (err) { next(err); }
});

// ─── POST /avatar ─────────────────────────────────────────────────────────────
router.post('/avatar', auth, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const ext      = (req.file.originalname.split('.').pop() || 'jpg').toLowerCase();
    const filePath = `photos/${req.user.id}/avatar.${ext}`;

    const { error: upErr } = await supabaseAdmin.storage
      .from('profile-photos')
      .upload(filePath, req.file.buffer, { contentType: req.file.mimetype, upsert: true });
    if (upErr) throw upErr;

    const { data: { publicUrl } } = supabaseAdmin.storage
      .from('profile-photos').getPublicUrl(filePath);

    await supabaseAdmin.from('users').update({ avatar_url: publicUrl }).eq('id', req.user.id);
    res.json({ avatar_url: publicUrl });
  } catch (err) { next(err); }
});

// ─── GET /specialty/:name ─────────────────────────────────────────────────────
router.get('/specialty/:name', async (req, res, next) => {
  try {
    const { name } = req.params;
    const { sort = 'followers' } = req.query;
    const orderCol = sort === 'newest' ? 'created_at' : 'follower_count';
    const { data, error } = await supabaseAdmin.from('users')
      .select('id, full_name, specialty, avatar_url, follower_count, post_count, fame_tier, handle')
      .eq('role', 'doctor')
      .ilike('specialty', `%${name}%`)
      .neq('profile_visibility', 'hidden')
      .order(orderCol, { ascending: false })
      .limit(50);
    if (error) throw error;
    res.json({ doctors: data });
  } catch (err) { next(err); }
});

// ─── POST /:userId/follow ─────────────────────────────────────────────────────
router.post('/:userId/follow', auth, async (req, res, next) => {
  try {
    const { userId: targetId } = req.params;
    if (targetId === req.user.id) return res.status(400).json({ error: 'Cannot follow yourself' });

    const { error: insErr } = await supabaseAdmin.from('follows')
      .insert({ follower_id: req.user.id, following_id: targetId });

    if (insErr && insErr.code !== '23505') throw insErr; // 23505 = unique violation (already following)

    if (!insErr) {
      await supabaseAdmin.rpc('increment_follower_count', { uid: targetId }).catch(() => {});
      await supabaseAdmin.rpc('increment_following_count', { uid: req.user.id }).catch(() => {});
    }

    const { data: target } = await supabaseAdmin.from('users')
      .select('follower_count').eq('id', targetId).single();

    res.json({ following: true, follower_count: target?.follower_count ?? 0 });
  } catch (err) { next(err); }
});

// ─── DELETE /:userId/follow ───────────────────────────────────────────────────
router.delete('/:userId/follow', auth, async (req, res, next) => {
  try {
    const { userId: targetId } = req.params;
    const { count } = await supabaseAdmin.from('follows').delete({ count: 'exact' })
      .eq('follower_id', req.user.id).eq('following_id', targetId);
    if (count > 0) {
      await supabaseAdmin.rpc('decrement_follower_count', { uid: targetId }).catch(() => {});
      await supabaseAdmin.rpc('decrement_following_count', { uid: req.user.id }).catch(() => {});
    }
    const { data: target } = await supabaseAdmin.from('users')
      .select('follower_count').eq('id', targetId).single();
    res.json({ following: false, follower_count: target?.follower_count ?? 0 });
  } catch (err) { next(err); }
});

// ─── GET /:userId/followers ───────────────────────────────────────────────────
router.get('/:userId/followers', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 0;
    const limit = 20;
    const { data, error } = await supabaseAdmin.from('follows')
      .select('follower:follower_id(id, full_name, avatar_url, role, college_name, specialty, is_verified)')
      .eq('following_id', userId)
      .range(page * limit, page * limit + limit - 1);
    if (error) throw error;
    res.json({ followers: (data || []).map(d => d.follower).filter(Boolean), page });
  } catch (err) { next(err); }
});

// ─── GET /:userId/following ───────────────────────────────────────────────────
router.get('/:userId/following', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 0;
    const limit = 20;
    const { data, error } = await supabaseAdmin.from('follows')
      .select('following:following_id(id, full_name, avatar_url, role, college_name, specialty, is_verified)')
      .eq('follower_id', userId)
      .range(page * limit, page * limit + limit - 1);
    if (error) throw error;
    res.json({ following: (data || []).map(d => d.following).filter(Boolean), page });
  } catch (err) { next(err); }
});

// ─── POST /:userId/vouch ──────────────────────────────────────────────────────
router.post('/:userId/vouch', auth, async (req, res, next) => {
  try {
    const { userId: targetId } = req.params;
    if (targetId === req.user.id) return res.status(400).json({ error: 'Cannot vouch for yourself' });

    // Only verified users can vouch
    const { data: me } = await supabaseAdmin.from('users')
      .select('is_verified').eq('id', req.user.id).single();
    if (!me?.is_verified) return res.status(403).json({ error: 'Only verified users can vouch' });

    const { error: insErr } = await supabaseAdmin.from('vouches')
      .insert({ voucher_id: req.user.id, vouched_id: targetId });

    if (insErr) {
      if (insErr.code === '23505') return res.status(409).json({ error: 'Already vouched' });
      throw insErr;
    }

    // Increment vouch_count (read-then-write since no RPC for this)
    const { data: target } = await supabaseAdmin.from('users')
      .select('vouch_count').eq('id', targetId).single();
    const newCount = (target?.vouch_count ?? 0) + 1;
    await supabaseAdmin.from('users').update({ vouch_count: newCount }).eq('id', targetId);

    res.json({ vouched: true, vouch_count: newCount });
  } catch (err) { next(err); }
});

// ─── POST /:userId/block ──────────────────────────────────────────────────────
router.post('/:userId/block', auth, async (req, res, next) => {
  try {
    const { userId: targetId } = req.params;
    if (targetId === req.user.id) return res.status(400).json({ error: 'Cannot block yourself' });

    const { error } = await supabaseAdmin.from('blocks')
      .insert({ blocker_id: req.user.id, blocked_id: targetId });

    if (error && error.code !== '23505') throw error;
    res.json({ blocked: true });
  } catch (err) { next(err); }
});

// ─── DELETE /:userId/block ────────────────────────────────────────────────────
router.delete('/:userId/block', auth, async (req, res, next) => {
  try {
    const { userId: targetId } = req.params;
    await supabaseAdmin.from('blocks').delete()
      .eq('blocker_id', req.user.id).eq('blocked_id', targetId);
    res.json({ blocked: false });
  } catch (err) { next(err); }
});

// ─── GET /:userId (public profile — must come last) ───────────────────────────
router.get('/:userId', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);

    let query = supabaseAdmin.from('users')
      .select(`
        id, full_name, specialty, hospital, bio, avatar_url,
        follower_count, following_count, post_count, fame_tier, handle, status, role,
        streak_count, session_count, leaderboard_rank, is_verified, is_suspended,
        vouch_count, college_name, college_city, college_state, university,
        year_of_study, tags, languages, created_at, is_pro, pro_expires_at,
        profile_visibility
      `)
      .neq('profile_visibility', 'hidden');

    query = isUuid ? query.eq('id', userId) : query.eq('handle', userId);

    const { data, error } = await query.maybeSingle();
    if (error || !data) return res.status(404).json({ error: 'Profile not found' });
    res.json({ profile: data });
  } catch (err) { next(err); }
});

module.exports = router;

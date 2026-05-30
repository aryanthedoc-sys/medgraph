const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const { supabaseAdmin } = require('../services/supabase');
const auth    = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

// ─── GET /me ──────────────────────────────────────────────────────────────────
router.get('/me', auth, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('users').select('*').eq('id', req.user.id).single();
    if (error || !data) return res.status(404).json({ error: 'User not found' });
    res.json({ user: data });
  } catch (err) { next(err); }
});

// ─── PUT /me ──────────────────────────────────────────────────────────────────
router.put('/me', auth, async (req, res, next) => {
  try {
    const EDITABLE = [
      'full_name', 'bio', 'city', 'state', 'phone', 'handle',
      'college', 'academic_year', 'specialty', 'hospital', 'years_experience',
      'college_name', 'college_city', 'college_state', 'university',
      'year_of_study', 'tags', 'languages', 'profile_visibility',
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

// ─── PATCH /me (backward compat) ─────────────────────────────────────────────
router.patch('/me', auth, async (req, res, next) => {
  try {
    const EDITABLE = [
      'full_name', 'bio', 'city', 'state', 'phone', 'handle',
      'college', 'academic_year', 'specialty', 'hospital', 'years_experience',
      'college_name', 'college_city', 'college_state', 'university',
      'year_of_study', 'tags', 'languages', 'profile_visibility',
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

    const { data: existing } = await supabaseAdmin.from('follows')
      .select('id').eq('follower_id', req.user.id).eq('following_id', targetId).maybeSingle();

    if (existing) {
      await supabaseAdmin.from('follows').delete()
        .eq('follower_id', req.user.id).eq('following_id', targetId);
      await supabaseAdmin.rpc('decrement_follower_count', { uid: targetId }).catch(() => {});
      await supabaseAdmin.rpc('decrement_following_count', { uid: req.user.id }).catch(() => {});
      return res.json({ following: false });
    }

    await supabaseAdmin.from('follows').insert({ follower_id: req.user.id, following_id: targetId });
    await supabaseAdmin.rpc('increment_follower_count', { uid: targetId }).catch(() => {});
    await supabaseAdmin.rpc('increment_following_count', { uid: req.user.id }).catch(() => {});
    res.json({ following: true });
  } catch (err) { next(err); }
});

// ─── DELETE /:userId/follow ───────────────────────────────────────────────────
router.delete('/:userId/follow', auth, async (req, res, next) => {
  try {
    const { userId: targetId } = req.params;
    await supabaseAdmin.from('follows').delete()
      .eq('follower_id', req.user.id).eq('following_id', targetId);
    await supabaseAdmin.rpc('decrement_follower_count', { uid: targetId }).catch(() => {});
    await supabaseAdmin.rpc('decrement_following_count', { uid: req.user.id }).catch(() => {});
    res.json({ following: false });
  } catch (err) { next(err); }
});

// ─── GET /:userId/followers ───────────────────────────────────────────────────
router.get('/:userId/followers', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 0;
    const limit = 20;
    const { data, error } = await supabaseAdmin.from('follows')
      .select('follower:follower_id(id, full_name, avatar_url, role, status, college_name, specialty, is_verified)')
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
      .select('following:following_id(id, full_name, avatar_url, role, status, college_name, specialty, is_verified)')
      .eq('follower_id', userId)
      .range(page * limit, page * limit + limit - 1);
    if (error) throw error;
    res.json({ following: (data || []).map(d => d.following).filter(Boolean), page });
  } catch (err) { next(err); }
});

// ─── GET /:userId (public profile — must come last) ───────────────────────────
router.get('/:userId', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);

    let query = supabaseAdmin.from('users')
      .select(`id, full_name, specialty, hospital, city, state, bio, avatar_url,
        follower_count, following_count, post_count, fame_tier, handle, status, role,
        current_streak, session_count, leaderboard_rank, is_verified, is_suspended,
        vouch_count, college_name, college_city, college_state, university,
        year_of_study, tags, languages, created_at, is_pro`)
      .neq('profile_visibility', 'hidden');

    query = isUuid ? query.eq('id', userId) : query.eq('handle', userId);

    const { data, error } = await query.maybeSingle();
    if (error || !data) return res.status(404).json({ error: 'Profile not found' });
    res.json({ profile: data });
  } catch (err) { next(err); }
});

module.exports = router;

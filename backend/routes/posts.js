const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('../services/supabase');
const auth = require('../middleware/auth');

// ─── GET /api/posts/feed ─────────────────────────────────────────────────────
router.get('/feed', async (req, res, next) => {
  try {
    const { type = 'rounds', page = 1 } = req.query;
    const limit  = 20;
    const offset = (page - 1) * limit;

    const { data, error } = await supabaseAdmin
      .from('posts')
      .select(`
        *,
        users!author_id (full_name, avatar_url, handle, status, fame_tier)
      `)
      .eq('type', type)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    res.json({ posts: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/posts/create ───────────────────────────────────────────────────
router.post('/create', auth, async (req, res, next) => {
  try {
    const { type, content, mediaUrl, mediaType, topicTag, isPremium } = req.body;
    if (!type || !content) return res.status(400).json({ error: 'type and content required' });

    const { data, error } = await supabaseAdmin
      .from('posts')
      .insert({
        id: uuidv4(),
        author_id: req.user.id,
        type,
        content,
        media_url: mediaUrl,
        media_type: mediaType,
        topic_tag: topicTag,
        is_premium: isPremium || false,
      })
      .select()
      .single();

    if (error) throw error;

    // Increment author post count
    await supabaseAdmin.rpc('increment_post_count', { uid: req.user.id });

    res.status(201).json({ post: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/posts/:id/like ────────────────────────────────────────────────
router.post('/:id/like', auth, async (req, res, next) => {
  try {
    const { id } = req.params;

    // Toggle like
    const { data: existing } = await supabaseAdmin
      .from('post_likes')
      .select('user_id')
      .eq('user_id', req.user.id)
      .eq('post_id', id)
      .single();

    if (existing) {
      await supabaseAdmin.from('post_likes')
        .delete().eq('user_id', req.user.id).eq('post_id', id);
      await supabaseAdmin.rpc('decrement_like_count', { pid: id });
      return res.json({ liked: false });
    }

    await supabaseAdmin.from('post_likes').insert({ user_id: req.user.id, post_id: id });
    await supabaseAdmin.rpc('increment_like_count', { pid: id });
    res.json({ liked: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/posts/:id/comment ────────────────────────────────────────────
router.post('/:id/comment', auth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'content required' });

    const { data, error } = await supabaseAdmin
      .from('comments')
      .insert({ id: uuidv4(), post_id: id, author_id: req.user.id, content })
      .select()
      .single();
    if (error) throw error;

    await supabaseAdmin.rpc('increment_comment_count', { pid: id });
    res.status(201).json({ comment: data });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/posts/:id/comments ────────────────────────────────────────────
router.get('/:id/comments', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { data, error } = await supabaseAdmin
      .from('comments')
      .select(`*, users!author_id (full_name, avatar_url)`)
      .eq('post_id', id)
      .order('created_at', { ascending: true });
    if (error) throw error;
    res.json({ comments: data });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

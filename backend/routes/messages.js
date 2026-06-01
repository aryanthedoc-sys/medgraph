const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { supabaseAdmin } = require('../services/supabase');

// GET /api/messages — all conversations for current user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const { data, error } = await supabaseAdmin
      .from('conversations')
      .select(`
        id,
        last_message,
        last_message_at,
        unread_count_user1,
        unread_count_user2,
        user1_id,
        user2_id,
        user1:user1_id(id, full_name, avatar_url, role, college_name, is_verified),
        user2:user2_id(id, full_name, avatar_url, role, college_name, is_verified)
      `)
      .or(`user1_id.eq.${userId},user2_id.eq.${userId}`)
      .order('last_message_at', { ascending: false });

    if (error) throw error;

    const formatted = (data || []).map(conv => {
      const isUser1 = conv.user1_id === userId;
      const partner = isUser1 ? conv.user2 : conv.user1;
      const unreadCount = isUser1 ? conv.unread_count_user1 : conv.unread_count_user2;
      return {
        id: conv.id,
        partner,
        last_message: conv.last_message,
        last_message_at: conv.last_message_at,
        unread_count: unreadCount,
      };
    });

    res.json({ conversations: formatted });
  } catch (err) {
    console.error('Get conversations error:', err);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/messages/start — start or get existing conversation
router.post('/start', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { targetUserId } = req.body;

    if (!targetUserId) {
      return res.status(400).json({ error: 'targetUserId required' });
    }

    const [user1Id, user2Id] =
      userId < targetUserId
        ? [userId, targetUserId]
        : [targetUserId, userId];

    const { data: existing } = await supabaseAdmin
      .from('conversations')
      .select('id')
      .eq('user1_id', user1Id)
      .eq('user2_id', user2Id)
      .single();

    if (existing) {
      return res.json({ conversationId: existing.id });
    }

    const { data: conv, error } = await supabaseAdmin
      .from('conversations')
      .insert({ user1_id: user1Id, user2_id: user2Id })
      .select('id')
      .single();

    if (error) throw error;
    res.json({ conversationId: conv.id });
  } catch (err) {
    console.error('Start conversation error:', err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/messages/:conversationId — messages in a conversation
router.get('/:conversationId', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { conversationId } = req.params;

    const { data: conv } = await supabaseAdmin
      .from('conversations')
      .select('user1_id, user2_id')
      .eq('id', conversationId)
      .single();

    if (!conv || (conv.user1_id !== userId && conv.user2_id !== userId)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const { data: msgs, error } = await supabaseAdmin
      .from('messages')
      .select('id, content, sender_id, read_at, created_at')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(50);

    if (error) throw error;

    // Mark received messages as read
    await supabaseAdmin
      .from('messages')
      .update({ read_at: new Date().toISOString() })
      .eq('conversation_id', conversationId)
      .neq('sender_id', userId)
      .is('read_at', null);

    // Reset unread count for current user
    const isUser1 = conv.user1_id === userId;
    await supabaseAdmin
      .from('conversations')
      .update(isUser1 ? { unread_count_user1: 0 } : { unread_count_user2: 0 })
      .eq('id', conversationId);

    res.json({ messages: msgs });
  } catch (err) {
    console.error('Get messages error:', err);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/messages/:conversationId — send a message
router.post('/:conversationId', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { conversationId } = req.params;
    const { content } = req.body;

    if (!content?.trim()) {
      return res.status(400).json({ error: 'Message cannot be empty' });
    }

    const { data: conv } = await supabaseAdmin
      .from('conversations')
      .select('user1_id, user2_id')
      .eq('id', conversationId)
      .single();

    if (!conv || (conv.user1_id !== userId && conv.user2_id !== userId)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const { data: msg, error } = await supabaseAdmin
      .from('messages')
      .insert({ conversation_id: conversationId, sender_id: userId, content: content.trim() })
      .select()
      .single();

    if (error) throw error;

    // Fetch current unread count then increment for the other user
    const isUser1 = conv.user1_id === userId;
    const unreadField = isUser1 ? 'unread_count_user2' : 'unread_count_user1';

    const { data: convData } = await supabaseAdmin
      .from('conversations')
      .select('unread_count_user1, unread_count_user2')
      .eq('id', conversationId)
      .single();

    const newCount = ((convData?.[unreadField]) || 0) + 1;

    await supabaseAdmin
      .from('conversations')
      .update({
        last_message: content.trim(),
        last_message_at: new Date().toISOString(),
        [unreadField]: newCount,
      })
      .eq('id', conversationId);

    // Real-time: push to receiver via Socket.io if online
    const receiverId = isUser1 ? conv.user2_id : conv.user1_id;
    const receiverSocketId = global.onlineUsers?.get(receiverId);
    if (receiverSocketId && global.io) {
      global.io.to(receiverSocketId).emit('new_message', {
        conversationId,
        message: msg,
        senderId: userId,
      });
    }

    res.json({ message: msg });
  } catch (err) {
    console.error('Send message error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

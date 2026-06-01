import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/auth_storage.dart';
import '../../../shared/services/socket_service.dart';
import 'chat_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupSocket();
  }

  void _setupSocket() {
    final userId = AuthStorage.userId;
    if (userId.isNotEmpty) {
      SocketService.emit('user_online', userId);
    }
    SocketService.on('new_message', (_) => _loadConversations());
  }

  Future<void> _loadConversations() async {
    try {
      final response = await ApiService.get('/api/messages');
      if (mounted) {
        setState(() {
          _conversations = response['conversations'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    SocketService.off('new_message');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _startNewConversation,
            tooltip: 'New message',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C7BE)))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) => _buildConversationTile(
                      _conversations[i] as Map<String, dynamic>,
                    ),
                  ),
                ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv) {
    final partner = (conv['partner'] as Map<String, dynamic>?) ?? {};
    final unread = conv['unread_count'] as int? ?? 0;
    final lastMsg = conv['last_message'] as String? ?? '';
    final lastTime = conv['last_message_at'] as String?;
    final name = partner['full_name'] as String? ?? 'User';
    final avatarUrl = partner['avatar_url'] as String?;
    final isVerified = partner['is_verified'] as bool? ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF00C7BE),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          if (isVerified) const Icon(Icons.verified, color: Color(0xFF00C7BE), size: 14),
          const SizedBox(width: 8),
          Text(
            _formatTime(lastTime),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMsg.isEmpty ? 'Start a conversation' : lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0 ? Colors.white : Colors.grey,
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF00C7BE),
                shape: BoxShape.circle,
              ),
              child: Text(
                unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversationId: conv['id'] as String,
            partner: partner,
          ),
        ),
      ).then((_) => _loadConversations()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Match with someone to start chatting',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/roulette'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7BE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(980)),
            ),
            child: const Text('Find a match'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  void _startNewConversation() {
    Navigator.pushNamed(context, '/search');
  }
}

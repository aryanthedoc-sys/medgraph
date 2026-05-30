import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';

class FollowersScreen extends ConsumerStatefulWidget {
  const FollowersScreen({
    super.key,
    required this.userId,
    required this.mode,
  });
  final String userId;
  final String mode; // 'followers' or 'following'

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final Set<String> _following = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final endpoint = '/api/profiles/${widget.userId}/${widget.mode}';
      final data = await ApiService.get(endpoint);
      final key  = widget.mode;
      final list = (data[key] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) setState(() { _users = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(String targetId) async {
    final isFollowing = _following.contains(targetId);
    setState(() {
      if (isFollowing) _following.remove(targetId);
      else _following.add(targetId);
    });
    try {
      if (isFollowing) {
        await ApiService.delete('/api/profiles/$targetId/follow');
      } else {
        await ApiService.post('/api/profiles/$targetId/follow', {});
      }
    } catch (_) {
      // Revert on error
      if (mounted) setState(() {
        if (isFollowing) _following.add(targetId);
        else _following.remove(targetId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? Colors.black : Colors.white;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final myId    = ref.read(currentUserProvider)?.id;
    final title   = widget.mode == 'followers' ? 'Followers' : 'Following';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => context.pop(),
        ),
        title: Text(title,
            style: AppTextStyles.headline.copyWith(color: text)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: sub),
                      const SizedBox(height: 12),
                      Text('No ${widget.mode} yet',
                          style: AppTextStyles.headline.copyWith(color: text)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 72,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (_, i) {
                    final u   = _users[i];
                    final uid = u['id'] as String? ?? '';
                    final isMe = uid == myId;
                    final isFollowing = _following.contains(uid);

                    return ListTile(
                      onTap: isMe
                          ? () => context.push('/profile')
                          : () => context.push('/profile/$uid'),
                      leading: _MiniAvatar(
                        name: u['full_name'] as String? ?? '',
                        url:  u['avatar_url'] as String?,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              u['full_name'] as String? ?? '',
                              style: AppTextStyles.subheadline
                                  .copyWith(color: text, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (u['is_verified'] == true) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 14, color: AppColors.teal),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        _subtitle(u),
                        style: AppTextStyles.caption.copyWith(color: sub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isMe
                          ? null
                          : SizedBox(
                              width: 88,
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () => _toggleFollow(uid),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isFollowing
                                      ? sub
                                      : AppColors.teal,
                                  side: BorderSide(
                                    color: isFollowing
                                        ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                        : AppColors.teal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isFollowing ? sub : AppColors.teal),
                                ),
                              ),
                            ),
                    );
                  },
                ),
    );
  }

  String _subtitle(Map<String, dynamic> u) {
    final role    = u['role'] as String? ?? '';
    final college = u['college_name'] as String? ?? '';
    final spec    = u['specialty'] as String? ?? '';
    if (role.startsWith('student_') && college.isNotEmpty) return college;
    if (role == 'doctor' && spec.isNotEmpty) return spec;
    return role;
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.name, this.url});
  final String name;
  final String? url;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.teal),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(url!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initWidget())
            : _initWidget(),
      ),
    );
  }

  Widget _initWidget() => Container(
    color: AppColors.teal,
    child: Center(
      child: Text(_initials,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

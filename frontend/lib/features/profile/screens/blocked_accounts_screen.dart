import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/api_service.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/api/profiles/me/blocked');
      final list = (data['blocked'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) setState(() { _blocked = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String userId, String name) async {
    try {
      await ApiService.delete('/api/profiles/$userId/block');
      setState(() => _blocked.removeWhere((u) => u['id'] == userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name unblocked')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not unblock. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? Colors.black : Colors.white;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

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
        title: Text('Blocked Accounts',
            style: AppTextStyles.headline.copyWith(color: text)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_outlined, size: 48, color: sub),
                      const SizedBox(height: 12),
                      Text('No blocked accounts',
                          style: AppTextStyles.headline.copyWith(color: text)),
                      const SizedBox(height: 4),
                      Text('People you block will appear here',
                          style: AppTextStyles.body.copyWith(color: sub)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _blocked.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5, thickness: 0.5, indent: 72,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (_, i) {
                    final u    = _blocked[i];
                    final uid  = u['id'] as String? ?? '';
                    final name = u['full_name'] as String? ?? 'User';
                    final url  = u['avatar_url'] as String?;
                    final initials = name.trim().split(' ')
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .take(2).join().toUpperCase();

                    return ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.teal),
                        child: ClipOval(
                          child: url != null && url.isNotEmpty
                              ? Image.network(url, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _initialsWidget(initials))
                              : _initialsWidget(initials),
                        ),
                      ),
                      title: Text(name,
                          style: AppTextStyles.subheadline
                              .copyWith(color: text, fontWeight: FontWeight.w600)),
                      subtitle: Text(u['role'] as String? ?? '',
                          style: AppTextStyles.caption.copyWith(color: sub)),
                      trailing: TextButton(
                        onPressed: () => _unblock(uid, name),
                        child: const Text('Unblock',
                            style: TextStyle(color: AppColors.teal)),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _initialsWidget(String initials) => Container(
    color: AppColors.teal,
    child: Center(child: Text(initials,
        style: const TextStyle(color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w600))),
  );
}

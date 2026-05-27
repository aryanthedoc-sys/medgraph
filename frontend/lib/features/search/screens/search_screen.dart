import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/mg_avatar.dart';
import '../../../shared/widgets/mg_badge.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/services/api_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _filter = 'all'; // all | doctor | student

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
          '/api/search/users?q=${Uri.encodeComponent(q)}&type=$_filter');
      setState(() {
        _results = (data['users'] as List? ?? []).cast<Map<String, dynamic>>();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(currentUserProvider.notifier).isPro;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search',
                  style: AppTextStyles.largeTitle.copyWith(color: text)),
              const SizedBox(height: 16),

              // Search field — locked for free users
              Stack(
                children: [
                  TextField(
                    controller: _queryCtrl,
                    enabled: isPro,
                    onChanged: _search,
                    style: AppTextStyles.body.copyWith(color: text),
                    decoration: InputDecoration(
                      hintText: 'Search verified medical professionals…',
                      hintStyle: AppTextStyles.body.copyWith(color: sub),
                      prefixIcon: Icon(Icons.search, color: sub),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (!isPro)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => context.go('/upgrade'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Filter chips
              Row(
                children: [
                  _FilterChip(label: 'All', value: 'all', current: _filter,
                      onTap: (v) { setState(() => _filter = v); _search(_queryCtrl.text); }),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Doctors', value: 'doctor', current: _filter,
                      onTap: (v) { setState(() => _filter = v); _search(_queryCtrl.text); }),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Students', value: 'student', current: _filter,
                      onTap: (v) { setState(() => _filter = v); _search(_queryCtrl.text); }),
                ],
              ),

              const SizedBox(height: 20),

              if (!isPro)
                Expanded(child: _LockedOverlay())
              else if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_results.isEmpty && _queryCtrl.text.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text('No results found',
                        style: AppTextStyles.subheadline.copyWith(color: sub)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _UserResultCard(user: _results[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final text = isDark ? Colors.white : Colors.black;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 48, color: sub),
          const SizedBox(height: 16),
          Text(
            'Search verified medical professionals',
            style: AppTextStyles.headline.copyWith(color: text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Pro to access profile search.',
            style: AppTextStyles.subheadline.copyWith(color: sub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: MGButton(
              label: 'Upgrade to Pro',
              onPressed: () => GoRouter.of(context).go('/upgrade'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  const _UserResultCard({required this.user});
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final isDoctor = user['role'] == 'doctor';
    final handle = user['handle'] as String?;

    return GestureDetector(
      onTap: handle != null
          ? () => GoRouter.of(context).go('/dr/$handle')
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            MGAvatar(
              name: user['full_name'] as String? ?? '?',
              imageUrl: user['avatar_url'] as String?,
              size: AvatarSize.medium,
              isVerifiedDoctor: isDoctor,
              isVerifiedStudent: !isDoctor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['full_name'] as String? ?? '',
                      style: AppTextStyles.subheadline.copyWith(color: text,
                          fontWeight: FontWeight.w600)),
                  if (isDoctor && user['specialty'] != null)
                    Text(user['specialty'] as String,
                        style: AppTextStyles.caption.copyWith(color: sub)),
                  if (!isDoctor && user['college'] != null)
                    Text(user['college'] as String,
                        style: AppTextStyles.caption.copyWith(color: sub)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MGBadge(
                  type: isDoctor ? BadgeType.verified : BadgeType.verified,
                ),
                if (isDoctor && user['follower_count'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${user['follower_count']} followers',
                    style: AppTextStyles.caption.copyWith(color: sub),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label, required this.value,
    required this.current, required this.onTap,
  });
  final String label, value, current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = value == current;
    final text = isDark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? text : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? text
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

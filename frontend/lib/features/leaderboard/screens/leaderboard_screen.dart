import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_avatar.dart';
import '../../../shared/services/api_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => _load());
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final types = ['streak', 'sessions', 'topics'];
    try {
      final data = await ApiService.get(
          '/api/leaderboard?type=${types[_tabCtrl.index]}');
      setState(() {
        _entries = (data['entries'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('Leaderboard',
                  style: AppTextStyles.largeTitle.copyWith(color: text)),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: text,
              unselectedLabelColor:
                  isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
              indicatorColor: text,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: '🔥 Streak'),
                Tab(text: '📅 Sessions'),
                Tab(text: '📚 Topics'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? _EmptyState()
                      : _LeaderboardList(
                          entries: _entries,
                          type: ['streak', 'sessions', 'topics'][_tabCtrl.index],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.entries, required this.type});
  final List<Map<String, dynamic>> entries;
  final String type;

  String _valueLabel(Map<String, dynamic> e) {
    switch (type) {
      case 'streak':   return '${e['current_streak'] ?? 0} days';
      case 'sessions': return '${e['sessions_this_month'] ?? 0} sessions';
      case 'topics':   return '${(e['topics_this_month'] as List?)?.length ?? 0} topics';
      default:         return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = entries[i];
        final rank = i + 1;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank',
                  style: AppTextStyles.headline.copyWith(color: text),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              MGAvatar(
                name: e['full_name'] as String? ?? '?',
                imageUrl: e['avatar_url'] as String?,
                size: AvatarSize.small,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (e['full_name'] as String? ?? '').split(' ').first,
                      style: AppTextStyles.subheadline.copyWith(color: text),
                    ),
                    if (e['college'] != null)
                      Text(e['college'] as String,
                          style: AppTextStyles.caption.copyWith(color: sub)),
                  ],
                ),
              ),
              Text(
                _valueLabel(e),
                style: AppTextStyles.footnote.copyWith(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: sub),
          const SizedBox(height: 16),
          Text('No data yet', style: AppTextStyles.headline.copyWith(color: sub)),
          const SizedBox(height: 8),
          Text('Complete sessions to appear on the leaderboard.',
              style: AppTextStyles.subheadline.copyWith(color: sub),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

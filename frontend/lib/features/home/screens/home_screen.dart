import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_card.dart';
import '../../../shared/widgets/disclaimer_overlay.dart';
import '../widgets/streak_card.dart';
import '../widgets/mcq_card.dart';
import '../widgets/filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _mode = 'study'; // study | clinical | casual
  int _onlineCount = 0;
  final SessionFilters _filters = SessionFilters();

  @override
  void initState() {
    super.initState();
    _loadOnlineCount();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDisclaimer());
  }

  Future<void> _checkDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('disclaimer_accepted') ?? false;
    if (!accepted && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DisclaimerOverlay(
            variant: DisclaimerVariant.onboarding),
      );
    }
  }

  Future<void> _loadOnlineCount() async {
    // In production: fetch from socket or API
    setState(() => _onlineCount = 42);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        filters: _filters,
        onApply: (f) {
          setState(() {
            _filters.college = f.college;
            _filters.location = f.location;
            _filters.year = f.year;
            _filters.specialty = f.specialty;
          });
        },
        isPro: ref.read(currentUserProvider.notifier).isPro,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    final firstName = user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_greeting()}, $firstName',
                            style: AppTextStyles.title2.copyWith(color: text),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_outlined, color: text),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Streak card
                    StreakCard(
                      streak: user?.currentStreak ?? 0,
                      sessionsToday: 0,
                    ),
                    const SizedBox(height: 16),

                    // Mode selector
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _ModeTab(label: 'Study', value: 'study', current: _mode,
                              onTap: (v) => setState(() => _mode = v)),
                          _ModeTab(label: 'Clinical', value: 'clinical', current: _mode,
                              onTap: (v) => setState(() => _mode = v)),
                          _ModeTab(label: 'Casual', value: 'casual', current: _mode,
                              onTap: (v) => setState(() => _mode = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_filters.college != null)
                            _FilterChip(label: _filters.college!, onRemove: () => setState(() => _filters.college = null)),
                          if (_filters.location != null)
                            _FilterChip(label: _filters.location!, onRemove: () => setState(() => _filters.location = null)),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.tune, size: 16, color: sub),
                                  const SizedBox(width: 6),
                                  Text('Filters', style: AppTextStyles.footnote.copyWith(color: sub)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Session button
                    MGButton(
                      label: 'Start session',
                      onPressed: () => context.go('/roulette'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '$_onlineCount students online now',
                        style: AppTextStyles.footnote.copyWith(color: sub),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: MGCard(
                            onTap: () => context.go('/sessions'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.calendar_today_outlined, color: text),
                                const SizedBox(height: 8),
                                Text('Book a session', style: AppTextStyles.headline.copyWith(color: text)),
                                Text('Schedule for later', style: AppTextStyles.footnote.copyWith(color: sub)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MGCard(
                            onTap: () => context.go('/feed'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.play_circle_outline, color: text),
                                const SizedBox(height: 8),
                                Text('Creator feed', style: AppTextStyles.headline.copyWith(color: text)),
                                Text('Rounds, Cases & Life', style: AppTextStyles.footnote.copyWith(color: sub)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // MCQ of the day
                    const MCQCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = value == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.subheadline.copyWith(
                color: isActive
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.footnote.copyWith(
                color: isDark ? Colors.black : Colors.white,
              )),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14,
                color: isDark ? Colors.black : Colors.white),
          ),
        ],
      ),
    );
  }
}

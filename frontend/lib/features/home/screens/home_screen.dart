import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
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

                    // Verification banner
                    if (user != null && !user.isVerified) ...[
                      _HomeVerificationBanner(user: user),
                      const SizedBox(height: 16),
                    ],

                    // Pro free period banner
                    if (user != null && user.isPro && user.proExpiresAt != null) ...[
                      _ProBanner(expiresAt: user.proExpiresAt!),
                      const SizedBox(height: 16),
                    ],

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

                    // Book a Session card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF00C7BE), size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Book a Study Session',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C7BE).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text(
                                  'UNLIMITED',
                                  style: TextStyle(
                                    color: Color(0xFF00C7BE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Schedule in advance. We match you with a study partner and notify you by email.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/sessions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C7BE),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Schedule a session →',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
                    const SizedBox(height: 12),

                    // Amber info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Early stage: Book sessions for guaranteed matches. '
                              'Live roulette works best with more users online simultaneously.',
                              style: TextStyle(
                                color: Colors.amber.shade200,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _HomeVerificationBanner extends StatelessWidget {
  const _HomeVerificationBanner({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = user.isProofSubmitted;
    return GestureDetector(
      onTap: isSubmitted ? null : () => context.push('/register/proof-upload'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSubmitted
                    ? 'Verification under review — our team will contact you within 24h'
                    : 'Verification pending — Upload your proof to get your verified badge',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A5600),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isSubmitted)
              const Icon(Icons.chevron_right, color: Colors.amber, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ProBanner extends StatefulWidget {
  const _ProBanner({required this.expiresAt});
  final DateTime expiresAt;

  @override
  State<_ProBanner> createState() => _ProBannerState();
}

class _ProBannerState extends State<_ProBanner> {
  bool _dismissed = false;

  int get _daysRemaining {
    final diff = widget.expiresAt.difference(DateTime.now()).inDays;
    return diff.clamp(0, 9999);
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final key = 'pro_banner_dismissed_${widget.expiresAt.millisecondsSinceEpoch ~/ 86400000}';
      if (p.getBool(key) == true && mounted) setState(() => _dismissed = true);
    });
  }

  void _dismiss() async {
    final p = await SharedPreferences.getInstance();
    final key = 'pro_banner_dismissed_${widget.expiresAt.millisecondsSinceEpoch ~/ 86400000}';
    await p.setBool(key, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final urgent = _daysRemaining <= 30;
    final color  = urgent ? Colors.amber : AppColors.teal;
    final expiry = '${['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'][widget.expiresAt.month - 1]} ${widget.expiresAt.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(urgent ? '⏰' : '🎉', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgent ? 'Pro free period ends in $_daysRemaining days' : 'Pro features are free during launch!',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: urgent ? const Color(0xFF7A5600) : color,
                  ),
                ),
                Text(
                  urgent
                      ? 'Add payment method to continue →'
                      : 'Unlimited sessions, matching filters & more until $expiry',
                  style: TextStyle(
                    fontSize: 12,
                    color: urgent ? const Color(0xFF7A5600) : color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!urgent)
            GestureDetector(
              onTap: _dismiss,
              child: Icon(Icons.close, size: 16, color: color.withValues(alpha: 0.7)),
            ),
        ],
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

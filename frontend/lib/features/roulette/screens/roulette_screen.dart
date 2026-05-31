import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/services/socket_service.dart';
import '../../../shared/services/auth_storage.dart';
import '../../video/screens/video_call_screen.dart';

enum _MatchState { idle, searching }

class RouletteScreen extends ConsumerStatefulWidget {
  const RouletteScreen({super.key});

  @override
  ConsumerState<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends ConsumerState<RouletteScreen>
    with SingleTickerProviderStateMixin {
  _MatchState _state = _MatchState.idle;
  String _mode = 'study';
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Listeners are registered inside onConnected (after socket exists).
  }

  // Called inside onConnected so _socket is guaranteed non-null.
  // off() first prevents duplicate handlers if the user taps Start multiple times.
  void _setupSocketListeners() {
    SocketService.off('match-found');
    SocketService.off('queue-timeout');
    SocketService.off('queue-error');

    SocketService.on('match-found', (data) {
      if (!mounted) return;

      // Debug — visible in Flutter DevTools / console
      // ignore: avoid_print
      print('RAW match-found data: $data');

      final roomName   = (data['roomName']     as String?) ?? '';
      final token      = (data['livekitToken'] as String?) ?? '';
      final livekitUrl = (data['livekitUrl']   as String?) ?? '';
      final partner    = (data['partner']      as Map?)    ?? {};

      // ignore: avoid_print
      print('[match-found] roomName=$roomName | token present=${token.isNotEmpty} | url=$livekitUrl | partner=$partner');

      if (roomName.isEmpty || token.isEmpty || livekitUrl.isEmpty) {
        // ignore: avoid_print
        print('[match-found] ERROR: missing connection params — aborting navigation');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match found but connection failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _state = _MatchState.idle);
        return;
      }

      setState(() => _state = _MatchState.idle);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          roomName: roomName,
          token: token,
          livekitUrl: livekitUrl,
          partnerInfo: {
            'name':    (partner['name']    as String?) ?? 'Partner',
            'role':    (partner['role']    as String?) ?? '',
            'college': (partner['college'] as String?) ?? '',
            'avatar':  (partner['avatar']  as String?) ?? '',
          },
        ),
      ));
    });

    SocketService.on('queue-timeout', (_) {
      if (!mounted) return;
      setState(() => _state = _MatchState.idle);
      _showNoMatchDialog();
    });

    SocketService.on('queue-error', (data) {
      if (!mounted) return;
      setState(() => _state = _MatchState.idle);
      final code    = data['code'] as String?;
      final message = data['message'] as String? ?? 'Could not join queue.';
      if (code == 'UNVERIFIED') {
        _showVerificationSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  void _startSearch() {
    final user   = ref.read(currentUserProvider);
    final userId = (user?.id.isNotEmpty == true) ? user!.id : AuthStorage.userId;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in — please restart the app.')),
      );
      return;
    }

    // Client-side verification check — server also checks, but this gives instant UX
    if (user != null && !user.isVerified) {
      _showVerificationSheet();
      return;
    }

    setState(() => _state = _MatchState.searching);

    SocketService.connect(onConnected: () {
      _setupSocketListeners(); // socket exists now — safe to register
      SocketService.emit('join-queue', {
        'userId': userId,
        'mode': _mode,
        'filters': {},
      });
    });
  }

  void _cancelSearch() {
    SocketService.emit('leave-queue', {});
    setState(() => _state = _MatchState.idle);
  }

  void _showNoMatchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No match right now'),
        content: const Text(
          'Nobody is available with your current filters.\nTry booking a session instead.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/sessions');
            },
            child: const Text('Book a session'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  void _showVerificationSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_outlined,
                    color: AppColors.teal, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Verification required',
                style: AppTextStyles.title2.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your credentials to access live matching. '
                'This keeps MedGraph safe for everyone.',
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              MGButton(
                label: 'Upload now',
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/register/proof-upload');
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/sessions');
                },
                child: Text(
                  'Book a session instead',
                  style: TextStyle(
                    color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SocketService.off('match-found');
    SocketService.off('queue-timeout');
    SocketService.off('queue-error');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Match', style: AppTextStyles.largeTitle.copyWith(color: text)),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Connect instantly with a verified peer.',
                  style: AppTextStyles.body.copyWith(color: sub),
                ),
              ),

              // Unverified warning
              if (user != null && !user.isVerified) ...[
                const SizedBox(height: 16),
                _UnverifiedBanner(onTap: _showVerificationSheet),
              ],

              const SizedBox(height: 24),

              // Mode selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ModeTab(label: 'Study',    value: 'study',    current: _mode, onTap: (v) => setState(() => _mode = v)),
                    _ModeTab(label: 'Clinical', value: 'clinical', current: _mode, onTap: (v) => setState(() => _mode = v)),
                    _ModeTab(label: 'Casual',   value: 'casual',   current: _mode, onTap: (v) => setState(() => _mode = v)),
                  ],
                ),
              ),
              const Spacer(),

              if (_state == _MatchState.searching)
                _SearchingAnimation(pulse: _pulse)
              else
                _IdleMatchButton(onTap: _startSearch),

              const SizedBox(height: 16),
              if (_state == _MatchState.searching)
                Column(
                  children: [
                    Text('Searching for a match…',
                        style: AppTextStyles.headline.copyWith(color: text)),
                    const SizedBox(height: 4),
                    Text('Usually under 30 seconds',
                        style: AppTextStyles.footnote.copyWith(color: sub)),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _cancelSearch,
                      child: Text('Cancel', style: TextStyle(color: sub)),
                    ),
                  ],
                )
              else
                Text('Tap to start a session',
                    style: AppTextStyles.subheadline.copyWith(color: sub)),

              const Spacer(),
              MGButton(
                label: 'Book a session instead',
                onPressed: () => context.go('/sessions'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnverifiedBanner extends StatelessWidget {
  const _UnverifiedBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'You need to verify to use live matching',
                style: TextStyle(fontSize: 13, color: Color(0xFF7A5600)),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.amber, size: 16),
          ],
        ),
      ),
    );
  }
}

class _IdleMatchButton extends StatelessWidget {
  const _IdleMatchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, height: 140,
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shuffle_rounded,
          size: 56,
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class _SearchingAnimation extends StatelessWidget {
  const _SearchingAnimation({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTransition(
      scale: pulse,
      child: Container(
        width: 140, height: 140,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
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
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final isActive = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
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

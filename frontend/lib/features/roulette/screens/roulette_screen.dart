import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/services/socket_service.dart';
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
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    SocketService.on('match-found', (data) {
      if (!mounted) return;
      final roomId = data['roomId'] as String;
      final partnerName = data['partnerName'] as String? ?? 'Your match';
      final partnerCollege = data['partnerCollege'] as String? ?? '';
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          roomId: roomId,
          partnerName: partnerName,
          partnerCollege: partnerCollege,
        ),
      ));
      setState(() => _state = _MatchState.idle);
    });

    SocketService.on('queue-timeout', (_) {
      if (!mounted) return;
      setState(() => _state = _MatchState.idle);
      _showNoMatchDialog();
    });
  }

  void _startSearch() {
    final user = ref.read(currentUserProvider);

    setState(() => _state = _MatchState.searching);

    SocketService.connect();
    SocketService.emit('join-queue', {
      'userId': user?.id ?? '',
      'mode': _mode,
      'filters': {},
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

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SocketService.off('match-found');
    SocketService.off('queue-timeout');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Match', style: AppTextStyles.largeTitle.copyWith(color: text)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Connect instantly with a verified peer.',
                  style: AppTextStyles.body.copyWith(color: sub),
                ),
              ),
              const SizedBox(height: 32),

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
              const Spacer(),

              // Centre animation
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
                Text(
                  'Tap to start a session',
                  style: AppTextStyles.subheadline.copyWith(color: sub),
                ),

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

class _IdleMatchButton extends StatelessWidget {
  const _IdleMatchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
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
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
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

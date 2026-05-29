import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _teal = Color(0xFF17C3B2);

class LandingHero extends StatefulWidget {
  const LandingHero({super.key, required this.isMobile});
  final bool isMobile;

  @override
  State<LandingHero> createState() => _LandingHeroState();
}

class _LandingHeroState extends State<LandingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  // staggered visibility flags
  bool _s0 = false, _s1 = false, _s2 = false,
       _s3 = false, _s4 = false, _s5 = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _s0 = true);
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _s1 = true);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _s2 = true);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _s3 = true);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _s4 = true);
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _s5 = true);
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return SizedBox(
      height: h,
      child: Stack(
        children: [
          // ── Gradient orbs ─────────────────────────────────────────────
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _teal.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 100, right: -150,
            child: Container(
              width: 600, height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF007AFF).withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: 100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFAF52DE).withValues(alpha: 0.05),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 24 : 40,
                  vertical: 40,
                ),
                child: widget.isMobile
                    ? _mobileLayout(context)
                    : _desktopLayout(context),
              ),
            ),
          ),

          // ── Scroll indicator ──────────────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _s5 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: const Column(
                children: [
                  Text(
                    'Scroll to explore',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF999999)),
                  ),
                  SizedBox(height: 4),
                  Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF999999), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _labelPill(),
        const SizedBox(height: 20),
        _headline(fontSize: 48),
        const SizedBox(height: 16),
        _subheadline(),
        const SizedBox(height: 28),
        _ctaRow(context),
        const SizedBox(height: 24),
        _socialProof(),
        const SizedBox(height: 32),
        _phoneMockups(),
      ],
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _labelPill(),
              const SizedBox(height: 24),
              _headline(fontSize: 88),
              const SizedBox(height: 20),
              _subheadline(maxWidth: 560),
              const SizedBox(height: 32),
              _ctaRow(context),
              const SizedBox(height: 28),
              _socialProof(),
            ],
          ),
        ),
        const SizedBox(width: 60),
        _phoneMockups(),
      ],
    );
  }

  Widget _labelPill() {
    return AnimatedOpacity(
      opacity: _s0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: _teal),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          "INDIA'S VERIFIED MEDICAL NETWORK",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _teal,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _headline({required double fontSize}) {
    return AnimatedSlide(
      offset: _s1 ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _s1 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study smarter.',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.0,
                letterSpacing: -3,
              ),
            ),
            Text(
              'Connect deeper.',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.0,
                letterSpacing: -3,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_teal, Color(0xFF007AFF)],
              ).createShader(bounds),
              child: Text(
                'Become great.',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subheadline({double? maxWidth}) {
    return AnimatedOpacity(
      opacity: _s2 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: const Text(
          "The platform where India's medical students find instant study "
          "partners, and verified doctors build their following and earn from teaching.",
          style: TextStyle(
            fontSize: 19,
            color: Color(0xFF666666),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _ctaRow(BuildContext context) {
    return AnimatedOpacity(
      opacity: _s3 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          GestureDetector(
            onTap: () => context.go('/register'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Start for free →',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            child: const Text(
              'See verified doctors →',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialProof() {
    return AnimatedOpacity(
      opacity: _s4 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 5 * 28.0 - 4 * 8.0,
            height: 28,
            child: Stack(
              children: List.generate(5, (i) => Positioned(
                left: i * 20.0,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: [
                      const Color(0xFFFFB347),
                      const Color(0xFF87CEEB),
                      const Color(0xFF98FB98),
                      const Color(0xFFDDA0DD),
                      const Color(0xFFF08080),
                    ][i],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      ['D', 'A', 'R', 'P', 'S'][i],
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join 2,400+ medical professionals',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              Text(
                'Students & doctors across India',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF999999)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phoneMockups() {
    return AnimatedOpacity(
      opacity: _s5 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          final float = Tween<double>(begin: -8, end: 8).evaluate(
            CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
          );
          return SizedBox(
            width: 320,
            height: 420,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _teal.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withValues(alpha: 0.2),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Back phone (rotated -8°)
                Positioned(
                  left: 0,
                  child: Transform.translate(
                    offset: Offset(0, float * 0.6),
                    child: Transform.rotate(
                      angle: -8 * math.pi / 180,
                      child: _PhoneMockup(
                        width: 200,
                        height: 380,
                        screenColor: const Color(0xFF1A1A2E),
                        child: _RouletteScreen(),
                      ),
                    ),
                  ),
                ),
                // Front phone (no rotation)
                Positioned(
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, float),
                    child: _PhoneMockup(
                      width: 220,
                      height: 420,
                      screenColor: const Color(0xFF0D0D0D),
                      child: _HomeScreen(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Phone shell ───────────────────────────────────────────────────────────────

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({
    required this.width,
    required this.height,
    required this.screenColor,
    required this.child,
  });

  final double width, height;
  final Color screenColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Container(
          color: screenColor,
          child: child,
        ),
      ),
    );
  }
}

// ─── Mock app screens ──────────────────────────────────────────────────────────

class _HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Status bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('9:41', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              Container(width: 30, height: 8, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Good morning, Aryan', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 8),
          // Streak card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('7-day streak!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    Text('3 sessions today', style: TextStyle(color: Colors.white38, fontSize: 9)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17C3B2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pro', style: TextStyle(color: Color(0xFF17C3B2), fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Match button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('Start session', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          // MCQ card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAF52DE).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('MCQ of the day', style: TextStyle(color: Color(0xFFAF52DE), fontSize: 8, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                const Text('Which of the following is most common cause of...', style: TextStyle(color: Colors.white70, fontSize: 9), maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouletteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Finding your match...', style: TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF17C3B2), width: 3),
            color: const Color(0xFF17C3B2).withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.person_outline, color: Color(0xFF17C3B2), size: 36),
        ),
        const SizedBox(height: 12),
        const Text('42 online now', style: TextStyle(color: Color(0xFF17C3B2), fontSize: 10)),
      ],
    );
  }
}

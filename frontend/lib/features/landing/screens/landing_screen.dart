import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/landing_hero.dart';
import '../widgets/landing_stats.dart';
import '../widgets/landing_roulette_section.dart';
import '../widgets/landing_doctor_fame.dart';
import '../widgets/landing_addiction_section.dart';
import '../widgets/landing_feeds.dart';
import '../widgets/landing_pricing.dart';
import '../widgets/landing_testimonials.dart';
import '../widgets/landing_early_access.dart';
import '../widgets/landing_footer.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollCtrl = ScrollController();
  bool _navSolid = false;
  final _featuresKey = GlobalKey();
  final _doctorsKey  = GlobalKey();
  final _pricingKey  = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final solid = _scrollCtrl.offset > 40;
    if (solid != _navSolid) setState(() => _navSolid = solid);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
              children: [
                // Spacer for navbar height
                const SizedBox(height: 64),
                LandingHero(isMobile: isMobile),
                LandingStats(scrollCtrl: _scrollCtrl),
                LandingRouletteSection(key: _featuresKey, isMobile: isMobile),
                LandingDoctorFame(key: _doctorsKey, isMobile: isMobile),
                LandingAddictionSection(isMobile: isMobile),
                LandingFeeds(isMobile: isMobile),
                LandingPricing(key: _pricingKey, isMobile: isMobile),
                LandingTestimonials(isMobile: isMobile),
                LandingEarlyAccess(isMobile: isMobile),
                LandingFooter(isMobile: isMobile),
              ],
            ),
          ),
          _Navbar(
            solid: _navSolid,
            isMobile: isMobile,
            featuresKey: _featuresKey,
            doctorsKey: _doctorsKey,
            pricingKey: _pricingKey,
          ),
        ],
      ),
    );
  }
}

// ─── Navbar ────────────────────────────────────────────────────────────────────

class _Navbar extends StatefulWidget {
  const _Navbar({
    required this.solid,
    required this.isMobile,
    required this.featuresKey,
    required this.doctorsKey,
    required this.pricingKey,
  });
  final bool solid;
  final bool isMobile;
  final GlobalKey featuresKey;
  final GlobalKey doctorsKey;
  final GlobalKey pricingKey;

  @override
  State<_Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<_Navbar> {
  bool _menuOpen = false;

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          decoration: BoxDecoration(
            color: widget.solid
                ? Colors.white.withValues(alpha: 0.96)
                : Colors.white,
            boxShadow: widget.solid
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 16 : 40),
            child: Row(
              children: [
                const Text(
                  'MedGraph',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (!widget.isMobile) ...[
                  _NavLink('Features', () => _scrollTo(widget.featuresKey)),
                  _NavLink('Doctors',  () => _scrollTo(widget.doctorsKey)),
                  _NavLink('Pricing',  () => _scrollTo(widget.pricingKey)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.go('/onboarding'),
                    child: const Text('Sign in',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  _EarlyAccessButton(
                      onTap: () => context.go('/register')),
                ] else ...[
                  IconButton(
                    icon: Icon(
                        _menuOpen ? Icons.close : Icons.menu,
                        color: Colors.black),
                    onPressed: () =>
                        setState(() => _menuOpen = !_menuOpen),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.isMobile && _menuOpen)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MobileNavItem('Features', () {
                  setState(() => _menuOpen = false);
                  _scrollTo(widget.featuresKey);
                }),
                _MobileNavItem('Doctors', () {
                  setState(() => _menuOpen = false);
                  _scrollTo(widget.doctorsKey);
                }),
                _MobileNavItem('Pricing', () {
                  setState(() => _menuOpen = false);
                  _scrollTo(widget.pricingKey);
                }),
                _MobileNavItem('Sign in', () {
                  setState(() => _menuOpen = false);
                  context.go('/onboarding');
                }),
                const SizedBox(height: 8),
                _EarlyAccessButton(onTap: () {
                  setState(() => _menuOpen = false);
                  context.go('/register');
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFF444444), fontSize: 14),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _EarlyAccessButton extends StatelessWidget {
  const _EarlyAccessButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'Get early access',
          style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

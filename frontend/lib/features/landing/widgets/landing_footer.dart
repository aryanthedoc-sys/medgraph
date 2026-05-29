import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key, required this.isMobile});
  final bool isMobile;

  void _nav(BuildContext context, String route) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final protectedRoutes = {
      '/match', '/feed', '/sessions', '/leaderboard',
      '/upgrade', '/profile', '/rankings/weekly',
    };
    if (protectedRoutes.contains(route) && !isLoggedIn) {
      context.push('/onboarding');
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 64,
              horizontal: isMobile ? 24 : 80,
            ),
            child: isMobile
                ? _mobileLayout(context)
                : _desktopLayout(context),
          ),
          // Copyright bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '© 2025 MedGraph · Built in India 🇮🇳',
                  style: TextStyle(color: Color(0x61FFFFFF), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'MedGraph is an educational platform. '
                  'Not medical advice. Not telemedicine.',
                  style: TextStyle(color: Color(0x3DFFFFFF), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand column
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MedGraph',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(
                'India\'s verified medical\nnetworking platform.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.4),
                    height: 1.6),
              ),
            ],
          ),
        ),
        _FooterColumn('Product', [
          _FooterLink('Matching',       () => _nav(context, '/roulette')),
          _FooterLink('Feed',           () => _nav(context, '/feed')),
          _FooterLink('Sessions',       () => _nav(context, '/sessions')),
          _FooterLink('Leaderboard',    () => _nav(context, '/leaderboard')),
          _FooterLink('Upgrade to Pro', () => _nav(context, '/upgrade')),
        ]),
        _FooterColumn('Community', [
          _FooterLink('For Students',       () => context.push('/register')),
          _FooterLink('For Doctors',        () => context.push('/register')),
          _FooterLink('MedGraph Fellows',   () => _nav(context, '/rankings/weekly')),
          _FooterLink('Creator Program',    () => _nav(context, '/profile')),
        ]),
        _FooterColumn('Company', [
          _FooterLink('About',           () => context.push('/about')),
          _FooterLink('Blog',            () => context.push('/blog')),
          _FooterLink('Contact',         () => context.push('/contact')),
          _FooterLink('Terms of Service',() => context.push('/legal/terms')),
          _FooterLink('Privacy Policy',  () => context.push('/legal/privacy')),
        ]),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MedGraph',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'India\'s verified medical networking platform.',
          style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _mobileLink(context, 'Terms', () => context.push('/legal/terms')),
            _mobileLink(context, 'Privacy', () => context.push('/legal/privacy')),
            _mobileLink(context, 'About', () => context.push('/about')),
            _mobileLink(context, 'Blog', () => context.push('/blog')),
            _mobileLink(context, 'Contact', () => context.push('/contact')),
          ],
        ),
      ],
    );
  }

  Widget _mobileLink(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn(this.title, this.links);
  final String title;
  final List<_FooterLink> links;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          ...links.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: l.onTap,
                  child: Text(
                    l.label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _FooterLink {
  const _FooterLink(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
}

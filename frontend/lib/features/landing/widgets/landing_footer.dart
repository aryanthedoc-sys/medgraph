import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key, required this.isMobile});
  final bool isMobile;

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
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 24,
              horizontal: isMobile ? 24 : 80,
            ),
            child: Column(
              children: [
                Text(
                  '© 2025 MedGraph · Built in India 🇮🇳',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.4)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Made for 2.3 million MBBS students',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'MedGraph is educational only. Not medical advice.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.25)),
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
          _FooterLink('Matching', () {}),
          _FooterLink('Feed', () {}),
          _FooterLink('Sessions', () {}),
          _FooterLink('Leaderboard', () {}),
          _FooterLink('Upgrade to Pro', () => context.go('/upgrade')),
        ]),
        _FooterColumn('Community', [
          _FooterLink('For Students', () {}),
          _FooterLink('For Doctors', () {}),
          _FooterLink('MedGraph Fellows', () {}),
          _FooterLink('Creator Program', () {}),
        ]),
        _FooterColumn('Company', [
          _FooterLink('About', () {}),
          _FooterLink('Blog', () {}),
          _FooterLink('Contact', () {}),
          _FooterLink('Terms of Service', () => context.push('/legal/terms')),
          _FooterLink('Privacy Policy', () => context.push('/legal/privacy')),
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
            GestureDetector(
              onTap: () => context.push('/legal/terms'),
              child: Text('Terms',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      decoration: TextDecoration.underline,
                      decorationColor:
                          Colors.white.withValues(alpha: 0.5))),
            ),
            GestureDetector(
              onTap: () => context.push('/legal/privacy'),
              child: Text('Privacy',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      decoration: TextDecoration.underline,
                      decorationColor:
                          Colors.white.withValues(alpha: 0.5))),
            ),
            GestureDetector(
              onTap: () {},
              child: Text('About',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5))),
            ),
            GestureDetector(
              onTap: () {},
              child: Text('Contact',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5))),
            ),
          ],
        ),
      ],
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _teal = Color(0xFF17C3B2);

class LandingPricing extends StatelessWidget {
  const LandingPricing({super.key, required this.isMobile});
  final bool isMobile;

  static const _freeFeatures = [
    (true, '5 matching sessions per day'),
    (true, 'Access to Rounds, Cases & Life feed'),
    (true, 'Basic profile & handle'),
    (true, 'Public leaderboard access'),
    (false, 'Unlimited matching sessions'),
    (false, 'Advanced filters (college, city, year)'),
    (false, 'Book scheduled 1-on-1 sessions'),
    (false, 'Subscribe to verified doctors'),
  ];

  static const _proFeatures = [
    (true, 'Everything in Free'),
    (true, 'Unlimited matching sessions'),
    (true, 'Advanced filters (college, city, year)'),
    (true, 'Book scheduled 1-on-1 sessions'),
    (true, 'Subscribe to verified doctors'),
    (true, 'Priority matching'),
    (true, 'Pro badge on profile'),
    (true, 'Early access to new features'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isMobile ? 20 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'PRICING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _teal,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start free. Go Pro when ready.',
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: [
                    _FreeCard(features: _freeFeatures, isMobile: isMobile),
                    const SizedBox(height: 20),
                    _ProCard(features: _proFeatures, isMobile: isMobile),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FreeCard(
                          features: _freeFeatures, isMobile: isMobile),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _ProCard(
                          features: _proFeatures, isMobile: isMobile),
                    ),
                  ],
                ),
          const SizedBox(height: 40),
          const Text(
            '"Less than one chai a day. No excuse not to be the best."',
            style: TextStyle(
              fontSize: 17,
              fontStyle: FontStyle.italic,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.features, required this.isMobile});
  final List<(bool, String)> features;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Free',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
          const SizedBox(height: 4),
          const Text('₹0 / forever',
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black)),
          const SizedBox(height: 24),
          ...features.map((f) => _FeatureRow(included: f.$1, label: f.$2)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0x1A000000)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Get started free',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.features, required this.isMobile});
  final List<(bool, String)> features;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Pro',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF17C3B2).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Most popular',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17C3B2))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('₹99 / month',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text('Less than one chai per day',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          ...features.map((f) => _FeatureRow(
              included: f.$1,
              label: f.$2,
              dark: true)),
          const SizedBox(height: 24),
          // Payment logos
          Row(
            children: [
              _PayLogo('UPI'),
              const SizedBox(width: 8),
              _PayLogo('Card'),
              const SizedBox(width: 8),
              _PayLogo('NetBanking'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Upgrade to Pro',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.included,
    required this.label,
    this.dark = false,
  });
  final bool included, dark;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            included ? Icons.check : Icons.close,
            size: 16,
            color: included
                ? (dark ? const Color(0xFF17C3B2) : Colors.black)
                : (dark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: included
                    ? (dark ? Colors.white : Colors.black)
                    : (dark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayLogo extends StatelessWidget {
  const _PayLogo(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

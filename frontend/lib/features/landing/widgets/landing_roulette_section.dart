import 'package:flutter/material.dart';

const Color _teal = Color(0xFF17C3B2);

class LandingRouletteSection extends StatefulWidget {
  const LandingRouletteSection({super.key, required this.isMobile});
  final bool isMobile;

  @override
  State<LandingRouletteSection> createState() =>
      _LandingRouletteSectionState();
}

class _LandingRouletteSectionState extends State<LandingRouletteSection> {
  int _selected = 0;

  static const _features = [
    _Feature(
      caption: 'INSTANT MATCH',
      title: 'Click start.\nSomeone appears.',
      body:
          'No waiting rooms, no scheduling. Tap once and you\'re face-to-face with a study partner across India within seconds.',
      pills: ['Avg wait < 3s', 'Always someone online', 'Verified profiles only'],
      icon: Icons.bolt_outlined,
      color: _teal,
    ),
    _Feature(
      caption: 'SKIP INSTANTLY',
      title: 'Not right?\nOne tap to next.',
      body:
          'Not feeling the vibe? Skip to the next match instantly. No awkwardness. Your time is too valuable.',
      pills: ['Anonymous skip', 'No rating penalty', 'Instant next match'],
      icon: Icons.skip_next_outlined,
      color: Color(0xFF007AFF),
    ),
    _Feature(
      caption: 'YOUR FILTERS',
      title: 'Same college.\nYour city.',
      body:
          'Pro members can filter by college, city, academic year, and specialty. Study with people who know exactly what you\'re going through.',
      pills: ['College filter', 'City filter', 'Specialty match'],
      icon: Icons.tune_outlined,
      color: Color(0xFFAF52DE),
    ),
    _Feature(
      caption: 'FREE FOREVER',
      title: '5 sessions daily.\nAlways free.',
      body:
          '5 free sessions every day. No credit card, no trial period. Upgrade to Pro for unlimited sessions and advanced filters.',
      pills: ['5 free/day', 'No credit card', 'Unlimited with Pro'],
      icon: Icons.card_giftcard_outlined,
      color: Color(0xFF34C759),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: widget.isMobile ? 20 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROULETTE MATCHING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _teal,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Study like you mean it.',
            style: TextStyle(
              fontSize: widget.isMobile ? 32 : 48,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 48),
          widget.isMobile
              ? _mobileLayout()
              : _desktopLayout(),
        ],
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone mockup
        _AnimatedPhone(selectedFeature: _features[_selected]),
        const SizedBox(width: 80),
        // Feature points
        Expanded(
          child: Column(
            children: List.generate(_features.length, (i) => _FeaturePoint(
              feature: _features[i],
              isSelected: i == _selected,
              onTap: () => setState(() => _selected = i),
            )),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      children: [
        _AnimatedPhone(selectedFeature: _features[_selected]),
        const SizedBox(height: 32),
        ...List.generate(_features.length, (i) => _FeaturePoint(
          feature: _features[i],
          isSelected: i == _selected,
          onTap: () => setState(() => _selected = i),
        )),
      ],
    );
  }
}

class _AnimatedPhone extends StatelessWidget {
  const _AnimatedPhone({required this.selectedFeature});
  final _Feature selectedFeature;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: selectedFeature.color.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _PhoneContent(
            key: ValueKey(selectedFeature.caption),
            feature: selectedFeature,
          ),
        ),
      ),
    );
  }
}

class _PhoneContent extends StatelessWidget {
  const _PhoneContent({super.key, required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: feature.color.withValues(alpha: 0.12),
              border: Border.all(color: feature.color, width: 2),
            ),
            child: Icon(feature.icon, color: feature.color, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            feature.caption,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: feature.color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ...feature.pills.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: feature.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 12, color: feature.color),
                  const SizedBox(width: 6),
                  Text(p,
                      style: TextStyle(
                          fontSize: 11,
                          color: feature.color,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({
    required this.feature,
    required this.isSelected,
    required this.onTap,
  });

  final _Feature feature;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? feature.color.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? feature.color.withValues(alpha: 0.3)
                : const Color(0x1A000000),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(feature.icon, color: feature.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.caption,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: feature.color,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.title.replaceAll('\n', ' '),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 8),
                    Text(
                      feature.body,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.caption,
    required this.title,
    required this.body,
    required this.pills,
    required this.icon,
    required this.color,
  });
  final String caption, title, body;
  final List<String> pills;
  final IconData icon;
  final Color color;
}

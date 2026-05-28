import 'package:flutter/material.dart';

const Color _teal = Color(0xFF17C3B2);

class LandingDoctorFame extends StatefulWidget {
  const LandingDoctorFame({super.key, required this.isMobile});
  final bool isMobile;

  @override
  State<LandingDoctorFame> createState() => _LandingDoctorFameState();
}

class _LandingDoctorFameState extends State<LandingDoctorFame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lineCtrl;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    super.dispose();
  }

  static const _tiers = [
    _Tier('Rising', Color(0xFF8E8E93)),
    _Tier('Notable', Color(0xFF007AFF)),
    _Tier('Top Educator', _teal),
    _Tier('Fellow', Color(0xFFFFCC00)),
  ];

  static const _features = [
    _FeatureItem(Icons.video_camera_back_outlined, 'Post Rounds',
        'Share 60-second clinical videos with your following.', _teal),
    _FeatureItem(Icons.school_outlined, 'Host Sessions',
        'Teach in live 1-on-1 sessions. Earn from every call.', Color(0xFF007AFF)),
    _FeatureItem(Icons.verified_outlined, 'Fellow Badge',
        'Earn the MedGraph Fellow title. India\'s top educators.', Color(0xFFFFCC00)),
    _FeatureItem(Icons.trending_up_outlined, 'Leaderboard',
        'Climb the weekly rankings. Be known across India.', Color(0xFFFF9500)),
    _FeatureItem(Icons.people_outline, 'Build Following',
        'Students follow doctors they trust. Build yours.', Color(0xFFAF52DE)),
    _FeatureItem(Icons.currency_rupee_outlined, 'Earn Revenue',
        'Set your subscription price. Students pay monthly.', Color(0xFF34C759)),
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
            'FOR VERIFIED DOCTORS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _teal,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Post. Teach. Become famous.',
            style: TextStyle(
              fontSize: widget.isMobile ? 32 : 52,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 48),

          // Doctor profile card
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE5F3FF),
                            ),
                            child: const Center(
                              child: Text('RM',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF007AFF))),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF34C759),
                              ),
                              child: const Icon(Icons.verified,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dr. Rajesh Mehta',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              'Cardiologist · AIIMS Delhi',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF666666)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC00)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'MedGraph Fellow',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB8860B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0x1A000000)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('14.2K', 'Followers'),
                      Container(width: 0.5, height: 32, color: const Color(0x1A000000)),
                      _Stat('89', 'Posts'),
                      Container(width: 0.5, height: 32, color: const Color(0x1A000000)),
                      _Stat('₹4.2L', 'Earned'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('Follow',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0x1A000000)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('Subscribe ₹199',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 64),

          // Fame tier timeline
          const Text(
            'Your journey to Fellow',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 32),
          _FameTierTimeline(tiers: _tiers, lineCtrl: _lineCtrl),
          const SizedBox(height: 64),

          // 6-feature grid
          _FeatureGrid(features: _features, isMobile: widget.isMobile),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }
}

class _FameTierTimeline extends StatelessWidget {
  const _FameTierTimeline({required this.tiers, required this.lineCtrl});
  final List<_Tier> tiers;
  final AnimationController lineCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tiers.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: AnimatedBuilder(
              animation: lineCtrl,
              builder: (_, __) {
                final progress =
                    ((lineCtrl.value * (tiers.length - 1)) - (i ~/ 2))
                        .clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Container(height: 2, color: const Color(0xFFE5E5E5)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                          height: 2, color: _teal),
                    ),
                  ],
                );
              },
            ),
          );
        }
        final tier = tiers[i ~/ 2];
        return Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tier.color.withValues(alpha: 0.12),
                border: Border.all(color: tier.color, width: 2),
              ),
              child: Icon(Icons.star, color: tier.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              tier.name,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features, required this.isMobile});
  final List<_FeatureItem> features;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: isMobile ? 4 : 2,
      ),
      itemCount: features.length,
      itemBuilder: (_, i) {
        final f = features[i];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.icon, color: f.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(f.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    const SizedBox(height: 3),
                    Text(f.body,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tier {
  const _Tier(this.name, this.color);
  final String name;
  final Color color;
}

class _FeatureItem {
  const _FeatureItem(this.icon, this.title, this.body, this.color);
  final IconData icon;
  final String title, body;
  final Color color;
}

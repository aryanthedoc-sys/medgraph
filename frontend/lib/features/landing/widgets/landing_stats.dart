import 'package:flutter/material.dart';

class LandingStats extends StatefulWidget {
  const LandingStats({super.key, required this.scrollCtrl});
  final ScrollController scrollCtrl;

  @override
  State<LandingStats> createState() => _LandingStatsState();
}

class _LandingStatsState extends State<LandingStats> {
  final _key = GlobalKey();
  bool _visible = false;

  static const _stats = [
    _Stat('10,000+', 'Targeting interns', 10000),
    _Stat('2.3M', 'MBBS students in India', 2300000),
    _Stat('₹0', 'To start', 0),
    _Stat('54', 'Countries (MBBS system)', 54),
  ];

  @override
  void initState() {
    super.initState();
    widget.scrollCtrl.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (pos.dy < screenH) {
      setState(() => _visible = true);
      widget.scrollCtrl.removeListener(_checkVisibility);
    }
  }

  @override
  void dispose() {
    widget.scrollCtrl.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Container(
      key: _key,
      color: const Color(0xFFF5F5F7),
      child: Column(
        children: [
          Container(height: 0.5, color: const Color(0x1A000000)),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 48,
              horizontal: isMobile ? 20 : 80,
            ),
            child: isMobile
                ? Column(
                    children: List.generate(_stats.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        return Container(
                            height: 0.5,
                            color: const Color(0x1A000000),
                            margin: const EdgeInsets.symmetric(vertical: 24));
                      }
                      return _StatItem(stat: _stats[i ~/ 2], visible: _visible);
                    }),
                  )
                : IntrinsicHeight(
                    child: Row(
                      children: List.generate(_stats.length * 2 - 1, (i) {
                        if (i.isOdd) {
                          return Container(
                              width: 0.5,
                              color: const Color(0x1A000000),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 32));
                        }
                        return Expanded(
                          child: _StatItem(
                              stat: _stats[i ~/ 2], visible: _visible),
                        );
                      }),
                    ),
                  ),
          ),
          Container(height: 0.5, color: const Color(0x1A000000)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat, required this.visible});
  final _Stat stat;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (visible)
          TweenAnimationBuilder<double>(
            key: ValueKey('stat_${stat.label}'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeOut,
            builder: (_, t, __) => Text(
              stat.animatedLabel(t),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -1,
              ),
            ),
          )
        else
          const Text('—',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
        const SizedBox(height: 8),
        Text(
          stat.label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Stat {
  const _Stat(this.display, this.label, this.numericValue);
  final String display;
  final String label;
  final double numericValue;

  String animatedLabel(double t) {
    if (display.startsWith('₹')) return display;
    if (display.contains('M')) return display;
    if (display.contains('+')) {
      final val = (numericValue * t).round();
      return '${_fmt(val)}+';
    }
    return '${(numericValue * t).round()}';
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n ~/ 1000)},${(n % 1000).toString().padLeft(3, '0')}';
    return '$n';
  }
}

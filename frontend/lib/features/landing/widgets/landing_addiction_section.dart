import 'package:flutter/material.dart';

class LandingAddictionSection extends StatelessWidget {
  const LandingAddictionSection({super.key, required this.isMobile});
  final bool isMobile;

  static const _teal = Color(0xFF17C3B2);

  static const _items = [
    _Item('1', Icons.casino_outlined, 'Roulette hook',
        'One tap. Someone appears. You can\'t stop at just one.', _teal),
    _Item('2', Icons.play_circle_outlined, 'Rounds scroll',
        '60-second clinical videos. Always one more to watch.', Color(0xFF007AFF)),
    _Item('3', Icons.local_fire_department_outlined, 'Streak loss aversion',
        'Don\'t break your streak. 11 days means something.', Color(0xFFFF9500)),
    _Item('4', Icons.timer_outlined, 'NEET PG countdown',
        'Every day that passes is one fewer day to prepare.', Color(0xFFFF6B35)),
    _Item('5', Icons.emoji_events_outlined, 'Leaderboard identity',
        'Your rank means something. Your city is watching.', Color(0xFFFFCC00)),
    _Item('6', Icons.quiz_outlined, 'MCQ of the day',
        'One question. Every day. Your clinical instinct sharpens.', Color(0xFFAF52DE)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isMobile ? 20 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENGINEERED FOR CONSISTENCY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _teal,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Six reasons you open it every day.',
            style: TextStyle(
              fontSize: isMobile ? 28 : 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: isMobile ? 3.5 : 2.5,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) => _ItemCard(item: _items[i]),
          ),
          const SizedBox(height: 64),
          // Stats row
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: isMobile
                ? Column(
                    children: [
                      _StatRow('Average session', '28 min'),
                      const SizedBox(height: 16),
                      _StatRow('Daily return rate', '71%'),
                      const SizedBox(height: 16),
                      _StatRow('Streak average', '11 days'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatRow('Average session', '28 min'),
                      Container(
                          width: 0.5,
                          height: 48,
                          color: Colors.white.withValues(alpha: 0.15)),
                      _StatRow('Daily return rate', '71%'),
                      Container(
                          width: 0.5,
                          height: 48,
                          color: Colors.white.withValues(alpha: 0.15)),
                      _StatRow('Streak average', '11 days'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          // Large faded number
          Positioned(
            right: -8, top: -12,
            child: Text(
              item.number,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.03),
                height: 1,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

class _Item {
  const _Item(this.number, this.icon, this.title, this.body, this.color);
  final String number, title, body;
  final IconData icon;
  final Color color;
}

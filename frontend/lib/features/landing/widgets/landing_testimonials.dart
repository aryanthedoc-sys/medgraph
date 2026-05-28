import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Color _teal = Color(0xFF17C3B2);

class LandingTestimonials extends StatefulWidget {
  const LandingTestimonials({super.key, required this.isMobile});
  final bool isMobile;

  @override
  State<LandingTestimonials> createState() => _LandingTestimonialsState();
}

class _LandingTestimonialsState extends State<LandingTestimonials>
    with TickerProviderStateMixin {
  late final AnimationController _row1Ctrl;
  late final AnimationController _row2Ctrl;

  static const _cards = [
    _Card(
      '"Found my study group through MedGraph. Cleared NEET PG on first attempt."',
      'Priya Sharma',
      'MBBS 4th Year · AIIMS Delhi',
      true,
    ),
    _Card(
      '"The roulette feature is genuinely addictive. I study twice as much now."',
      'Arjun Nair',
      'MBBS 3rd Year · JIPMER',
      false,
    ),
    _Card(
      '"Built 12K followers in 6 months. My teaching income is real now."',
      'Dr. Kavitha Rao',
      'Cardiologist · Apollo Bangalore',
      true,
    ),
    _Card(
      '"MCQ of the day keeps me sharp even during internship madness."',
      'Rohit Desai',
      'Intern · Grant Medical College',
      false,
    ),
    _Card(
      '"Finally a platform that understands what MBBS life actually looks like."',
      'Sneha Patel',
      'MBBS 5th Year · BHU',
      false,
    ),
    _Card(
      '"Streak system made me consistent for the first time in 3 years."',
      'Vikram Singh',
      'MBBS 2nd Year · Maulana Azad',
      false,
    ),
    _Card(
      '"Connected with a senior who mentored me through my surgery postings."',
      'Divya Menon',
      'MBBS 3rd Year · Kasturba Medical',
      true,
    ),
    _Card(
      '"The verified doctor tag changed how students interact with my content."',
      'Dr. Suresh Kumar',
      'Neurologist · NIMHANS',
      true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _row1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _row2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _row1Ctrl.dispose();
    _row2Ctrl.dispose();
    super.dispose();
  }

  // Each card is 280px wide + 20px gap = 300px; 8 cards total
  static const _cardWidth = 300.0;
  static const _totalWidth = 8 * _cardWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: EdgeInsets.symmetric(vertical: 80,
          horizontal: widget.isMobile ? 0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 20 : 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMMUNITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'From the people using it.',
                  style: TextStyle(
                    fontSize: widget.isMobile ? 32 : 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Row 1: scroll left
          _TickerRow(
            ctrl: _row1Ctrl,
            cards: _cards,
            totalWidth: _totalWidth,
            reverse: false,
          ),
          const SizedBox(height: 20),
          // Row 2: scroll right
          _TickerRow(
            ctrl: _row2Ctrl,
            cards: [..._cards.reversed],
            totalWidth: _totalWidth,
            reverse: true,
          ),
        ],
      ),
    );
  }
}

class _TickerRow extends StatefulWidget {
  const _TickerRow({
    required this.ctrl,
    required this.cards,
    required this.totalWidth,
    required this.reverse,
  });

  final AnimationController ctrl;
  final List<_Card> cards;
  final double totalWidth;
  final bool reverse;

  @override
  State<_TickerRow> createState() => _TickerRowState();
}

class _TickerRowState extends State<_TickerRow> {
  @override
  Widget build(BuildContext context) {
    final ticker = MouseRegion(
      onEnter: kIsWeb ? (_) => widget.ctrl.stop() : null,
      onExit: kIsWeb ? (_) => widget.ctrl.repeat() : null,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: widget.ctrl,
          builder: (_, __) {
            final offset = widget.reverse
                ? -(widget.totalWidth -
                    widget.ctrl.value * widget.totalWidth)
                : -(widget.ctrl.value * widget.totalWidth);
            return OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.cards.map((c) => _TestimonialCard(card: c)),
                    // Duplicate for seamless loop
                    ...widget.cards.map((c) => _TestimonialCard(card: c)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    return SizedBox(
      height: 180,
      child: ticker,
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.card});
  final _Card card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              card.quote,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF333333),
                height: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    card.name[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _teal,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                        ),
                        if (card.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 12, color: Color(0xFF34C759)),
                        ],
                      ],
                    ),
                    Text(
                      card.college,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999999)),
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

class _Card {
  const _Card(this.quote, this.name, this.college, this.verified);
  final String quote, name, college;
  final bool verified;
}

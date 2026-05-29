import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _teal = Color(0xFF00C7BE);

class LandingEarlyAccess extends StatelessWidget {
  const LandingEarlyAccess({super.key, required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isMobile ? 20 : 80,
      ),
      child: Stack(
        children: [
          // Gradient orbs
          Positioned(
            top: -80, left: -80,
            child: _Orb(size: 400, color: _teal.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -60, right: -60,
            child: _Orb(size: 350, color: const Color(0xFF007AFF).withValues(alpha: 0.06)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const Text(
                    'Join MedGraph today',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Free to start. No credit card. No download.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '🎁 First 500 members get 3 months Pro free',
                    style: TextStyle(
                      fontSize: 14,
                      color: _teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(980),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create free account →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 5 * 28.0 - 4 * 8.0,
                        height: 32,
                        child: Stack(
                          children: List.generate(5, (i) => Positioned(
                            left: i * 20.0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: [
                                  const Color(0xFFFFB347),
                                  const Color(0xFF87CEEB),
                                  const Color(0xFF98FB98),
                                  const Color(0xFFDDA0DD),
                                  const Color(0xFFF08080),
                                ][i],
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  ['D', 'A', 'R', 'P', 'S'][i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Join 2,400+ medical professionals',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

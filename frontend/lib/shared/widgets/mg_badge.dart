import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum BadgeType { verified, pro, rising, notable, topEducator, fellow }

/// Small pill badge used for verification status and fame tiers.
class MGBadge extends StatelessWidget {
  const MGBadge({super.key, required this.type});

  final BadgeType type;

  @override
  Widget build(BuildContext context) {
    final config = _config[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 10, color: config.fg),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTextStyles.caption.copyWith(
              color: config.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static final _config = {
    BadgeType.verified: _BadgeConfig(
      label: 'Verified',
      icon: Icons.verified_outlined,
      bg: AppColors.verifiedGreen.withValues(alpha: 0.15),
      fg: AppColors.verifiedGreen,
    ),
    BadgeType.pro: _BadgeConfig(
      label: 'Pro',
      icon: Icons.star,
      bg: AppColors.proGold.withValues(alpha: 0.15),
      fg: AppColors.proGold,
    ),
    BadgeType.rising: _BadgeConfig(
      label: 'Rising',
      icon: Icons.trending_up,
      bg: const Color(0xFF007AFF).withValues(alpha: 0.15),
      fg: const Color(0xFF007AFF),
    ),
    BadgeType.notable: _BadgeConfig(
      label: 'Notable',
      icon: Icons.auto_awesome,
      bg: const Color(0xFFAF52DE).withValues(alpha: 0.15),
      fg: const Color(0xFFAF52DE),
    ),
    BadgeType.topEducator: _BadgeConfig(
      label: 'Top Educator',
      icon: Icons.school,
      bg: AppColors.warning.withValues(alpha: 0.15),
      fg: AppColors.warning,
    ),
    BadgeType.fellow: _BadgeConfig(
      label: 'MedGraph Fellow',
      icon: Icons.workspace_premium,
      bg: AppColors.proGold.withValues(alpha: 0.2),
      fg: AppColors.proGold,
    ),
  };
}

class _BadgeConfig {
  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}

/// Standalone verified badge shown under profile names.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, required this.isDoctor});
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    return const MGBadge(type: BadgeType.verified);
  }
}

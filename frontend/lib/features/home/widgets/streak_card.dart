import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_card.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak, required this.sessionsToday});

  final int streak;
  final int sessionsToday;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final hasStreak = streak > 0;

    return MGCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasStreak
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: hasStreak ? 24 : 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0 ? '$streak day streak' : 'Start your streak',
                  style: AppTextStyles.headline.copyWith(color: text),
                ),
                Text(
                  sessionsToday > 0
                      ? 'Keep it up — $sessionsToday session${sessionsToday > 1 ? "s" : ""} today'
                      : 'Start today to keep your streak alive',
                  style: AppTextStyles.footnote.copyWith(color: sub),
                ),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔥 $streak',
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

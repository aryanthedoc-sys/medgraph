import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text('I am a', style: AppTextStyles.largeTitle.copyWith(color: text)),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to join MedGraph.',
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                ),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                title: 'Medical Student',
                subtitle: 'MBBS, BDS, BAMS or equivalent',
                icon: Icons.school_outlined,
                onTap: () => context.go('/register/student'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Doctor / Consultant',
                subtitle: 'Verified practitioner with MRN',
                icon: Icons.local_hospital_outlined,
                onTap: () => context.go('/register/doctor'),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSecondary
                          : AppColors.lightSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/legal/terms'),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/legal/privacy'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: text, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline.copyWith(color: text)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.footnote.copyWith(color: sub)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: sub),
          ],
        ),
      ),
    );
  }
}

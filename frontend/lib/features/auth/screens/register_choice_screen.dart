import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RegisterChoiceScreen extends StatefulWidget {
  const RegisterChoiceScreen({super.key});

  @override
  State<RegisterChoiceScreen> createState() => _RegisterChoiceScreenState();
}

class _RegisterChoiceScreenState extends State<RegisterChoiceScreen> {
  String? _selected;

  static const _roles = [
    _RoleOption(
      value: 'student_mbbs',
      title: 'MBBS Student',
      subtitle: 'Bachelor of Medicine and Surgery',
      icon: Icons.medical_services_outlined,
    ),
    _RoleOption(
      value: 'student_bds',
      title: 'BDS Student',
      subtitle: 'Bachelor of Dental Surgery',
      icon: Icons.medical_information_outlined,
    ),
    _RoleOption(
      value: 'student_bams',
      title: 'BAMS Student',
      subtitle: 'Ayurvedic Medicine and Surgery',
      icon: Icons.local_pharmacy_outlined,
    ),
    _RoleOption(
      value: 'doctor',
      title: 'Doctor',
      subtitle: 'Verified practitioner with NMC registration',
      icon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? Colors.black : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final sub  = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text('I am a', style: AppTextStyles.largeTitle.copyWith(color: text)),
                    const SizedBox(height: 6),
                    Text(
                      'Choose your role to get started on MedGraph.',
                      style: AppTextStyles.body.copyWith(color: sub),
                    ),
                    const SizedBox(height: 32),

                    // Role cards
                    ...(_roles.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoleCard(
                        option: role,
                        isSelected: _selected == role.value,
                        onTap: () => setState(() => _selected = role.value),
                      ),
                    ))),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selected != null ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: AppTextStyles.headline.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/onboarding'),
                        child: Text(
                          'Already have an account? Sign in',
                          style: TextStyle(color: sub),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 13, color: sub),
                          children: [
                            const TextSpan(text: 'By continuing you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push('/legal/terms'),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push('/legal/privacy'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _continue() {
    if (_selected == null) return;
    context.go('/register/unified', extra: _selected);
  }
}

class _RoleOption {
  const _RoleOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });
  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkSurface  : AppColors.lightSurface;
    final textCol  = isDark ? Colors.white            : Colors.black;
    final sub      = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.teal : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? AppColors.teal : textCol,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title,
                      style: AppTextStyles.headline.copyWith(
                        color: isSelected ? AppColors.teal : textCol,
                      )),
                  const SizedBox(height: 3),
                  Text(option.subtitle,
                      style: AppTextStyles.footnote.copyWith(color: sub)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.teal, size: 22)
            else
              Icon(Icons.chevron_right, color: sub),
          ],
        ),
      ),
    );
  }
}

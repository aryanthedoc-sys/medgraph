import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_text_field.dart';
import '../../../shared/services/api_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _cityCtr = TextEditingController();
  final _bioCtr = TextEditingController();
  int? _academicYear;
  bool _loading = false;
  String? _error;

  static const _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', 'Intern', 'Postgraduate'];

  @override
  void dispose() {
    _cityCtr.dispose();
    _bioCtr.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() { _error = null; _loading = true; });
    try {
      await ApiService.post('/api/auth/complete-profile', {
        'academicYear': _academicYear,
        'city': _cityCtr.text.trim(),
        'bio': _bioCtr.text.trim(),
      });
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Almost there!', style: AppTextStyles.title1.copyWith(color: text)),
              const SizedBox(height: 8),
              Text(
                'A few more details to personalise your experience.',
                style: AppTextStyles.body.copyWith(color: sub),
              ),
              const SizedBox(height: 32),
              Text('Academic Year', style: AppTextStyles.headline.copyWith(color: text)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_years.length, (i) {
                  final isSelected = _academicYear == i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _academicYear = i + 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? text : surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _years[i],
                        style: AppTextStyles.subheadline.copyWith(
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : text,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              MGTextField(
                hint: 'City',
                controller: _cityCtr,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              MGTextField(
                hint: 'Short bio (optional, 300 chars)',
                controller: _bioCtr,
                maxLines: 3,
                maxLength: 300,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                ),
              ],
              const SizedBox(height: 32),
              MGButton(
                label: 'Complete profile',
                onPressed: _complete,
                isLoading: _loading,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text('Skip for now', style: TextStyle(color: sub)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

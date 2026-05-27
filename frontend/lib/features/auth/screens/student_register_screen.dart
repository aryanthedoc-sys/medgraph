import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_text_field.dart';
import '../../../shared/services/api_service.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    super.dispose();
  }

  bool get _isValidEmail {
    final e = _emailCtr.text.trim().toLowerCase();
    return e.contains('@') &&
        (e.endsWith('.ac.in') || e.endsWith('.edu') || e.contains('.edu.'));
  }

  Future<void> _continue() async {
    setState(() { _error = null; _loading = true; });
    try {
      await ApiService.post('/api/auth/send-otp', {
        'email': _emailCtr.text.trim().toLowerCase(),
        'name': _nameCtr.text.trim(),
        'role': 'student',
      });
      if (!mounted) return;
      context.go('/register/otp', extra: _emailCtr.text.trim().toLowerCase());
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        leading: BackButton(onPressed: () => context.go('/register')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Medical Student',
                style: AppTextStyles.title1.copyWith(color: text),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your college email to verify you\'re a medical student.',
                style: AppTextStyles.body.copyWith(color: sub),
              ),
              const SizedBox(height: 32),
              MGTextField(
                hint: 'Full name',
                controller: _nameCtr,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              MGTextField(
                hint: 'College email (.ac.in or .edu)',
                controller: _emailCtr,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _isValidEmail && _nameCtr.text.isNotEmpty
                    ? _continue()
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: sub),
                  const SizedBox(width: 6),
                  Text(
                    'Must be your .ac.in or .edu email',
                    style: AppTextStyles.footnote.copyWith(color: sub),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.danger),
                  ),
                ),
              ],
              const Spacer(),
              MGButton(
                label: 'Send verification code',
                onPressed: _isValidEmail && _nameCtr.text.trim().isNotEmpty
                    ? _continue
                    : null,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_text_field.dart';
import '../../../shared/services/api_service.dart';

// Unified registration screen for all user types.
// The userType is passed via GoRouter's `extra` parameter.
class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key, this.userType});
  final String? userType;

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _nameCtr        = TextEditingController();
  final _emailCtr       = TextEditingController();
  final _collegeCtr     = TextEditingController();
  final _cityCtr        = TextEditingController();
  final _universityCtr  = TextEditingController();
  final _specialtyCtr   = TextEditingController();
  final _nmcCtr         = TextEditingController();
  final _expCtr         = TextEditingController();

  String? _yearOfStudy;
  String? _collegeState;
  bool _loading = false;
  String? _error;

  String get _userType => widget.userType ?? 'student_mbbs';

  bool get _isDoctor => _userType == 'doctor';
  bool get _isStudent => !_isDoctor;

  @override
  void dispose() {
    for (final c in [
      _nameCtr, _emailCtr, _collegeCtr, _cityCtr,
      _universityCtr, _specialtyCtr, _nmcCtr, _expCtr,
    ]) { c.dispose(); }
    super.dispose();
  }

  static const _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Intern'];

  static const _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
  ];

  static const _specialties = [
    'General Medicine', 'Surgery', 'Pediatrics', 'Gynecology', 'Cardiology',
    'Orthopedics', 'Dermatology', 'Ophthalmology', 'ENT', 'Psychiatry',
    'Radiology', 'Anesthesia', 'Nephrology', 'Urology', 'Gastroenterology',
    'Endocrinology', 'Pulmonology', 'Rheumatology', 'Oncology', 'Other',
  ];

  String get _roleTitle {
    switch (_userType) {
      case 'student_mbbs': return 'MBBS Student';
      case 'student_bds':  return 'BDS Student';
      case 'student_bams': return 'BAMS Student';
      case 'doctor':       return 'Doctor';
      default: return 'Create account';
    }
  }

  bool get _canSubmit {
    if (_nameCtr.text.trim().isEmpty) return false;
    if (!_isValidEmail) return false;
    if (_isStudent) {
      return _collegeCtr.text.trim().isNotEmpty &&
          _yearOfStudy != null;
    } else {
      return _specialtyCtr.text.trim().isNotEmpty &&
          _nmcCtr.text.trim().isNotEmpty;
    }
  }

  bool get _isValidEmail {
    final e = _emailCtr.text.trim().toLowerCase();
    return e.contains('@') && e.contains('.');
  }

  Future<void> _continue() async {
    setState(() { _error = null; _loading = true; });
    try {
      final body = <String, dynamic>{
        'email':    _emailCtr.text.trim().toLowerCase(),
        'name':     _nameCtr.text.trim(),
        'userType': _userType,
      };

      if (_isStudent) {
        body['collegeName']  = _collegeCtr.text.trim();
        body['collegeCity']  = _cityCtr.text.trim();
        body['collegeState'] = _collegeState ?? '';
        body['university']   = _universityCtr.text.trim();
        body['yearOfStudy']  = _yearOfStudy ?? '';
      } else {
        body['specialty']       = _specialtyCtr.text.trim();
        body['nmcNumber']       = _nmcCtr.text.trim();
        body['yearsExperience'] = _expCtr.text.trim();
      }

      await ApiService.post('/api/auth/send-otp', body);
      if (!mounted) return;
      context.go('/register/otp', extra: {
        'email':    _emailCtr.text.trim().toLowerCase(),
        'name':     _nameCtr.text.trim(),
        'userType': _userType,
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach server. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub  = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_roleTitle),
        leading: BackButton(onPressed: () => context.go('/register')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_roleTitle, style: AppTextStyles.title1.copyWith(color: text)),
              const SizedBox(height: 6),
              Text(
                _isStudent
                    ? 'Fill in your details. Any email address is accepted.'
                    : 'Enter your professional details for verification.',
                style: AppTextStyles.body.copyWith(color: sub),
              ),
              const SizedBox(height: 28),

              // ── Common fields ──────────────────────────
              MGTextField(
                hint: 'Full name',
                controller: _nameCtr,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              MGTextField(
                hint: 'Email address',
                controller: _emailCtr,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              if (_isStudent) ..._buildStudentFields(isDark, text, sub),
              if (_isDoctor)  ..._buildDoctorFields(isDark, text, sub),

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

              const SizedBox(height: 28),
              MGButton(
                label: 'Send verification code',
                onPressed: _canSubmit ? _continue : null,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields(bool isDark, Color text, Color sub) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor  = isDark ? AppColors.darkBorder  : AppColors.lightBorder;

    return [
      _SectionLabel(text: 'College details', color: sub),
      const SizedBox(height: 10),
      MGTextField(
        hint: 'College name',
        controller: _collegeCtr,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      MGTextField(
        hint: 'City',
        controller: _cityCtr,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),

      // State dropdown
      Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _collegeState,
            hint: Text('State', style: TextStyle(color: sub)),
            isExpanded: true,
            dropdownColor: surfaceColor,
            items: _indianStates.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: TextStyle(color: text)),
            )).toList(),
            onChanged: (v) => setState(() => _collegeState = v),
          ),
        ),
      ),
      const SizedBox(height: 12),

      MGTextField(
        hint: 'University / Affiliation',
        controller: _universityCtr,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),

      _SectionLabel(text: 'Year of study', color: sub),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _years.map((y) {
          final sel = _yearOfStudy == y;
          return GestureDetector(
            onTap: () => setState(() => _yearOfStudy = y),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? AppColors.teal : borderColor,
                  width: sel ? 1.5 : 0.5,
                ),
              ),
              child: Text(y,
                  style: AppTextStyles.footnote.copyWith(
                    color: sel ? Colors.white : text,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildDoctorFields(bool isDark, Color text, Color sub) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor  = isDark ? AppColors.darkBorder  : AppColors.lightBorder;

    return [
      _SectionLabel(text: 'Professional details', color: sub),
      const SizedBox(height: 10),

      // Specialty dropdown
      Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _specialtyCtr.text.isEmpty ? null : _specialtyCtr.text,
            hint: Text('Specialty', style: TextStyle(color: sub)),
            isExpanded: true,
            dropdownColor: surfaceColor,
            items: _specialties.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: TextStyle(color: text)),
            )).toList(),
            onChanged: (v) => setState(() => _specialtyCtr.text = v ?? ''),
          ),
        ),
      ),
      const SizedBox(height: 12),

      MGTextField(
        hint: 'NMC Registration Number',
        controller: _nmcCtr,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      MGTextField(
        hint: 'Years of experience',
        controller: _expCtr,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 8),

      // Disclaimer for doctors
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.teal, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Doctor accounts require NMC verification. You\'ll be asked to upload proof on the next screen.',
                style: AppTextStyles.footnote.copyWith(color: AppColors.teal),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: color,
    ),
  );
}

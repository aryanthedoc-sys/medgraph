import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_text_field.dart';
import '../../../shared/services/api_service.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _mrnCtr = TextEditingController();
  final _hospitalCtr = TextEditingController();
  String? _specialty;
  int _yearsExp = 0;
  String? _docPhotoPath;
  bool _loading = false;
  String? _error;
  bool _professionalDisclaimer = false;

  static const _specialties = [
    'General Medicine', 'Surgery', 'Paediatrics', 'Obstetrics & Gynaecology',
    'Cardiology', 'Neurology', 'Orthopaedics', 'Psychiatry', 'Dermatology',
    'ENT', 'Ophthalmology', 'Anaesthesia', 'Radiology', 'Pathology',
    'Community Medicine', 'Emergency Medicine', 'Nephrology', 'Oncology',
    'Endocrinology', 'Gastroenterology', 'Pulmonology', 'Rheumatology',
    'Urology', 'Haematology', 'Infectious Disease', 'Other',
  ];

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _mrnCtr.dispose();
    _hospitalCtr.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _docPhotoPath = file.path);
  }

  bool get _canSubmit =>
      _nameCtr.text.trim().isNotEmpty &&
      _emailCtr.text.trim().isNotEmpty &&
      _mrnCtr.text.trim().isNotEmpty &&
      _specialty != null &&
      _docPhotoPath != null &&
      _professionalDisclaimer;

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; });
    try {
      await ApiService.post('/api/auth/register-doctor', {
        'email': _emailCtr.text.trim().toLowerCase(),
        'fullName': _nameCtr.text.trim(),
        'mrn': _mrnCtr.text.trim(),
        'specialty': _specialty,
        'hospital': _hospitalCtr.text.trim(),
        'yearsExperience': _yearsExp,
        'idPhotoUrl': _docPhotoPath ?? '',
      });
      if (!mounted) return;
      _showPendingDialog();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Profile Under Review',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Your profile is under review.\n\nWe verify all doctors within 24 hours. You will receive an email once approved.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        leading: BackButton(onPressed: () => context.go('/register')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor / Consultant', style: AppTextStyles.title1.copyWith(color: text)),
              const SizedBox(height: 8),
              Text(
                'All doctors are manually verified by our team within 24 hours.',
                style: AppTextStyles.body.copyWith(color: sub),
              ),
              const SizedBox(height: 32),
              MGTextField(hint: 'Full name', controller: _nameCtr, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              MGTextField(hint: 'Email address', controller: _emailCtr, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              MGTextField(hint: 'MCI/NMC Registration Number', controller: _mrnCtr, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              MGTextField(hint: 'Hospital / Clinic (optional)', controller: _hospitalCtr, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              // Specialty dropdown
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _specialty,
                    hint: Text('Select specialty', style: TextStyle(color: sub)),
                    isExpanded: true,
                    dropdownColor: surface,
                    items: _specialties.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: TextStyle(color: text)),
                    )).toList(),
                    onChanged: (v) => setState(() => _specialty = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Years experience slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Years of experience: $_yearsExp',
                      style: AppTextStyles.subheadline.copyWith(color: sub)),
                  Slider(
                    value: _yearsExp.toDouble(),
                    min: 0,
                    max: 40,
                    divisions: 40,
                    activeColor: text,
                    inactiveColor: surface,
                    onChanged: (v) => setState(() => _yearsExp = v.round()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Document upload
              GestureDetector(
                onTap: _pickDocument,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _docPhotoPath != null
                          ? AppColors.success
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: _docPhotoPath != null ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _docPhotoPath != null ? Icons.check_circle : Icons.upload_file_outlined,
                        color: _docPhotoPath != null ? AppColors.success : sub,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _docPhotoPath != null ? 'Document uploaded' : 'Upload verification document',
                              style: AppTextStyles.subheadline.copyWith(color: text),
                            ),
                            Text(
                              'Degree certificate, Hospital ID, or NMC certificate',
                              style: AppTextStyles.caption.copyWith(color: sub),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
              const SizedBox(height: 24),
              // Professional responsibility disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        const Text(
                          'Professional Responsibility',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'As a registered medical practitioner on MedGraph, you confirm:\n'
                      '• All case discussions are purely educational\n'
                      '• You will not use MedGraph to establish doctor-patient relationships\n'
                      '• You accept personal professional liability for advice given as a medical practitioner',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: _professionalDisclaimer,
                onChanged: (v) =>
                    setState(() => _professionalDisclaimer = v ?? false),
                activeColor: isDark ? Colors.white : Colors.black,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I understand my professional responsibilities on this platform',
                  style: AppTextStyles.subheadline.copyWith(color: text),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              MGButton(
                label: 'Submit for review',
                onPressed: _canSubmit ? _submit : null,
                isLoading: _loading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

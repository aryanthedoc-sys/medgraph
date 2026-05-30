import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/mg_button.dart';

class ProofUploadScreen extends ConsumerStatefulWidget {
  const ProofUploadScreen({super.key});

  @override
  ConsumerState<ProofUploadScreen> createState() => _ProofUploadScreenState();
}

class _ProofUploadScreenState extends ConsumerState<ProofUploadScreen> {
  PlatformFile? _file;
  bool _uploading = false;
  bool _uploaded  = false;
  String? _error;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        final ext = f.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'pdf'].contains(ext)) {
          setState(() => _error = 'Please upload a JPG, PNG or PDF file.');
          return;
        }
        if (f.size > 5 * 1024 * 1024) {
          setState(() => _error = 'File too large. Maximum 5MB allowed.');
          return;
        }
        setState(() { _file = f; _error = null; });
      }
    } catch (e) {
      setState(() => _error = 'Could not open file picker: $e');
    }
  }

  Future<void> _upload() async {
    if (_file == null) return;
    setState(() { _uploading = true; _error = null; });
    try {
      await ApiService.uploadFile(
        path: '/api/auth/upload-proof',
        fieldName: 'file',
        filename: _file!.name,
        fileBytes: _file!.bytes ?? Uint8List(0),
        mimeType: _mimeType(_file!.name),
      );
      setState(() { _uploaded = true; _uploading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _uploading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _uploading = false; });
    }
  }

  String _mimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'png':  return 'image/png';
      default:     return 'image/jpeg';
    }
  }

  void _goHome() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bg     = isDark ? Colors.black : Colors.white;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_uploaded) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.teal, size: 44),
                ),
                const SizedBox(height: 24),
                Text('Proof uploaded!',
                    style: AppTextStyles.title1.copyWith(color: text),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Our medical team will review your credentials within 24 hours. '
                  'You have full access to MedGraph while we verify.',
                  style: AppTextStyles.body.copyWith(color: sub),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                MGButton(label: 'Start using MedGraph', onPressed: _goHome),
              ],
            ),
          ),
        ),
      );
    }

    final isStudent = !(user?.isDoctor ?? false);
    final uploadHint = isStudent
        ? 'Upload your college ID card or marksheet'
        : 'Upload your degree certificate or NMC registration card';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: BackButton(
          onPressed: () => context.go('/home'),
          color: text,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your credentials',
                  style: AppTextStyles.title1.copyWith(color: text)),
              const SizedBox(height: 8),
              Text(uploadHint,
                  style: AppTextStyles.body.copyWith(color: sub)),
              const SizedBox(height: 32),

              // Upload box
              GestureDetector(
                onTap: _uploading ? null : _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _file != null
                        ? AppColors.teal.withValues(alpha: 0.06)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _file != null ? AppColors.teal : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: _file != null ? 1.5 : 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    // dashed border via custom paint would be ideal, but we use solid here
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _file != null ? Icons.insert_drive_file_outlined : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _file != null ? AppColors.teal : sub,
                      ),
                      const SizedBox(height: 12),
                      if (_file != null) ...[
                        Text(_file!.name,
                            style: AppTextStyles.headline.copyWith(color: text),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(
                          '${(_file!.size / 1024).toStringAsFixed(0)} KB — tap to change',
                          style: AppTextStyles.footnote.copyWith(color: sub),
                        ),
                      ] else ...[
                        Text('Tap to upload',
                            style: AppTextStyles.headline.copyWith(color: text)),
                        const SizedBox(height: 4),
                        Text('JPG, PNG or PDF · Max 5 MB',
                            style: AppTextStyles.footnote.copyWith(color: sub)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'JPG, PNG or PDF · Maximum 5MB',
                  style: AppTextStyles.caption.copyWith(color: sub),
                ),
              ),
              const SizedBox(height: 20),

              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your documents are reviewed by our medical team within 24 hours. '
                        'You have immediate access to MedGraph while we verify.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A5600),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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

              const SizedBox(height: 28),

              MGButton(
                label: _uploading ? 'Uploading…' : 'Upload proof',
                onPressed: (_file != null && !_uploading) ? _upload : null,
                isLoading: _uploading,
              ),
              const SizedBox(height: 12),

              Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: _goHome,
                      child: Text('Skip for now',
                          style: AppTextStyles.body.copyWith(color: sub)),
                    ),
                    Text(
                      'You can upload proof later from your profile settings',
                      style: AppTextStyles.caption.copyWith(color: sub),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

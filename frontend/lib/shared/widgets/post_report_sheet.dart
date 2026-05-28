import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../services/api_service.dart';

class PostReportSheet extends StatefulWidget {
  const PostReportSheet({super.key, required this.postId});
  final String postId;

  @override
  State<PostReportSheet> createState() => _PostReportSheetState();
}

class _PostReportSheetState extends State<PostReportSheet> {
  String? _reason;
  bool _loading = false;
  bool _submitted = false;

  static const _reasons = [
    'Contains patient identifiers',
    'Medical misinformation',
    'Inappropriate content',
    'Fake doctor / unverified advice',
    'Spam',
  ];

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.post('/api/posts/${widget.postId}/report', {
        'reason': _reason,
      });
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _submitted ? _SuccessState(text: text) : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: sub.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Report this post', style: AppTextStyles.title3.copyWith(color: text)),
          const SizedBox(height: 4),
          Text(
            'Select the reason that best describes the issue.',
            style: AppTextStyles.footnote.copyWith(color: sub),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((r) => RadioListTile<String>(
            title: Text(r, style: AppTextStyles.subheadline.copyWith(color: text)),
            value: r,
            groupValue: _reason,
            activeColor: isDark ? Colors.white : Colors.black,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _reason = v),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _reason != null && !_loading ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                disabledBackgroundColor:
                    (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit report',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.text});
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: AppColors.success),
          const SizedBox(height: 16),
          Text('Report submitted',
              style: AppTextStyles.title3.copyWith(color: text)),
          const SizedBox(height: 8),
          Text(
            'We review within 24 hours.',
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.lightSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

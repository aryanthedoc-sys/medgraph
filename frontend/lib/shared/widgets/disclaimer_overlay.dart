import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum DisclaimerVariant { onboarding, videoCall, casePost, footer }

/// Multi-variant disclaimer overlay.
///
/// Usage by variant:
///   onboarding  → showDialog(builder: (_) => DisclaimerOverlay(variant: .onboarding))
///   videoCall   → include in Stack as a widget; passes onDismiss callback
///   casePost    → showModalBottomSheet(builder: (_) => DisclaimerOverlay(variant: .casePost, onConfirm: ...))
///   footer      → use inline as a small Text widget
class DisclaimerOverlay extends StatefulWidget {
  const DisclaimerOverlay({
    super.key,
    required this.variant,
    this.onConfirm,
    this.onDismiss,
  });

  final DisclaimerVariant variant;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;

  @override
  State<DisclaimerOverlay> createState() => _DisclaimerOverlayState();
}

class _DisclaimerOverlayState extends State<DisclaimerOverlay> {
  // onboarding
  bool _check1 = false;
  bool _check2 = false;
  bool _saving = false;

  // casePost
  bool _case1 = false;
  bool _case2 = false;
  bool _case3 = false;
  bool _case4 = false;

  // videoCall
  Timer? _autoDismissTimer;
  bool _videoDismissed = false;

  @override
  void initState() {
    super.initState();
    if (widget.variant == DisclaimerVariant.videoCall) {
      _autoDismissTimer = Timer(const Duration(seconds: 8), () {
        if (mounted && !_videoDismissed) {
          setState(() => _videoDismissed = true);
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptOnboarding() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.variant) {
      DisclaimerVariant.onboarding   => _OnboardingOverlay(
          check1: _check1,
          check2: _check2,
          saving: _saving,
          onCheck1: (v) => setState(() => _check1 = v ?? false),
          onCheck2: (v) => setState(() => _check2 = v ?? false),
          onAccept: _acceptOnboarding,
        ),
      DisclaimerVariant.videoCall    => _videoDismissed
          ? const SizedBox.shrink()
          : _VideoCallBanner(onDismiss: () {
              setState(() => _videoDismissed = true);
              widget.onDismiss?.call();
            }),
      DisclaimerVariant.casePost     => _CasePostSheet(
          c1: _case1, c2: _case2, c3: _case3, c4: _case4,
          onToggle1: (v) => setState(() => _case1 = v ?? false),
          onToggle2: (v) => setState(() => _case2 = v ?? false),
          onToggle3: (v) => setState(() => _case3 = v ?? false),
          onToggle4: (v) => setState(() => _case4 = v ?? false),
          onPost: _case1 && _case2 && _case3 && _case4
              ? () { Navigator.pop(context); widget.onConfirm?.call(); }
              : null,
          onCancel: () => Navigator.pop(context),
        ),
      DisclaimerVariant.footer       => _FooterText(
          onTap: () => context.push('/legal/terms'),
        ),
    };
  }
}

// ─── Onboarding full-screen overlay ────────────────────────────────────────────

class _OnboardingOverlay extends StatelessWidget {
  const _OnboardingOverlay({
    required this.check1,
    required this.check2,
    required this.saving,
    required this.onCheck1,
    required this.onCheck2,
    required this.onAccept,
  });

  final bool check1, check2, saving;
  final ValueChanged<bool?> onCheck1;
  final ValueChanged<bool?> onCheck2;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FFF8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF17C3B2), width: 1),
                    ),
                    child: const Text(
                      'IMPORTANT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17C3B2),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Before you continue',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'MedGraph is an educational platform for medical '
                      'students and doctors. It is NOT a telemedicine, '
                      'diagnostic, or clinical decision-making service.\n\n'
                      'Nothing shared on MedGraph constitutes medical '
                      'advice or creates a doctor-patient relationship.\n\n'
                      'You retain full professional liability for all '
                      'real-world clinical decisions.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    value: check1,
                    onChanged: onCheck1,
                    activeColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I understand MedGraph is educational and not a medical advice service',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: check2,
                    onChanged: onCheck2,
                    activeColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I will never share real patient identifiers including names, record numbers, or photos',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (check1 && check2 && !saving)
                          ? onAccept
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.black.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.white)))
                          : const Text('I understand — Continue',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/legal/terms'),
                        child: const Text('Terms',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                                decoration: TextDecoration.underline)),
                      ),
                      const Text('  ·  ',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF999999))),
                      GestureDetector(
                        onTap: () => context.push('/legal/privacy'),
                        child: const Text('Privacy',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Video call banner ──────────────────────────────────────────────────────────

class _VideoCallBanner extends StatelessWidget {
  const _VideoCallBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF856404)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Educational discussion only — not medical advice',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF664D03),
                  fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: Color(0xFF856404)),
          ),
        ],
      ),
    );
  }
}

// ─── Case post bottom sheet ─────────────────────────────────────────────────────

class _CasePostSheet extends StatelessWidget {
  const _CasePostSheet({
    required this.c1, required this.c2,
    required this.c3, required this.c4,
    required this.onToggle1, required this.onToggle2,
    required this.onToggle3, required this.onToggle4,
    required this.onPost,
    required this.onCancel,
  });

  final bool c1, c2, c3, c4;
  final ValueChanged<bool?> onToggle1, onToggle2, onToggle3, onToggle4;
  final VoidCallback? onPost;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 14, height: 1.4);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Before you post this case',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
          const SizedBox(height: 4),
          const Text(
            'Please confirm all of the following:',
            style: TextStyle(
                fontSize: 14, color: AppColors.lightSecondary),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: c1, onChanged: onToggle1,
            activeColor: Colors.black, contentPadding: EdgeInsets.zero,
            title: const Text('No real patient name included',
                style: textStyle),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: c2, onChanged: onToggle2,
            activeColor: Colors.black, contentPadding: EdgeInsets.zero,
            title: const Text('No hospital record or admission number',
                style: textStyle),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: c3, onChanged: onToggle3,
            activeColor: Colors.black, contentPadding: EdgeInsets.zero,
            title: const Text(
                'No identifying photos or dates of birth',
                style: textStyle),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: c4, onChanged: onToggle4,
            activeColor: Colors.black, contentPadding: EdgeInsets.zero,
            title: const Text(
                'This is for educational discussion only',
                style: textStyle),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.black.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text('Post case',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.lightSecondary)),
          ),
        ],
      ),
    );
  }
}

// ─── Footer variant ─────────────────────────────────────────────────────────────

class _FooterText extends StatelessWidget {
  const _FooterText({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'MedGraph is educational only. Not medical advice.',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.lightSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

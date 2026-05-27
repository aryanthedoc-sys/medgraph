import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/services/api_service.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.email});
  final String email;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCooldown <= 0) { t.cancel(); return; }
      setState(() => _resendCooldown--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete => _otp.length == 6;

  Future<void> _verify() async {
    setState(() { _error = null; _loading = true; });
    try {
      final res = await ApiService.post('/api/auth/verify-otp', {
        'email': widget.email,
        'otp': _otp,
      });
      // Sign in with the returned custom token via Supabase
      await Supabase.instance.client.auth.signInWithPassword(
        email: widget.email,
        password: res['tempPassword'] as String,
      );
      if (!mounted) return;
      final isNewUser = res['isNewUser'] as bool? ?? true;
      context.go(isNewUser ? '/register/profile-setup' : '/home');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resendCooldown = 30; _error = null; });
    _startCooldown();
    try {
      await ApiService.post('/api/auth/send-otp', {'email': widget.email});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/register/student'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Check your email', style: AppTextStyles.title1.copyWith(color: text)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body.copyWith(color: sub),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to '),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(color: text, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 6-box OTP input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OTPBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      _focusNodes[i + 1].requestFocus();
                    } else if (val.isEmpty && i > 0) {
                      _focusNodes[i - 1].requestFocus();
                    }
                    setState(() {});
                    if (_isComplete) _verify();
                  },
                )),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.footnote.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: _resendCooldown > 0
                    ? Text(
                        'Resend code in ${_resendCooldown}s',
                        style: AppTextStyles.footnote.copyWith(color: sub),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: Text('Resend code', style: TextStyle(color: text)),
                      ),
              ),
              const Spacer(),
              MGButton(
                label: 'Verify',
                onPressed: _isComplete ? _verify : null,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OTPBox extends StatelessWidget {
  const _OTPBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? Colors.white : Colors.black;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          // Handle paste of full OTP
          if (val.length > 1) {
            onChanged(val[0]);
          } else {
            onChanged(val);
          }
        },
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: bg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: text, width: 1.5),
          ),
        ),
      ),
    );
  }
}

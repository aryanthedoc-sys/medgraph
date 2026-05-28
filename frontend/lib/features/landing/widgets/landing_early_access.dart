import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color _teal = Color(0xFF17C3B2);

class LandingEarlyAccess extends StatefulWidget {
  const LandingEarlyAccess({super.key, required this.isMobile});
  final bool isMobile;

  @override
  State<LandingEarlyAccess> createState() => _LandingEarlyAccessState();
}

class _LandingEarlyAccessState extends State<LandingEarlyAccess> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  String _role = 'Student';
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  static const _roles = ['Student', 'Doctor', 'Other'];
  static const _backendUrl =
      'https://medgraph-backend-2py8.onrender.com';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$_backendUrl/api/auth/waitlist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': _role,
          'institution': _institutionCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      if (res.statusCode < 400) {
        setState(() => _submitted = true);
      } else {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: widget.isMobile ? 20 : 80,
      ),
      child: Stack(
        children: [
          // Gradient orbs
          Positioned(top: -80, left: -80, child: _Orb(size: 400, color: _teal.withValues(alpha: 0.08))),
          Positioned(bottom: -60, right: -60, child: _Orb(size: 350, color: const Color(0xFF007AFF).withValues(alpha: 0.06))),
          Column(
            children: [
              const Text(
                'LIMITED EARLY ACCESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Be among the first.',
                style: TextStyle(
                  fontSize: widget.isMobile ? 32 : 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'First 500 get 3 months Pro free',
                style: TextStyle(
                    fontSize: 16, color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 40),

              // Glass card
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: _submitted
                            ? _SuccessContent()
                            : _FormContent(
                                formKey: _formKey,
                                nameCtrl: _nameCtrl,
                                emailCtrl: _emailCtrl,
                                institutionCtrl: _institutionCtrl,
                                role: _role,
                                roles: _roles,
                                onRoleChange: (v) {
                                  if (v != null) setState(() => _role = v);
                                },
                                loading: _loading,
                                error: _error,
                                onSubmit: _submit,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '2,437 professionals already waiting',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.institutionCtrl,
    required this.role,
    required this.roles,
    required this.onRoleChange,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, institutionCtrl;
  final String role;
  final List<String> roles;
  final ValueChanged<String?> onRoleChange;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const inputStyle = TextStyle(color: Colors.white, fontSize: 15);
    const hintStyle = TextStyle(color: Color(0x80FFFFFF), fontSize: 15);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: hintStyle,
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameCtrl,
            style: inputStyle,
            decoration:
                inputDecoration.copyWith(hintText: 'Full name'),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailCtrl,
            style: inputStyle,
            keyboardType: TextInputType.emailAddress,
            decoration:
                inputDecoration.copyWith(
                    hintText:
                        'Institutional or College Email (e.g., student@aiims.edu)'),
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Required';
              if (!v!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: role,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A2E),
                style: inputStyle,
                items: roles
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: inputStyle)))
                    .toList(),
                onChanged: onRoleChange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: institutionCtrl,
            style: inputStyle,
            decoration: inputDecoration.copyWith(
                hintText: 'College or Hospital'),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!,
                style: const TextStyle(
                    color: Color(0xFFFF6B6B), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _teal.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text(
                      'Claim my early access',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _teal.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.check, color: _teal, size: 36),
        ),
        const SizedBox(height: 20),
        const Text(
          "You're on the list!",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll email you when access opens.\nFirst 500 get 3 months Pro free.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

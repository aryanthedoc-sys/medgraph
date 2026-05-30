import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/api_service.dart';

class AlliedHealthScreen extends StatefulWidget {
  const AlliedHealthScreen({super.key});

  @override
  State<AlliedHealthScreen> createState() => _AlliedHealthScreenState();
}

class _AlliedHealthScreenState extends State<AlliedHealthScreen> {
  final _emailCtr = TextEditingController();
  bool _loading    = false;
  bool _submitted  = false;
  String? _error;
  String? _selectedProfession;

  @override
  void dispose() {
    _emailCtr.dispose();
    super.dispose();
  }

  bool get _isValidEmail {
    final e = _emailCtr.text.trim();
    return e.contains('@') && e.contains('.');
  }

  Future<void> _notifyMe() async {
    if (!_isValidEmail || _selectedProfession == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.post('/api/auth/allied-health-waitlist', {
        'email': _emailCtr.text.trim().toLowerCase(),
        'profession': _selectedProfession,
      });
      setState(() { _submitted = true; _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Could not reach server. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? Colors.black : Colors.white;
    final text     = isDark ? Colors.white : Colors.black;
    final sub      = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface  = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border   = isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: BackButton(color: text, onPressed: () {
          if (context.canPop()) context.pop();
          else context.go('/');
        }),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 60,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Allied Health',
                  style: AppTextStyles.largeTitle.copyWith(color: text)),
              const SizedBox(height: 6),
              Text(
                'Coming soon — a dedicated platform for nursing and physiotherapy professionals.',
                style: AppTextStyles.body.copyWith(color: sub),
              ),
              const SizedBox(height: 36),

              // Cards row / column
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final cards = [
                  _ProfessionCard(
                    icon: '💊',
                    title: 'Nursing',
                    subtitle: 'For Nurses',
                    description: 'Connect with fellow nurses, share clinical experiences, and advance your career.',
                    color: const Color(0xFF0071E3),
                    surfaceColor: surface,
                    borderColor: border,
                    isDark: isDark,
                    selected: _selectedProfession == 'nurse',
                    onTap: () => setState(() => _selectedProfession = 'nurse'),
                  ),
                  _ProfessionCard(
                    icon: '🏃',
                    title: 'Physiotherapy',
                    subtitle: 'For Physiotherapists',
                    description: 'Connect with fellow physios, share cases, and build your practice.',
                    color: const Color(0xFF34C759),
                    surfaceColor: surface,
                    borderColor: border,
                    isDark: isDark,
                    selected: _selectedProfession == 'physio',
                    onTap: () => setState(() => _selectedProfession = 'physio'),
                  ),
                ];

                return isWide
                    ? Row(
                        children: cards.map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: c,
                          ),
                        )).toList(),
                      )
                    : Column(
                        children: cards.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: c,
                        )).toList(),
                      );
              }),

              const SizedBox(height: 36),

              // Notification signup
              Text(
                'Get notified when Allied Health launches',
                style: AppTextStyles.headline.copyWith(color: text),
              ),
              const SizedBox(height: 16),

              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00C7BE)),
                      const SizedBox(width: 10),
                      Text(
                        "We'll notify you at launch!",
                        style: AppTextStyles.headline.copyWith(color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailCtr,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Your email address',
                          hintStyle: TextStyle(color: sub),
                          filled: true,
                          fillColor: surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border, width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                          ),
                        ),
                        style: TextStyle(color: text),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isValidEmail && _selectedProfession != null && !_loading)
                            ? _notifyMe
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,
                                ),
                              )
                            : const Text('Notify me', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                if (_selectedProfession == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Select your profession above first',
                    style: AppTextStyles.footnote.copyWith(color: sub),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: AppTextStyles.footnote.copyWith(color: AppColors.danger)),
                ],
              ],

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: Text(
                  'MedGraph Allied Health is a separate community for nursing and physiotherapy professionals. '
                  'It does not connect with the main MedGraph medical platform.',
                  style: AppTextStyles.footnote.copyWith(color: sub),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionCard extends StatelessWidget {
  const _ProfessionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.surfaceColor,
    required this.borderColor,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final Color surfaceColor;
  final Color borderColor;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = isDark ? Colors.white : Colors.black;
    final sub  = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : borderColor,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.headline.copyWith(color: text)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.footnote.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Text(description,
                style: AppTextStyles.footnote.copyWith(color: sub, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

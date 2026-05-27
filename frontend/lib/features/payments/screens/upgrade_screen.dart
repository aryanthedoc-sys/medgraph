import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/services/api_service.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _loading = false;
  // Razorpay is only available on Android/iOS.
  Razorpay? _razorpay;

  static const _features = [
    _Feature(
        icon: Icons.search,
        title: 'Profile search',
        subtitle: 'Find any verified doctor or student'),
    _Feature(
        icon: Icons.all_inclusive,
        title: 'Unlimited sessions',
        subtitle: 'No daily or time limits'),
    _Feature(
        icon: Icons.tune,
        title: 'Specialty filter',
        subtitle: 'Match by exact specialty'),
    _Feature(
        icon: Icons.message_outlined,
        title: 'Message doctors',
        subtitle: 'Direct message verified practitioners'),
    _Feature(
        icon: Icons.leaderboard_outlined,
        title: 'Pro leaderboard',
        subtitle: 'Compete on the Pro-only rankings'),
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ── Razorpay handlers ────────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful — Pro is now active!'),
        backgroundColor: AppColors.success,
      ),
    );
    // Refresh auth state so isPro reflects immediately, then go home.
    ref.invalidate(currentUserProvider);
    context.go('/home');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Payment failed: ${response.message ?? 'Unknown error'}'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // User selected an external wallet — Razorpay handles the redirect.
    // No action needed here; result arrives via success/error handlers.
  }

  // ── Subscribe flow ───────────────────────────────────────────────────────────

  Future<void> _subscribe() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Open the MedGraph app on Android to subscribe.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final data =
          await ApiService.post('/api/payments/create-pro-subscription', {});
      final subscriptionId = data['subscriptionId'] as String;
      final keyId          = data['razorpayKeyId']  as String;
      final userEmail =
          ref.read(currentUserProvider)?.email ?? '';

      final options = <String, dynamic>{
        'key':             keyId,
        'subscription_id': subscriptionId,
        'name':            'MedGraph',
        'description':     'Pro · ₹99/month',
        'prefill':         {'email': userEmail},
        'theme':           {'color': '#000000'},
      };

      _razorpay!.open(options);
      // _loading is cleared by _handlePaymentSuccess / _handlePaymentError.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final text     = isDark ? Colors.white : Colors.black;
    final sub      = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface  = isDark ? AppColors.darkSurface    : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.proGold, size: 28),
                  const SizedBox(width: 10),
                  Text('MedGraph Pro',
                      style: AppTextStyles.title1.copyWith(color: text)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Everything you need to study smarter and connect deeper.',
                style: AppTextStyles.body.copyWith(color: sub),
              ),
              const SizedBox(height: 32),

              // Feature list
              ...List.generate(_features.length, (i) {
                final f = _features[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon, size: 20, color: text),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title,
                                style: AppTextStyles.subheadline.copyWith(
                                    color: text,
                                    fontWeight: FontWeight.w600)),
                            Text(f.subtitle,
                                style: AppTextStyles.caption
                                    .copyWith(color: sub)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                    ],
                  ),
                );
              }),

              const Spacer(),

              // Price badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.proGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.proGold.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹99',
                        style: AppTextStyles.title1.copyWith(
                            color: text, fontWeight: FontWeight.w800),
                      ),
                      Text(' / month',
                          style: AppTextStyles.body.copyWith(color: sub)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              MGButton(
                label: 'Subscribe · ₹99/month',
                onPressed: _subscribe,
                isLoading: _loading,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Cancel anytime · Billed monthly via Razorpay',
                  style: AppTextStyles.caption.copyWith(color: sub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

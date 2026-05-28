import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: AppTextStyles.title1.copyWith(color: text),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: 1 June 2025',
                style: AppTextStyles.footnote.copyWith(color: sub),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'This policy is compliant with the Digital Personal Data Protection Act, 2023 (DPDP Act) of India.',
                  style: TextStyle(
                      fontSize: 13, color: sub, height: 1.5),
                ),
              ),
              const SizedBox(height: 28),
              _section(
                title: '1. Information We Collect',
                body: 'We collect information you provide directly: name, email address, phone number, academic institution, year of study or medical registration number, specialty, and profile photo. We also collect usage data including session logs, match history, post activity, and device information. For verified doctors, we collect and securely store MCI/NMC registration numbers and verification documents.',
                text: text, sub: sub,
              ),
              _section(
                title: '2. How We Use Your Information',
                body: 'Your information is used to:\n\n'
                    '• Create and manage your account.\n'
                    '• Match you with study partners or doctors.\n'
                    '• Enable video sessions via LiveKit.\n'
                    '• Send important notifications (session reminders, streak alerts).\n'
                    '• Verify doctor credentials.\n'
                    '• Improve our Platform through aggregated analytics.\n\n'
                    'We do not use your data for automated clinical decision-making.',
                text: text, sub: sub,
              ),
              _section(
                title: '3. Data Sharing',
                body: 'We share data with:\n\n'
                    '• Supabase (database and authentication infrastructure).\n'
                    '• LiveKit (real-time video infrastructure).\n'
                    '• Razorpay (payment processing — only transaction data).\n'
                    '• Firebase (push notification delivery).\n\n'
                    'We do not sell your personal data to any third party. We do not share your data with advertisers.',
                text: text, sub: sub,
              ),
              _section(
                title: '4. Data Localisation',
                body: 'In compliance with the DPDP Act, 2023, we store all personal data of Indian users on servers located within India. Verification documents are stored in encrypted form on Indian infrastructure. You may request the deletion of your data at any time.',
                text: text, sub: sub,
              ),
              _section(
                title: '5. Your Rights Under DPDP Act',
                body: 'As a data principal under the DPDP Act, 2023, you have the right to:\n\n'
                    '• Access a summary of your personal data processed by us.\n'
                    '• Correct or update inaccurate personal data.\n'
                    '• Erase your personal data and close your account.\n'
                    '• Withdraw consent for optional data processing.\n'
                    '• Nominate a person to exercise rights on your behalf.\n\n'
                    'To exercise any of these rights, email us at privacy@medgraph.in.',
                text: text, sub: sub,
              ),
              _section(
                title: '6. Cookies and Local Storage',
                body: 'On web, we use browser local storage for session tokens and user preferences. We do not use third-party tracking cookies. You may clear local storage at any time via your browser settings, which will log you out.',
                text: text, sub: sub,
              ),
              _section(
                title: '7. Data Retention',
                body: 'We retain your account data for as long as your account is active. If you delete your account, we remove your personal data within 30 days. Aggregated, anonymised analytics may be retained indefinitely. Verification documents for doctors are retained for 7 years for compliance purposes.',
                text: text, sub: sub,
              ),
              _section(
                title: '8. Security',
                body: 'We use industry-standard security measures including TLS encryption in transit, AES-256 encryption at rest for sensitive documents, and row-level security policies on our database. We conduct regular security reviews. However, no system is completely secure and we cannot guarantee absolute security.',
                text: text, sub: sub,
              ),
              _section(
                title: '9. Children\'s Privacy',
                body: 'MedGraph is not intended for users under 18 years of age. We do not knowingly collect personal data from anyone under 18. If we learn that a user is under 18, we will delete their account.',
                text: text, sub: sub,
              ),
              _section(
                title: '10. Contact & Grievance Officer',
                body: 'For privacy-related requests or concerns, please contact our Grievance Officer:\n\nEmail: privacy@medgraph.in\nResponse time: 72 hours for acknowledgement, 30 days for resolution.\n\nFor escalation, you may contact the Data Protection Board of India at their official portal.',
                text: text, sub: sub,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required String body,
    required Color text,
    required Color sub,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              color: sub,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: AppTextStyles.title1.copyWith(color: text),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: 1 June 2025',
                style: AppTextStyles.footnote.copyWith(color: sub),
              ),
              const SizedBox(height: 32),
              _section(
                title: '1. Acceptance of Terms',
                body: 'By accessing or using MedGraph ("the Platform"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not use the Platform. These terms apply to all users, including medical students and verified doctors.',
                text: text, sub: sub,
              ),
              _section(
                title: '2. Educational Purpose Only',
                body: 'MedGraph is strictly an educational networking platform. Nothing on MedGraph constitutes medical advice, a diagnosis, a prescription, or clinical guidance of any kind. No doctor-patient relationship is created through use of this Platform. All content shared is for educational and discussion purposes only. You must not use this Platform to seek or provide clinical decisions for real patients.',
                text: text, sub: sub,
              ),
              _section(
                title: '3. Doctor Verification',
                body: 'Doctors must provide a valid MCI/NMC registration number and supporting documentation for verification. Verification is manual and may take up to 24 hours. Providing false credentials is a violation of these Terms and may result in immediate termination. Verified status does not constitute endorsement by MedGraph.',
                text: text, sub: sub,
              ),
              _section(
                title: '4. Disclaimer',
                body: 'As a registered medical practitioner on MedGraph, you confirm that:\n\n'
                    '• All case discussions are purely educational in nature.\n'
                    '• You will not use MedGraph to establish doctor-patient relationships.\n'
                    '• You accept full personal professional liability for any clinical advice you give as a medical practitioner.\n'
                    '• You will comply with all applicable medical council regulations.',
                text: text, sub: sub,
              ),
              _section(
                title: '5. Patient Data & Privacy',
                body: 'You must never share real patient identifiers on MedGraph, including but not limited to: full names, Aadhaar numbers, hospital record numbers, contact details, photographs, or addresses. Sharing identifiable patient data is a violation of the Digital Personal Data Protection Act, 2023 (India) and may result in legal action. MedGraph reserves the right to remove any content that may identify a patient.',
                text: text, sub: sub,
              ),
              _section(
                title: '6. Intellectual Property',
                body: 'All content you create on MedGraph remains yours. By posting, you grant MedGraph a non-exclusive, royalty-free licence to display and distribute your content on the Platform. You may not copy, reproduce, or distribute other users\' content without their explicit consent. The MedGraph name, logo, and design are owned by MedGraph and may not be used without written permission.',
                text: text, sub: sub,
              ),
              _section(
                title: '7. Account Termination',
                body: 'MedGraph reserves the right to suspend or permanently terminate any account that violates these Terms, shares patient-identifying information, spreads medical misinformation, or engages in harassment. Terminated accounts may not re-register without explicit approval.',
                text: text, sub: sub,
              ),
              _section(
                title: '8. Limitation of Liability',
                body: 'To the maximum extent permitted by law, MedGraph and its operators shall not be liable for any direct, indirect, incidental, special, or consequential damages arising from your use of the Platform, including any clinical decisions made based on content found here. Your use of the Platform is at your own risk.',
                text: text, sub: sub,
              ),
              _section(
                title: '9. Governing Law',
                body: 'These Terms are governed by the laws of India. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts of Bangalore, Karnataka, India.',
                text: text, sub: sub,
              ),
              _section(
                title: '10. Contact',
                body: 'For any questions regarding these Terms, please contact us at legal@medgraph.in. We aim to respond within 72 hours.',
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

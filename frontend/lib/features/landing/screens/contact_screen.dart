import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Get in touch',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Get in touch",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'd love to hear from you",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 32),
              _ContactCard(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF00C7BE),
                label: 'Email us',
                value: 'aryandevagarwal89000@gmail.com',
                onTap: () => launchUrl(
                  Uri.parse('mailto:aryandevagarwal89000@gmail.com'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: 16),
              _ContactCard(
                icon: Icons.camera_alt_outlined,
                iconColor: const Color(0xFFAF52DE),
                label: 'Follow on Instagram',
                value: '@aryandevagarwal',
                onTap: () => launchUrl(
                  Uri.parse('https://instagram.com/aryandevagarwal'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}

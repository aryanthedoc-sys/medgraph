import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Web stub — dart_webrtc JS-interop is incompatible with Flutter web builds.
/// Shows partner info and prompts the user to switch to the mobile app.
class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
    required this.partnerCollege,
    this.partnerAvatarUrl,
  });

  final String roomId;
  final String partnerName;
  final String partnerCollege;
  final String? partnerAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = partnerName.trim().isNotEmpty
        ? partnerName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  partnerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (partnerCollege.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    partnerCollege,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.smartphone, color: Colors.white54, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        'Video calls require the MedGraph mobile app',
                        style: AppTextStyles.subheadline.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You\'ve been matched! Open the app on your phone to start the call.',
                        style: AppTextStyles.footnote.copyWith(color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/home'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to home',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

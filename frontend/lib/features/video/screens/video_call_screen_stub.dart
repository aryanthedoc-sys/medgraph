import 'package:flutter/material.dart';

/// Web stub — LiveKit / WebRTC is only available on Android and iOS.
/// The router will push this screen on web when a match is found, but
/// video calls should be prompted to open the mobile app instead.
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_disabled,
                  size: 56, color: Colors.white38),
              const SizedBox(height: 20),
              const Text(
                'Video calls are available on the mobile app.',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your match: $partnerName',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

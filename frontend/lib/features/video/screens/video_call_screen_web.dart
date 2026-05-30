// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/socket_service.dart';

/// Web video call screen — embeds Jitsi Meet in a full-screen IFrame.
/// Browser handles all WebRTC natively, bypassing dart_webrtc entirely.
class VideoCallScreen extends StatefulWidget {
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
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _ready = false;

  String get _viewId => 'jitsi-${widget.roomId}';

  @override
  void initState() {
    super.initState();
    _registerIframe();
    SocketService.on('partner-ended', (_) {
      if (mounted) _leave();
    });
  }

  @override
  void dispose() {
    SocketService.off('partner-ended');
    super.dispose();
  }

  void _registerIframe() {
    try {
      ui.platformViewRegistry.registerViewFactory(_viewId, (int _) {
        return html.IFrameElement()
          ..src = 'https://meet.jit.si/${widget.roomId}'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'camera; microphone; fullscreen; display-capture; autoplay';
      });
    } catch (_) {
      // Factory already registered (hot-restart / re-navigation) — safe to ignore.
    }
    if (mounted) setState(() => _ready = true);
  }

  void _leave() {
    SocketService.emit('end-call', {'roomId': widget.roomId});
    if (mounted) context.go('/home');
  }

  String get _initials {
    final parts = widget.partnerName.trim().split(' ');
    return parts.map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen Jitsi iframe
          Positioned.fill(
            child: HtmlElementView(viewType: _viewId),
          ),

          // Top gradient bar — partner info + Leave button
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.25),
                      child: Text(
                        _initials.isNotEmpty ? _initials : '?',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.partnerName,
                            style: AppTextStyles.subheadline.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.partnerCollege.isNotEmpty)
                            Text(
                              widget.partnerCollege,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _leave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Leave',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

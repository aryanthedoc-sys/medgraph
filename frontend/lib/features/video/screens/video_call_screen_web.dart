// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/socket_service.dart';

/// Web video call screen.
/// Iframes into /livekit_meet.html which uses the LiveKit JavaScript SDK —
/// dart_webrtc JS-interop types are not compatible with Flutter web builds,
/// so web uses the LiveKit JS SDK loaded in a same-origin iframe instead.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.partnerInfo,
  });

  final String roomName;
  final String token;
  final String livekitUrl;
  final Map<String, dynamic> partnerInfo;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _ready = false;
  html.EventListener? _msgListener;

  String get _partnerName    => (widget.partnerInfo['name']    as String?) ?? 'Partner';
  String get _partnerCollege => (widget.partnerInfo['college'] as String?) ?? '';

  String get _viewId => 'livekit-${widget.roomName}';

  String get _iframeSrc {
    final url   = Uri.encodeComponent(widget.livekitUrl);
    final token = Uri.encodeComponent(widget.token);
    final name  = Uri.encodeComponent(
      _partnerName.isNotEmpty ? _partnerName : 'MedGraph User',
    );
    return '/livekit_meet.html?url=$url&token=$token&name=$name';
  }

  @override
  void initState() {
    super.initState();
    _registerIframe();
    _listenHangup();
    SocketService.on('partner-ended', (_) {
      if (mounted) _leave();
    });
  }

  @override
  void dispose() {
    if (_msgListener != null) {
      html.window.removeEventListener('message', _msgListener!);
    }
    SocketService.off('partner-ended');
    super.dispose();
  }

  void _registerIframe() {
    try {
      ui.platformViewRegistry.registerViewFactory(_viewId, (int _) {
        return html.IFrameElement()
          ..src = _iframeSrc
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'camera; microphone; fullscreen; display-capture; autoplay';
      });
    } catch (_) {
      // Already registered on hot-restart / re-navigation.
    }
    if (mounted) setState(() => _ready = true);
  }

  void _listenHangup() {
    _msgListener = (html.Event event) {
      if (event is html.MessageEvent) {
        final data = event.data;
        if (data is Map && data['type'] == 'livekit-hangup') {
          _leave();
        }
      }
    };
    html.window.addEventListener('message', _msgListener!);
  }

  void _leave() {
    SocketService.emit('end-call', {'roomId': widget.roomName});
    if (mounted) context.go('/home');
  }

  String get _initials {
    final parts = _partnerName.trim().split(' ');
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
          // Full-screen LiveKit iframe
          Positioned.fill(
            child: HtmlElementView(viewType: _viewId),
          ),

          // Top gradient bar — partner info + Leave button
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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
                            _partnerName,
                            style: AppTextStyles.subheadline.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_partnerCollege.isNotEmpty)
                            Text(
                              _partnerCollege,
                              style: const TextStyle(
                                color: Colors.white54, fontSize: 12,
                              ),
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
                          horizontal: 16, vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Leave',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/socket_service.dart';
import '../../../shared/widgets/disclaimer_overlay.dart';

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
  // ── Partner info convenience getters ─────────────────────────────────────────
  String get _partnerName    => (widget.partnerInfo['name']    as String?) ?? 'Partner';
  String get _partnerCollege => (widget.partnerInfo['college'] as String?) ?? '';

  // ── LiveKit ──────────────────────────────────────────────────────────────────
  final lk.Room _room = lk.Room();
  lk.EventsListener<lk.RoomEvent>? _roomEvents;
  bool _connected    = false;
  bool _connecting   = true;
  String? _connectError;
  bool _frontCamera  = true;

  // ── Controls ─────────────────────────────────────────────────────────────────
  bool _micOn          = true;
  bool _cameraOn       = true;
  bool _overlayVisible = true;
  bool _ending         = false; // prevents _onRoomUpdate from auto-popping during intentional end

  // ── Timer ────────────────────────────────────────────────────────────────────
  int    _seconds      = 0;
  Timer? _timer;
  Timer? _overlayTimer;
  static const _freeMinutes = 30;
  bool   _warningShown = false;

  // ── Disclaimer banner ─────────────────────────────────────────────────────────
  bool   _showDisclaimer = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('[VideoCallScreen] starting — room=${widget.roomName} url=${widget.livekitUrl} tokenLen=${widget.token.length}');
    if (widget.roomName.isEmpty || widget.token.isEmpty || widget.livekitUrl.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _connecting   = false;
            _connectError = 'Missing connection parameters (room=${widget.roomName.isEmpty}, token=${widget.token.isEmpty}, url=${widget.livekitUrl.isEmpty})';
          });
        }
      });
      return;
    }
    _room.addListener(_onRoomUpdate);
    // Explicit typed event listeners — belt-and-suspenders for track subscriptions.
    // Room.addListener (ChangeNotifier) covers most cases; these fire for the
    // specific track events that update the remote video widget.
    _roomEvents = _room.createListener()
      ..on<lk.TrackSubscribedEvent>((e) {
        // ignore: avoid_print
        print('[VideoCallScreen] TrackSubscribed kind=${e.track.kind} participant=${e.participant.identity}');
        if (mounted) setState(() {});
      })
      ..on<lk.TrackUnsubscribedEvent>((e) {
        // ignore: avoid_print
        print('[VideoCallScreen] TrackUnsubscribed kind=${e.track.kind}');
        if (mounted) setState(() {});
      })
      ..on<lk.TrackPublishedEvent>((e) {
        // ignore: avoid_print
        print('[VideoCallScreen] TrackPublished participant=${e.participant.identity}');
        if (mounted) setState(() {});
      })
      ..on<lk.ParticipantConnectedEvent>((e) {
        // ignore: avoid_print
        print('[VideoCallScreen] ParticipantConnected identity=${e.participant.identity}');
        if (mounted) setState(() {});
      });
    _startTimer();
    _scheduleOverlayHide();
    _listenSocket();
    _connectToRoom();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _overlayTimer?.cancel();
    _roomEvents?.dispose();
    _room.removeListener(_onRoomUpdate);
    _room.disconnect();
    _room.dispose();
    SocketService.off('partner-skipped');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Connection ───────────────────────────────────────────────────────────────

  Future<void> _connectToRoom() async {
    // On mobile, request camera + mic before connecting.
    if (!kIsWeb) {
      final camera = await Permission.camera.request();
      final mic    = await Permission.microphone.request();
      if (!camera.isGranted || !mic.isGranted) {
        if (!mounted) return;
        setState(() {
          _connecting   = false;
          _connectError = 'Camera and microphone permissions are required.';
        });
        return;
      }
    }

    try {
      // ignore: avoid_print
      print('[VideoCallScreen] calling room.connect url=${widget.livekitUrl}');
      await _room.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const lk.RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultVideoPublishOptions: lk.VideoPublishOptions(simulcast: true),
        ),
      );
      // ignore: avoid_print
      print('[VideoCallScreen] room.connect succeeded');
    } catch (e) {
      // ignore: avoid_print
      print('[VideoCallScreen] room.connect FAILED: $e');
      if (mounted) {
        setState(() {
          _connecting   = false;
          _connectError = 'Could not connect to call: ${e.toString()}';
        });
      }
      return;
    }

    try {
      await _room.localParticipant?.setCameraEnabled(true);
      await _room.localParticipant?.setMicrophoneEnabled(true);
    } catch (e) {
      // ignore: avoid_print
      print('[VideoCallScreen] camera/mic enable failed (non-fatal): $e');
      // Continue — the call can proceed without camera/mic initially
    }

    if (mounted) setState(() { _connecting = false; _connected = true; _showDisclaimer = true; });
  }

  void _onRoomUpdate() {
    if (!mounted) return;
    if (_connected && !_ending &&
        _room.connectionState == lk.ConnectionState.disconnected) {
      // ignore: avoid_print
      print('[VideoCallScreen] unexpected disconnect — showing error UI, NOT popping');
      setState(() {
        _connecting = false;
        _connectError = 'The call was disconnected. Please go back and try again.';
      });
      return;
    }
    setState(() {});
  }

  // ── Track accessors ──────────────────────────────────────────────────────────

  lk.VideoTrack? get _localVideoTrack {
    if (!_connected || !_cameraOn) return null;
    return _room.localParticipant?.videoTrackPublications
        .where((p) => p.track != null && !p.muted)
        .firstOrNull
        ?.track;
  }

  lk.VideoTrack? get _remoteVideoTrack {
    if (!_connected) return null;
    final remote = _room.remoteParticipants.values.firstOrNull;
    return remote?.videoTrackPublications
        .where((p) => p.track != null)
        .firstOrNull
        ?.track;
  }

  // ── Timer & overlay ──────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      final mins = _seconds ~/ 60;
      if (mins == _freeMinutes - 2 && !_warningShown) {
        _warningShown = true;
        _showTimeWarning();
      }
      if (mins >= _freeMinutes) _endCall(reason: 'limit');
    });
  }

  void _scheduleOverlayHide() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3),
        () { if (mounted) setState(() => _overlayVisible = false); });
  }

  void _onTap() {
    setState(() => _overlayVisible = true);
    _scheduleOverlayHide();
  }

  void _listenSocket() {
    SocketService.on('partner-skipped', (_) {
      if (!mounted) return;
      _endCall(reason: 'skipped');
    });
  }

  void _showTimeWarning() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('2 minutes remaining · Upgrade Pro for unlimited sessions'),
      backgroundColor: AppColors.warning,
      duration: Duration(seconds: 6),
    ));
  }

  String get _duration {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  Future<void> _toggleMic() async {
    final next = !_micOn;
    setState(() => _micOn = next);
    await _room.localParticipant?.setMicrophoneEnabled(next);
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraOn;
    setState(() => _cameraOn = next);
    await _room.localParticipant?.setCameraEnabled(next);
  }

  Future<void> _flipCamera() async {
    if (kIsWeb || !_connected || !_cameraOn) return;
    HapticFeedback.lightImpact();
    final track = _room.localParticipant?.videoTrackPublications
        .firstOrNull?.track;
    if (track != null) {
      await Helper.switchCamera(track.mediaStreamTrack);
      if (mounted) setState(() => _frontCamera = !_frontCamera);
    }
  }

  void _endCall({String reason = 'ended'}) {
    _ending = true;
    _timer?.cancel();
    _room.disconnect();
    SocketService.emit('end-call', {'roomId': widget.roomName, 'reason': reason});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    if (reason == 'ended') {
      _showNotesSheet();
    } else if (reason == 'limit') {
      ApiService.post('/api/sessions/${widget.roomName}/end',
          {'durationSeconds': _seconds}).catchError((_) => <String, dynamic>{});
      _showLimitDialog();
    } else {
      ApiService.post('/api/sessions/${widget.roomName}/end',
          {'durationSeconds': _seconds}).catchError((_) => <String, dynamic>{});
      Navigator.of(context).pop();
    }
  }

  void _showNotesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotesSheet(
        roomId: widget.roomName,
        partnerName: _partnerName,
        durationSeconds: _seconds,
      ),
    ).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _skip() {
    HapticFeedback.mediumImpact();
    SocketService.emit('skip', {'roomId': widget.roomName});
    _room.disconnect();
    Navigator.of(context).pop();
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session time limit reached'),
        content: const Text(
          'Free sessions are limited to 30 minutes.\nUpgrade Pro for unlimited sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              context.go('/upgrade');
            },
            child: const Text('Upgrade ₹99/month'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              context.go('/sessions');
            },
            child: const Text('Book a session'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Connecting…',
                  style: TextStyle(color: Colors.white60, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    if (_connectError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  _connectError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _connectError = null;
                      _connecting   = true;
                      _connected    = false;
                    });
                    _connectToRoom();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    minimumSize: const Size(160, 44),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final remoteVideo = _remoteVideoTrack;
    final localVideo  = _localVideoTrack;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          children: [
            // ── Remote video (full screen) ────────────────────────────────
            Positioned.fill(
              child: remoteVideo != null
                  ? lk.VideoTrackRenderer(
                      remoteVideo,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : _RemotePlaceholder(name: _partnerName),
            ),

            // ── Local PiP (top-right corner) ─────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: localVideo != null
                      ? lk.VideoTrackRenderer(
                          localVideo,
                          fit: RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitCover,
                        )
                      : Container(
                          color: const Color(0xFF2C2C2C),
                          child: const Center(
                            child: Icon(Icons.videocam_off,
                                color: Colors.white38, size: 32),
                          ),
                        ),
                ),
              ),
            ),

            // ── Disclaimer banner ─────────────────────────────────────────
            if (_showDisclaimer)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: DisclaimerOverlay(
                  variant: DisclaimerVariant.videoCall,
                  onDismiss: () =>
                      setState(() => _showDisclaimer = false),
                ),
              ),

            // ── Top overlay (fades after 3 s) ─────────────────────────────
            AnimatedOpacity(
              opacity: _overlayVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _TopOverlay(
                partnerName: _partnerName,
                partnerCollege: _partnerCollege,
                duration: _duration,
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              child: _BottomControls(
                micOn: _micOn,
                cameraOn: _cameraOn,
                onMicToggle: () { _toggleMic(); },
                onCameraToggle: () { _toggleCamera(); },
                onEndCall: () => _endCall(),
                onSkip: _skip,
                onFlip: () { _flipCamera(); },
                showFlip: !kIsWeb,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Remote placeholder ────────────────────────────────────────────────────────
class _RemotePlaceholder extends StatelessWidget {
  const _RemotePlaceholder({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white12,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 32,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(color: Colors.white60, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Waiting for video…',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Top overlay ──────────────────────────────────────────────────────────────
class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.partnerName,
    required this.partnerCollege,
    required this.duration,
  });

  final String partnerName;
  final String partnerCollege;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    partnerCollege,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppColors.verifiedGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 12, color: AppColors.verifiedGreen),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.verifiedGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom controls ──────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.micOn,
    required this.cameraOn,
    required this.onMicToggle,
    required this.onCameraToggle,
    required this.onEndCall,
    required this.onSkip,
    required this.onFlip,
    this.showFlip = true,
  });

  final bool micOn;
  final bool cameraOn;
  final VoidCallback onMicToggle;
  final VoidCallback onCameraToggle;
  final VoidCallback onEndCall;
  final VoidCallback onSkip;
  final VoidCallback onFlip;
  final bool showFlip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(40),
      ),
      // FittedBox scales the row down proportionally on very narrow devices
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CtrlBtn(
                icon: micOn ? Icons.mic : Icons.mic_off,
                onTap: onMicToggle,
                active: micOn),
            const SizedBox(width: 8),
            _CtrlBtn(
                icon: cameraOn ? Icons.videocam : Icons.videocam_off,
                onTap: onCameraToggle,
                active: cameraOn),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEndCall,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle),
                child: const Icon(Icons.call_end, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSkip,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.skip_next, color: Colors.black, size: 26),
              ),
            ),
            if (showFlip) ...[
              const SizedBox(width: 8),
              _CtrlBtn(icon: Icons.flip_camera_ios, onTap: onFlip, active: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({
    required this.icon,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: active ? Colors.white : Colors.white38, size: 24),
      ),
    );
  }
}

// ─── Post-call notes sheet ─────────────────────────────────────────────────────
class _NotesSheet extends StatefulWidget {
  const _NotesSheet({
    required this.roomId,
    required this.partnerName,
    required this.durationSeconds,
  });

  final String roomId;
  final String partnerName;
  final int durationSeconds;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _durationLabel {
    final m = widget.durationSeconds ~/ 60;
    final s = widget.durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  Future<void> _skip() async {
    await ApiService.post(
      '/api/sessions/${widget.roomId}/end',
      {'durationSeconds': widget.durationSeconds},
    ).catchError((_) => <String, dynamic>{});
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final notes = _ctrl.text.trim();
    await ApiService.post(
      '/api/sessions/${widget.roomId}/end',
      {
        'durationSeconds': widget.durationSeconds,
        if (notes.isNotEmpty) 'summaryNotes': notes,
      },
    ).catchError((_) => <String, dynamic>{});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Session Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'with ${widget.partnerName}  ·  $_durationLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  maxLines: 5,
                  maxLength: 2000,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'What did you cover? Key points, takeaways…',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving ? null : _skip,
                        child: const Text('Skip', style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Notes',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

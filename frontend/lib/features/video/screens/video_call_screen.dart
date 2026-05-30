// Conditional platform export:
//   • Mobile (dart.library.io available)  → LiveKit implementation
//   • Web    (dart.library.html available) → Jitsi Meet iframe
// dart_webrtc JS-interop types are incompatible with Flutter web builds,
// so web uses native browser WebRTC via an IFrameElement instead.
export 'video_call_screen_mobile.dart'
    if (dart.library.html) 'video_call_screen_web.dart';

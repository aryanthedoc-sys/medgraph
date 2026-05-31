// Conditional platform export:
//   • Mobile (dart.library.io available) → LiveKit implementation
//   • Web    (dart.library.html available) → stub (prompts to use mobile app)
// dart_webrtc JS-interop is incompatible with Flutter web builds.
export 'video_call_screen_mobile.dart'
    if (dart.library.html) 'video_call_screen_stub.dart';

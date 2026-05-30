// Conditional platform export:
//   • Mobile (dart.library.io available)  → full LiveKit implementation
//   • Web    (dart.library.html available) → lightweight stub
// dart_webrtc's JS-interop types are incompatible with Flutter web builds.
export 'video_call_screen_mobile.dart'
    if (dart.library.html) 'video_call_screen_stub.dart';

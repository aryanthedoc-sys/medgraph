// Conditional platform export:
//   • Mobile (dart.library.io available)  → full LiveKit implementation
//   • Web    (dart.library.html available) → lightweight stub
// This prevents dart_webrtc's JS-interop code from entering the web build.
export 'video_call_screen_mobile.dart'
    if (dart.library.html) 'video_call_screen_stub.dart';

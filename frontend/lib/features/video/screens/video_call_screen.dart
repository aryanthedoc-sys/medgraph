// Conditional platform export:
//   • Mobile (dart.library.io available) → LiveKit via livekit_client package
//   • Web    (dart.library.html available) → LiveKit JS SDK via IFrameElement
// dart_webrtc JS-interop types cannot compile for Flutter web, so web
// uses the LiveKit JavaScript SDK loaded in a same-origin iframe instead.
export 'video_call_screen_mobile.dart'
    if (dart.library.html) 'video_call_screen_web.dart';

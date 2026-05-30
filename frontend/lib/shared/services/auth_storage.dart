import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the auth JWT token and current user ID.
/// In-memory cache means synchronous reads after init(); SharedPreferences
/// persists across app restarts.
class AuthStorage {
  AuthStorage._();

  static const _tokenKey  = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  static String? _token;
  static String? _userId;

  /// Call once at app startup (before runApp) to restore a persisted session.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token  = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
  }

  /// Current JWT — empty string if not logged in.
  static String get token => _token ?? '';

  /// UUID of the logged-in user — empty string if not known yet.
  static String get userId => _userId ?? '';

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Persist token + userId after OTP verification.
  static Future<void> save(String token, {String? userId}) async {
    _token = token;
    if (userId != null && userId.isNotEmpty) _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
  }

  /// Clear everything on sign-out.
  static Future<void> clear() async {
    _token  = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase client — use this instead of calling
/// Supabase.instance directly so we can swap implementations in tests.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateStream =>
      client.auth.onAuthStateChange;
}

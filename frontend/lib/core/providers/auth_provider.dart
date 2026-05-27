import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/api_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>(
  (ref) => CurrentUserNotifier(),
);

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  CurrentUserNotifier() : super(null);

  Future<void> loadUser(String userId) async {
    try {
      final data = await ApiService.get('/api/auth/me');
      state = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      state = null;
    }
  }

  void setUser(UserModel user) => state = user;

  void clearUser() => state = null;

  bool get isPro {
    final u = state;
    if (u == null) return false;
    if (!u.isPro) return false;
    if (u.proExpiresAt == null) return false;
    return u.proExpiresAt!.isAfter(DateTime.now());
  }
}

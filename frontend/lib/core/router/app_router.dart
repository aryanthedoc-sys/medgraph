import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_choice_screen.dart';
import '../../features/auth/screens/student_register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/doctor_register_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/roulette/screens/roulette_screen.dart';
import '../../features/sessions/screens/sessions_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/payments/screens/upgrade_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/legal/screens/privacy_screen.dart';
import '../../shared/services/notification_service.dart';
import '../scaffold/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn =
          Supabase.instance.client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final isPublicRoute = loc.startsWith('/register') ||
          loc == '/onboarding' ||
          loc == '/' ||
          loc.startsWith('/legal') ||
          loc.startsWith('/dr/');

      if (!isLoggedIn && !isPublicRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) {
          if (kIsWeb) {
            final isLoggedIn =
                Supabase.instance.client.auth.currentSession != null;
            if (!isLoggedIn) return const LandingScreen();
          }
          return const SplashScreen();
        },
      ),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterChoiceScreen()),
      GoRoute(path: '/register/student', builder: (_, __) => const StudentRegisterScreen()),
      GoRoute(
        path: '/register/otp',
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return OTPScreen(email: email);
        },
      ),
      GoRoute(path: '/register/doctor', builder: (_, __) => const DoctorRegisterScreen()),
      GoRoute(path: '/register/profile-setup', builder: (_, __) => const ProfileSetupScreen()),

      // Legal screens — public, no auth required
      GoRoute(path: '/legal/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/legal/privacy', builder: (_, __) => const PrivacyScreen()),

      // Authenticated shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/roulette', builder: (_, __) => const RouletteScreen()),
          GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/upgrade', builder: (_, __) => const UpgradeScreen()),
        ],
      ),

      // Profile edit — full-screen, no bottom nav
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),

      // Public profile — no auth required
      GoRoute(
        path: '/dr/:handle',
        builder: (_, state) {
          final handle = state.pathParameters['handle']!;
          return PublicProfileScreen(handle: handle);
        },
      ),
    ],
  );
});

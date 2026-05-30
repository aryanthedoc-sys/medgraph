import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/auth_storage.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_choice_screen.dart';
import '../../features/auth/screens/student_register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/doctor_register_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/proof_upload_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/roulette/screens/roulette_screen.dart';
import '../../features/sessions/screens/sessions_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/followers_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/payments/screens/upgrade_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/landing/screens/about_screen.dart';
import '../../features/landing/screens/blog_screen.dart';
import '../../features/landing/screens/contact_screen.dart';
import '../../features/landing/screens/allied_health_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/legal/screens/privacy_screen.dart';
import '../../shared/services/notification_service.dart';
import '../scaffold/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn   = AuthStorage.isLoggedIn;
      final loc          = state.matchedLocation;
      final isPublicRoute =
          loc.startsWith('/register') ||
          loc == '/onboarding' ||
          loc == '/' ||
          loc.startsWith('/legal') ||
          loc.startsWith('/dr/') ||
          loc == '/about' ||
          loc == '/blog' ||
          loc == '/contact' ||
          loc == '/allied-health';

      if (!isLoggedIn && !isPublicRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) {
          if (kIsWeb) {
            if (!AuthStorage.isLoggedIn) return const LandingScreen();
          }
          return const SplashScreen();
        },
      ),
      GoRoute(path: '/onboarding',    builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/register',      builder: (_, __) => const RegisterChoiceScreen()),
      GoRoute(
        path: '/register/unified',
        builder: (_, state) {
          final userType = state.extra as String?;
          return StudentRegisterScreen(userType: userType);
        },
      ),
      // Legacy student route — redirects to unified screen
      GoRoute(
        path: '/register/student',
        builder: (_, state) {
          final userType = state.extra as String? ?? 'student_mbbs';
          return StudentRegisterScreen(userType: userType);
        },
      ),
      GoRoute(
        path: '/register/otp',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return OTPScreen(
              email:    extra['email']    as String? ?? '',
              name:     extra['name']     as String?,
              userType: extra['userType'] as String?,
            );
          }
          return OTPScreen(email: extra as String? ?? '');
        },
      ),
      GoRoute(path: '/register/doctor',        builder: (_, __) => const DoctorRegisterScreen()),
      GoRoute(path: '/register/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/register/proof-upload',  builder: (_, __) => const ProofUploadScreen()),

      // Legal screens — public
      GoRoute(path: '/legal/terms',    builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/legal/privacy',  builder: (_, __) => const PrivacyScreen()),

      // Company pages — public
      GoRoute(path: '/about',          builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/blog',           builder: (_, __) => const BlogScreen()),
      GoRoute(path: '/contact',        builder: (_, __) => const ContactScreen()),
      GoRoute(path: '/allied-health',  builder: (_, __) => const AlliedHealthScreen()),

      // Authenticated shell with bottom nav / sidebar
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/feed',        builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/roulette',    builder: (_, __) => const RouletteScreen()),
          GoRoute(path: '/sessions',    builder: (_, __) => const SessionsScreen()),
          GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/search',      builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/upgrade',     builder: (_, __) => const UpgradeScreen()),
        ],
      ),

      // Full-screen screens (no bottom nav)
      GoRoute(path: '/profile/edit',   builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/settings',       builder: (_, __) => const SettingsScreen()),

      // Other user profiles (full-screen)
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),

      // Followers / Following
      GoRoute(
        path: '/profile/:userId/followers',
        builder: (_, state) => FollowersScreen(
          userId: state.pathParameters['userId']!,
          mode: 'followers',
        ),
      ),
      GoRoute(
        path: '/profile/:userId/following',
        builder: (_, state) => FollowersScreen(
          userId: state.pathParameters['userId']!,
          mode: 'following',
        ),
      ),

      // Public profile (legacy handle-based)
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

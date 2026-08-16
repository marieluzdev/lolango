import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lolango_v2/features/auth/presentation/screens/login_screen.dart';
import 'package:lolango_v2/features/auth/presentation/screens/splash_screen.dart';
import 'package:lolango_v2/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lolango_v2/features/main/presentation/screens/main_shell.dart';
import 'package:lolango_v2/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/profile_preview_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/settings_screen.dart';
import 'package:lolango_v2/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:lolango_v2/features/profile/presentation/viewmodels/profile_status_provider.dart';

final pendingFirstNameProvider = StateProvider<String?>((ref) => null);

/// A [ChangeNotifier] that fires whenever auth state changes,
/// so GoRouter re-evaluates its redirect without being fully reconstructed.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Listen to auth changes
    ref.listen(authViewModelProvider, (_, _) => notifyListeners());
    // Listen to profile status changes
    ref.listen(profileStatusProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final refreshNotifier = _RouterRefreshNotifier(ref);

  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final profileStatus = ref.read(profileStatusProvider);

      final isAuthenticated = authState.valueOrNull != null;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuthenticated) {
        if (isGoingToLogin) return null;
        return '/login';
      }

      if (profileStatus.isLoading) {
        if (isGoingToLogin || isGoingToSplash) {
          return null; // Reste sur login ou splash pendant le chargement
        }
        return '/'; // Splash screen
      }

      final profileCompleted = profileStatus.valueOrNull ?? false;

      if (isGoingToSplash) {
        return profileCompleted ? '/home' : '/onboarding';
      }

      if (!profileCompleted && !isGoingToOnboarding) {
        final firstName = ref.read(pendingFirstNameProvider);
        if (firstName != null && firstName.trim().isNotEmpty) {
          return '/onboarding?firstName=${Uri.encodeComponent(firstName.trim())}';
        }
        return '/onboarding';
      }

      if (profileCompleted && (isGoingToLogin || isGoingToOnboarding)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingFlowScreen(
          initialFirstName: state.uri.queryParameters['firstName'],
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile-photos',
        builder: (context, state) => const ProfilePhotosScreen(),
      ),
      GoRoute(
        path: '/profile-preview',
        builder: (context, state) => const ProfilePreviewScreen(),
      ),
      GoRoute(
        path: '/user-profile/:id',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          final userName = state.extra as String?;
          return UserProfileScreen(userId: userId, userName: userName);
        },
      ),
    ],
  );
});

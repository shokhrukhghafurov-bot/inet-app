import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/locations/presentation/locations_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../shared/layout/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionController = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: sessionController,
    redirect: (context, state) {
      final status = sessionController.status;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/splash';

      if (status == SessionStatus.initializing && path != '/splash') {
        return '/splash';
      }

      if (status == SessionStatus.unauthenticated && path != '/login') {
        return '/login';
      }

      if (status == SessionStatus.authenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/locations',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LocationsScreen(),
            ),
          ),
          GoRoute(
            path: '/subscription',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SubscriptionScreen(),
            ),
          ),
          GoRoute(
            path: '/devices',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DevicesScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

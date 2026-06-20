import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/setup/setup_flow_screen.dart';
import '../../features/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.setup,
        name: 'setup',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const SetupFlowScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    ],
  );
});

CustomTransitionPage<T> _buildPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String setup = '/setup';
  static const String home = '/home';
}

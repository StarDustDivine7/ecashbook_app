import 'package:ecashbook_app/main.dart';
import 'package:ecashbook_app/shared/main_layout.dart' show MainLayout;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecashbook_app/features/auth/login_page.dart';
import 'package:ecashbook_app/features/onboarding/introduction_screen.dart';
import 'package:ecashbook_app/features/permissions/permission_screen.dart';
import 'package:ecashbook_app/features/security/app_passcode_screen.dart';
import 'package:ecashbook_app/features/security/pin_unlock_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SplashScreen(),
        ),
      ),
      // Onboarding
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const IntroductionScreen(),
        ),
      ),
      // Permissions
      GoRoute(
        path: '/permissions',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PermissionScreen(),
        ),
      ),
      // App Passcode
      GoRoute(
        path: '/app-passcode',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AppPasscodeScreen(),
        ),
      ),
      // PIN Unlock Screen
      GoRoute(
        path: '/pin-unlock',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PinUnlockScreen(),
        ),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      // Dashboard
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MainLayout(),
        ),
      ),
      // Add more routes here...
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    ),
  );
}

// Bottom menu is already included in MainLayout
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecashbook_app/features/onboarding/introduction_screen.dart';
import 'package:ecashbook_app/features/auth/login_page.dart';
import 'package:ecashbook_app/shared/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecashbook_app/core/prefs_keys.dart';

class _StartupResolver extends StatelessWidget {
  const _StartupResolver({super.key});

  @override
  Widget build(BuildContext context) {
    // Add your startup logic here
    // For example:
    // 1. Check if user is logged in
    // 2. Check if it's first launch (show introduction)
    // 3. Redirect accordingly

    // Redirect to login using GoRouter (pages-safe)
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(PrefKeys.onboardingCompleted) ?? false;
      if (!hasCompletedOnboarding) {
        GoRouter.of(context).go('/introduction');
      } else {
        GoRouter.of(context).go('/login');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/resolver',
    routes: [
      GoRoute(
        path: '/resolver',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: _lazyLoad(
            () => const _StartupResolver(),
          ),
        ),
      ),
      GoRoute(
        path: '/introduction',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: _lazyLoad(
            () => const IntroductionScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: _lazyLoad(() => const LoginPage()),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: _lazyLoad(() => MainLayout()),
        ),
      ),
      // Add other routes here
    ],
  );

  static Widget _lazyLoad(Widget Function() builder) {
    return FutureBuilder(
      future: Future.microtask(builder),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data ?? const SizedBox.shrink();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

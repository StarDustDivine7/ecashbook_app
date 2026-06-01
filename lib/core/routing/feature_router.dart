import 'package:ecashbook_app/features/auth/login_page.dart';
import 'package:ecashbook_app/shared/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeatureRouter {
  static final List<RouteBase> routes = [
    // Auth Routes
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: _lazyLoad(
          () => const LoginPage(),
          'login',
        ),
      ),
    ),
    // Dashboard Route (serve within app shell)
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) {
        final qp = state.uri.queryParameters;
        final index = int.tryParse(qp['index'] ?? '') ?? 2;
        final taskId = qp['taskId'];
        final requestId = qp['requestId'];
        return MaterialPage(
          key: state.pageKey,
          child: _lazyLoad(
            () => MainLayout(
                initialIndex: index, taskId: taskId, requestId: requestId),
            'dashboard',
          ),
        );
      },
    ),
    // Add more feature routes here
  ];

  static Widget _lazyLoad(Widget Function() builder, String featureName) {
    return FutureBuilder(
      future: Future.delayed(Duration.zero),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

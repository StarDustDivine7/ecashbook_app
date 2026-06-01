import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../../features/auth/auth_provider.dart';

class LogoutHandler {
  /// Handle logout with API call and navigation
  /// This method should be used for manual logout (user initiated)
  static Future<void> performLogout(BuildContext context, WidgetRef ref) async {
    try {
      debugPrint('🚪 LogoutHandler: Starting logout process');

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return const Dialog(
              backgroundColor: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF422F90)),
                    SizedBox(height: 16),
                    Text(
                      'Logging out...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      // Call logout through auth provider (includes API call)
      await ref.read(authProvider.notifier).logout();

      // Close loading dialog (use rootNavigator to ensure dismissal)
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      // Navigate to login
      await _navigateToLogin(context);
    } catch (e) {
      debugPrint('❌ LogoutHandler error: $e');

      // Close any open dialogs
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      // Force logout locally and navigate
      await _forceLogoutAndNavigate(context, ref);
    }
  }

  /// Handle unauthorized response (401 errors)
  /// This method should be used when API returns unauthorized
  static Future<void> handleUnauthorizedResponse(
      BuildContext context, WidgetRef ref) async {
    try {
      debugPrint('🔒 LogoutHandler: Handling unauthorized response');

      // Check if already logged out to prevent looping
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('user_logged_in') ?? false;
      if (!isLoggedIn) {
        debugPrint('🔒 LogoutHandler: Already logged out, skipping');
        return;
      }

      // Update Riverpod auth state immediately so no widget re-triggers the flow
      try {
        ref.read(authProvider.notifier).forceLoggedOut();
      } catch (_) {}

      // Clear all app data
      await AuthService.clearAllAppData();

      // Navigate to login
      if (context.mounted) await _navigateToLogin(context);
    } catch (e) {
      debugPrint('❌ LogoutHandler unauthorized error: $e');
      await _forceLogoutAndNavigate(context, ref);
    }
  }

  /// Force logout without API call (for error scenarios)
  static Future<void> _forceLogoutAndNavigate(
      BuildContext context, WidgetRef ref) async {
    try {
      // Clear all data locally (this will automatically update auth state when provider reinitializes)
      await AuthService.clearAllAppData();

      // Navigate to login
      await _navigateToLogin(context);
    } catch (e) {
      debugPrint('❌ Force logout error: $e');
      // Last resort - try to navigate anyway
      if (context.mounted) {
        try {
          context.go('/login');
        } catch (_) {}
      }
    }
  }

  /// Navigate to login screen with error handling
  static Future<void> _navigateToLogin(BuildContext context) async {
    if (!context.mounted) return;
    try {
      context.go('/login');
      debugPrint('✅ LogoutHandler: Navigation to login completed');
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }
}

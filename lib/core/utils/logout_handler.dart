import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate to login
      await _navigateToLogin(context);
      
    } catch (e) {
      debugPrint('❌ LogoutHandler error: $e');
      
      // Close any open dialogs
      if (context.mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      
      // Force logout locally and navigate
      await _forceLogoutAndNavigate(context, ref);
    }
  }

  /// Handle unauthorized response (401 errors)
  /// This method should be used when API returns unauthorized
  static Future<void> handleUnauthorizedResponse(BuildContext context, WidgetRef ref) async {
    try {
      debugPrint('🔒 LogoutHandler: Handling unauthorized response');
      
      // Clear all app data
      await AuthService.clearAllAppData();
      
      // Update auth state
      ref.read(authProvider.notifier).state = ref.read(authProvider.notifier).state.copyWith(
        isLoggedIn: false,
        errorMessage: 'Session expired. Please login again.',
      );
      
      // Navigate to login
      await _navigateToLogin(context);
      
    } catch (e) {
      debugPrint('❌ LogoutHandler unauthorized error: $e');
      await _forceLogoutAndNavigate(context, ref);
    }
  }

  /// Force logout without API call (for error scenarios)
  static Future<void> _forceLogoutAndNavigate(BuildContext context, WidgetRef ref) async {
    try {
      // Clear all data locally
      await AuthService.clearAllAppData();
      
      // Update auth state
      ref.read(authProvider.notifier).state = ref.read(authProvider.notifier).state.copyWith(
        isLoggedIn: false,
        errorMessage: null,
      );
      
      // Navigate to login
      await _navigateToLogin(context);
      
    } catch (e) {
      debugPrint('❌ Force logout error: $e');
      // Last resort - try to navigate anyway
      if (context.mounted) {
        try {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } catch (_) {}
      }
    }
  }

  /// Navigate to login screen with error handling
  static Future<void> _navigateToLogin(BuildContext context) async {
    if (!context.mounted) return;
    
    try {
      // Small delay to ensure state updates are processed
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        debugPrint('✅ LogoutHandler: Navigation to login completed');
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      
      // Fallback navigation
      if (context.mounted) {
        try {
          Navigator.pushReplacementNamed(context, '/login');
        } catch (fallbackError) {
          debugPrint('❌ Fallback navigation failed: $fallbackError');
        }
      }
    }
  }
}
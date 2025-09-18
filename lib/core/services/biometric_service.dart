import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  static final LocalAuthentication _localAuth = LocalAuthentication();

  // ✅ REUSED: Existing constants
  static const Duration _authRequiredTimeout = Duration(minutes: 2);
  static const Duration _longBreakTimeout = Duration(minutes: 5);
  static const String _lastActivePageKey = 'last_active_page';
  static const String _backgroundTimeKey = 'background_timestamp';
  static const String _lastAuthTimeKey = 'last_biometric_auth';

  // ✅ REUSED: All existing authentication methods - no changes needed
  static Future<bool> isDeviceSecure() async {
    try {
      debugPrint('🔍 Checking if device is secure...');

      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        debugPrint('❌ Device does not support authentication');
        return false;
      }

      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      debugPrint('📱 Can check biometrics: $canCheckBiometrics');

      return canCheckBiometrics;
    } catch (e) {
      debugPrint('❌ Error checking device security: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      debugPrint('📋 Getting available biometric types...');
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

      for (BiometricType type in availableBiometrics) {
        debugPrint('✅ Available: $type');
      }

      return availableBiometrics;
    } catch (e) {
      debugPrint('❌ Error getting biometrics: $e');
      return [];
    }
  }

  static Future<BiometricResult> authenticateWithSystem({
    String reason = 'Please authenticate to access EcashBook',
  }) async {
    try {
      debugPrint('🔐 Starting system authentication...');

      final bool isSecure = await isDeviceSecure();
      if (!isSecure) {
        debugPrint('❌ Device is not secure - no authentication available');
        return BiometricResult(
          success: false,
          errorMessage: 'No screen lock set up on device. Please set up PIN, Pattern, Password, or Biometric authentication in device settings.',
          errorCode: BiometricErrorCode.noAuthenticationSet,
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (didAuthenticate) {
        debugPrint('✅ Authentication successful');
        await _recordSuccessfulAuthentication();

        final String nextPage = await getSmartNavigationDestination();

        return BiometricResult(
          success: true,
          authMethod: await _getUsedAuthMethod(),
          navigationDestination: nextPage,
        );
      } else {
        debugPrint('❌ Authentication failed or cancelled');
        return BiometricResult(
          success: false,
          errorMessage: 'Authentication cancelled or failed',
          errorCode: BiometricErrorCode.cancelled,
        );
      }

    } on PlatformException catch (e) {
      debugPrint('❌ Platform exception during authentication: $e');
      return _handlePlatformException(e);
    } catch (e) {
      debugPrint('❌ General error during authentication: $e');
      return BiometricResult(
        success: false,
        errorMessage: 'Authentication error: $e',
        errorCode: BiometricErrorCode.unknown,
      );
    }
  }

  // ✅ ENHANCED: Smart navigation with restart type priority
  static Future<String> getSmartNavigationDestination() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ PRIORITY 1: Check restart type first
      final String? restartType = prefs.getString('last_restart_type');
      final String lastActivePage = prefs.getString(_lastActivePageKey) ?? '/dashboard';

      debugPrint('🧭 Smart navigation analysis:');
      debugPrint('   - Restart type: $restartType');
      debugPrint('   - Last active page: $lastActivePage');

      // ✅ NEW: Restart type based navigation (highest priority)
      if (restartType != null) {
        switch (restartType) {
          case 'screen_state':
            debugPrint('📱 Screen state change - returning to: $lastActivePage');
            return lastActivePage;

          case 'app_background':
            debugPrint('📱 App background - returning to: $lastActivePage');
            return lastActivePage;

          case 'ram_clear':
            debugPrint('🧹 RAM clear - going to dashboard');
            return '/dashboard';

          case 'phone_restart':
            debugPrint('📱 Phone restart - going to dashboard');
            return '/dashboard';

          default:
            debugPrint('❓ Unknown restart type: $restartType');
            break;
        }
      }

      // ✅ FALLBACK: Use existing time-based logic
      final String? backgroundTimeString = prefs.getString(_backgroundTimeKey);

      if (backgroundTimeString == null) {
        debugPrint('🧭 No background time found - going to dashboard');
        return '/dashboard';
      }

      final DateTime backgroundTime = DateTime.parse(backgroundTimeString);
      final DateTime currentTime = DateTime.now();
      final Duration timeSinceBackground = currentTime.difference(backgroundTime);

      debugPrint('⏱️ Time since background: ${timeSinceBackground.inMinutes} minutes');

      if (timeSinceBackground > _longBreakTimeout) {
        debugPrint('🧭 Long break (${timeSinceBackground.inMinutes}min) - going to dashboard');
        return '/dashboard';
      } else {
        debugPrint('🧭 Quick resume (${timeSinceBackground.inMinutes}min) - returning to $lastActivePage');
        return lastActivePage;
      }
    } catch (e) {
      debugPrint('❌ Error in smart navigation: $e');
      return '/dashboard';
    }
  }

  // ✅ REUSED: All existing utility methods - no changes needed
  static Future<void> saveLastActivePage(String pageName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActivePageKey, pageName);
      debugPrint('📝 Saved last active page: $pageName');
    } catch (e) {
      debugPrint('⚠️ Failed to save last active page: $e');
    }
  }

  static Future<void> saveBackgroundTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String timestamp = DateTime.now().toIso8601String();
      await prefs.setString(_backgroundTimeKey, timestamp);
      debugPrint('📝 Saved background time: $timestamp');
    } catch (e) {
      debugPrint('⚠️ Failed to save background time: $e');
    }
  }

  static Future<void> clearNavigationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivePageKey);
      await prefs.remove(_backgroundTimeKey);
      debugPrint('🧹 Navigation data cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear navigation data: $e');
    }
  }

  // ✅ REUSED: All existing error handling - no changes needed
  static BiometricResult _handlePlatformException(PlatformException e) {
    String errorMessage;
    BiometricErrorCode errorCode;

    switch (e.code) {
      case 'NotAvailable':
        errorMessage = 'Biometric authentication not available on this device';
        errorCode = BiometricErrorCode.notAvailable;
        break;
      case 'NotEnrolled':
        errorMessage = 'No biometric credentials enrolled. Please set up fingerprint or face authentication in device settings';
        errorCode = BiometricErrorCode.notEnrolled;
        break;
      case 'PasscodeNotSet':
        errorMessage = 'No screen lock set up. Please set up PIN, Pattern, or Password in device settings';
        errorCode = BiometricErrorCode.noAuthenticationSet;
        break;
      case 'DeviceNotSecure':
        errorMessage = 'Device is not secure. Please enable screen lock in device settings';
        errorCode = BiometricErrorCode.deviceNotSecure;
        break;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        errorMessage = 'Too many failed attempts. Please try again later or use device PIN/Pattern';
        errorCode = BiometricErrorCode.lockedOut;
        break;
      case 'UserCancel':
        errorMessage = 'Authentication cancelled by user';
        errorCode = BiometricErrorCode.cancelled;
        break;
      case 'Timeout':
        errorMessage = 'Authentication timeout. Please try again';
        errorCode = BiometricErrorCode.timeout;
        break;
      default:
        errorMessage = 'Authentication failed: ${e.message ?? 'Unknown error'}';
        errorCode = BiometricErrorCode.unknown;
    }

    return BiometricResult(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  static Future<String> _getUsedAuthMethod() async {
    try {
      final List<BiometricType> available = await getAvailableBiometrics();

      if (available.contains(BiometricType.fingerprint)) {
        return 'fingerprint';
      } else if (available.contains(BiometricType.face)) {
        return 'face';
      } else if (available.contains(BiometricType.iris)) {
        return 'iris';
      } else {
        return 'device_credentials';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<void> _recordSuccessfulAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String timestamp = DateTime.now().toIso8601String();
      await prefs.setString(_lastAuthTimeKey, timestamp);
      debugPrint('📝 Recorded successful authentication at $timestamp');
    } catch (e) {
      debugPrint('⚠️ Failed to record authentication: $e');
    }
  }

  static Future<DateTime?> getLastAuthenticationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? timestamp = prefs.getString(_lastAuthTimeKey);

      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Failed to get last authentication time: $e');
      return null;
    }
  }

  static Future<bool> isAuthenticationRequired({
    Duration? timeout,
  }) async {
    try {
      final Duration actualTimeout = timeout ?? _authRequiredTimeout;
      final DateTime? lastAuth = await getLastAuthenticationTime();

      if (lastAuth == null) {
        debugPrint('🔐 No previous authentication - required');
        return true;
      }

      final Duration timeSinceAuth = DateTime.now().difference(lastAuth);
      final bool isRequired = timeSinceAuth > actualTimeout;

      debugPrint('⏱️ Time since last auth: ${timeSinceAuth.inMinutes} minutes');
      debugPrint('🔐 Authentication required: $isRequired');

      return isRequired;
    } catch (e) {
      debugPrint('⚠️ Error checking authentication requirement: $e');
      return true;
    }
  }

  static Future<void> clearAuthenticationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastAuthTimeKey);
      await clearNavigationData();
      debugPrint('🧹 Cleared biometric authentication data');
    } catch (e) {
      debugPrint('⚠️ Failed to clear authentication data: $e');
    }
  }

  static Future<Map<String, dynamic>> getAuthenticationInfo() async {
    final bool isSecure = await isDeviceSecure();
    final List<BiometricType> available = await getAvailableBiometrics();
    final DateTime? lastAuth = await getLastAuthenticationTime();

    return {
      'device_secure': isSecure,
      'available_biometrics': available.map((e) => e.toString()).toList(),
      'last_authentication': lastAuth?.toIso8601String(),
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
    };
  }
}

// ✅ REUSED: Existing result classes - no changes needed
class BiometricResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorCode? errorCode;
  final String? authMethod;
  final String? navigationDestination;

  BiometricResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.authMethod,
    this.navigationDestination,
  });

  @override
  String toString() {
    return 'BiometricResult(success: $success, errorMessage: $errorMessage, authMethod: $authMethod, destination: $navigationDestination)';
  }
}

enum BiometricErrorCode {
  notAvailable,
  notEnrolled,
  noAuthenticationSet,
  deviceNotSecure,
  lockedOut,
  cancelled,
  timeout,
  unknown,
}

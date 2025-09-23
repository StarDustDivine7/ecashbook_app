import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BiometricErrorCode {
  noAuthenticationSet,
  notAvailable,
  notEnrolled,
  deviceNotSecure,
  lockedOut,
  cancelled,
  timeout,
  unknown,
}

class BiometricResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorCode? errorCode;
  final String? authMethod;

  const BiometricResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.authMethod,
  });

  BiometricResult copyWith({
    bool? success,
    String? errorMessage,
    BiometricErrorCode? errorCode,
    String? authMethod,
  }) {
    return BiometricResult(
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      authMethod: authMethod ?? this.authMethod,
    );
  }
}

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const _kLastAuthTime = 'last_auth_time';
  static const _kLastActivePage = 'last_active_page';
  static const _kLastRestartType = 'last_restart_type';

  // Device capability
  static Future<bool> isDeviceSecure() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final enrolled = await hasAnyEnrollment();
      return isSupported && (canCheck || enrolled);
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const <BiometricType>[];
    }
  }

  static Future<bool> hasAnyEnrollment() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Authenticate
  static Future<BiometricResult> authenticateWithSystem({
    String reason = 'Please authenticate',
  }) async {
    try {
      final supports = await _auth.isDeviceSupported();
      if (!supports) {
        return const BiometricResult(
          success: false,
          errorMessage: 'Authentication not supported on this device',
          errorCode: BiometricErrorCode.notAvailable,
        );
      }

      final didAuth = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (didAuth) {
        await _touchLastAuthTime();
        final hasBio = await hasAnyEnrollment();
        return BiometricResult(
          success: true,
          authMethod: hasBio ? 'biometric' : 'device_credential',
        );
      }
      return const BiometricResult(
        success: false,
        errorMessage: 'Authentication cancelled',
        errorCode: BiometricErrorCode.cancelled,
      );
    } on PlatformException catch (e) {
      return BiometricResult(
        success: false,
        errorMessage: e.message ?? 'Authentication failed',
        errorCode: _mapPlatformError(e),
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        errorMessage: 'Authentication error: $e',
        errorCode: BiometricErrorCode.unknown,
      );
    }
  }

  // Re-auth timeout helpers
  static Future<bool> isAuthenticationRequired({Duration? timeout}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastAuthTime);
    if (last == null) return true;
    final dt = DateTime.fromMillisecondsSinceEpoch(last);
    final lim = timeout ?? const Duration(minutes: 2);
    return DateTime.now().difference(dt) > lim;
  }

  static Future<DateTime?> getLastAuthenticationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastAuthTime);
    if (last == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(last);
  }

  static Future<void> clearAuthenticationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastAuthTime);
  }

  static Future<Map<String, dynamic>> getAuthenticationInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastAuthTime);
    final supported = await _safeIsSupported();
    final hasBio = await _safeHasBio();
    return {
      'supported': supported,
      'has_biometrics': hasBio,
      'last_auth_time': last,
    };
  }

  // Navigation-related utilities used by login and biometric screens

  static Future<void> saveLastActivePage(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastActivePage, route);
  }

  static Future<void> saveLastRestartType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastRestartType, type);
  }

  // Added to fix undefined method in login_page.dart
  static Future<void> clearNavigationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastActivePage);
    await prefs.remove(_kLastRestartType);
  }

  // Used by BiometricScreen for smart routing after unlock
  static Future<String> getSmartNavigationDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final restartType = prefs.getString(_kLastRestartType) ?? 'unknown';
    final lastActive = prefs.getString(_kLastActivePage) ?? '/dashboard';

    switch (restartType) {
      case 'screen_state':
      case 'app_background':
        return lastActive;
      case 'ram_clear':
      case 'phone_restart':
      default:
        return '/dashboard';
    }
  }

  // Internal helpers
  static Future<void> _touchLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastAuthTime, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> _safeIsSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _safeHasBio() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static BiometricErrorCode _mapPlatformError(PlatformException e) {
    final code = e.code.toLowerCase();
    if (code.contains('lockedout') || code.contains('lockout')) {
      return BiometricErrorCode.lockedOut;
    }
    if (code.contains('notavailable') || code.contains('nosupport')) {
      return BiometricErrorCode.notAvailable;
    }
    if (code.contains('notenrolled') ||
        code.contains('noenrolled') ||
        code.contains('passcode not set')) {
      return BiometricErrorCode.notEnrolled;
    }
    if (code.contains('notsetup') ||
        code.contains('notset') ||
        code.contains('devicepasscodenotset')) {
      return BiometricErrorCode.noAuthenticationSet;
    }
    if (code.contains('canceled') ||
        code.contains('cancelled') ||
        code.contains('usercancel')) {
      return BiometricErrorCode.cancelled;
    }
    if (code.contains('timeout')) {
      return BiometricErrorCode.timeout;
    }
    return BiometricErrorCode.unknown;
  }
}

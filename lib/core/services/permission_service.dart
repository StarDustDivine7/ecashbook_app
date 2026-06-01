import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all required permissions for the app
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    debugPrint('🔐 Requesting all app permissions...');

    final Map<Permission, PermissionStatus> results = {};

    // Define required permissions based on Android version
    final List<Permission> permissions = _getRequiredPermissions();

    try {
      // Request permissions one by one for better control
      for (Permission permission in permissions) {
        debugPrint('📋 Requesting permission: $permission');

        final status = await permission.request();
        results[permission] = status;

        debugPrint('✅ Permission $permission: $status');

        // Small delay for better UX
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Log results
      _logPermissionResults(results);

      return results;

    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');

      // Return failed results
      for (Permission permission in permissions) {
        results[permission] = PermissionStatus.denied;
      }
      return results;
    }
  }

  /// Get required permissions based on Android version
  static List<Permission> _getRequiredPermissions() {
    final List<Permission> permissions = [];

    // Location permissions (All Android versions)
    permissions.add(Permission.location);
    permissions.add(Permission.locationWhenInUse);

    // Camera permission (All Android versions)
    permissions.add(Permission.camera);

    // Storage permissions (Android version dependent)
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need media permissions
      permissions.add(Permission.photos);
      permissions.add(Permission.videos);
      permissions.add(Permission.audio);

      // For older Android versions, we need storage permission
      permissions.add(Permission.storage);
      permissions.add(Permission.manageExternalStorage);
    } else {
      permissions.add(Permission.storage);
    }

    // Notification permission (Android 13+ requires explicit permission)
    permissions.add(Permission.notification);

    // Biometric permissions
    permissions.add(Permission.sensors);

    return permissions;
  }

  /// Check if all critical permissions are granted
  static Future<bool> areAllCriticalPermissionsGranted() async {
    debugPrint('🔍 Checking critical permissions...');

    final criticalPermissions = [
      Permission.location,
      Permission.camera,
    ];

    for (Permission permission in criticalPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        debugPrint('❌ Critical permission not granted: $permission');
        return false;
      }
    }

    debugPrint('✅ All critical permissions granted');
    return true;
  }

  /// Check location permission specifically
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      debugPrint('📍 Location permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      return false;
    }
  }

  /// Check camera permission specifically
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      debugPrint('📸 Camera permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking camera permission: $e');
      return false;
    }
  }

  /// Check storage permission specifically
  static Future<bool> isStoragePermissionGranted() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        // Check media permissions for Android 13+
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;

        status = photosStatus.isGranted || storageStatus.isGranted
            ? PermissionStatus.granted
            : PermissionStatus.denied;
      } else {
        status = await Permission.storage.status;
      }

      debugPrint('💾 Storage permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking storage permission: $e');
      return false;
    }
  }

  /// Check notification permission specifically
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final status = await Permission.notification.status;
      debugPrint('🔔 Notification permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// Request location permission with high accuracy
  static Future<LocationPermissionResult> requestLocationWithAccuracy() async {
    debugPrint('🎯 Requesting precise location permission...');

    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return LocationPermissionResult(
          isGranted: false,
          isPrecise: false,
          error: 'Location services are disabled. Please enable GPS.',
        );
      }

      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permission denied');
        return LocationPermissionResult(
          isGranted: false,
          isPrecise: false,
          error: 'Location permission denied',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        return LocationPermissionResult(
          isGranted: false,
          isPrecise: false,
          error: 'Location permission permanently denied. Please enable in settings.',
        );
      }

      // Check accuracy level
      LocationAccuracyStatus accuracyStatus = await Geolocator.getLocationAccuracy();
      bool isPrecise = accuracyStatus == LocationAccuracyStatus.precise;

      debugPrint('✅ Location permission granted, precise: $isPrecise');

      return LocationPermissionResult(
        isGranted: true,
        isPrecise: isPrecise,
        error: null,
      );

    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return LocationPermissionResult(
        isGranted: false,
        isPrecise: false,
        error: 'Error requesting location: $e',
      );
    }
  }

  /// Open app settings for manual permission management
  static Future<void> openAppSettings() async {
    debugPrint('⚙️ Opening app settings...');
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
    }
  }

  /// Get permission status summary for debugging
  static Future<Map<String, dynamic>> getPermissionSummary() async {
    debugPrint('📊 Getting permission summary...');

    return {
      'location': await isLocationPermissionGranted(),
      'camera': await isCameraPermissionGranted(),
      'storage': await isStoragePermissionGranted(),
      'notification': await isNotificationPermissionGranted(),
      'all_critical': await areAllCriticalPermissionsGranted(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Log permission results for debugging
  static void _logPermissionResults(Map<Permission, PermissionStatus> results) {
    debugPrint('📋 Permission Results Summary:');
    results.forEach((permission, status) {
      final emoji = status.isGranted ? '✅' : '❌';
      debugPrint('   $emoji $permission: $status');
    });
  }

  /// Handle permission denied scenarios
  static void handlePermissionDenied(BuildContext context, Permission permission) {
    String message;
    String title;

    switch (permission) {
      case Permission.location:
        title = 'Location Permission Required';
        message = 'Location access is needed for accurate attendance tracking. Please enable it in settings.';
        break;
      case Permission.camera:
        title = 'Camera Permission Required';
        message = 'Camera access is needed for profile photos and face authentication. Please enable it in settings.';
        break;
      case Permission.storage:
        title = 'Storage Permission Required';
        message = 'Storage access is needed to save and access your documents. Please enable it in settings.';
        break;
      case Permission.notification:
        title = 'Notification Permission Required';
        message = 'Notifications help you stay updated with important work information. Please enable them in settings.';
        break;
      default:
        title = 'Permission Required';
        message = 'This permission is required for the app to work properly. Please enable it in settings.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

/// Result class for location permission requests
class LocationPermissionResult {
  final bool isGranted;
  final bool isPrecise;
  final String? error;

  LocationPermissionResult({
    required this.isGranted,
    required this.isPrecise,
    this.error,
  });

  bool get isSuccess => isGranted && error == null;

  @override
  String toString() {
    return 'LocationPermissionResult(granted: $isGranted, precise: $isPrecise, error: $error)';
  }
}

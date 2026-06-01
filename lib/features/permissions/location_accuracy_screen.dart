import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationAccuracyScreen extends ConsumerStatefulWidget {
  const LocationAccuracyScreen({super.key});

  @override
  ConsumerState<LocationAccuracyScreen> createState() => _LocationAccuracyScreenState();
}

class _LocationAccuracyScreenState extends ConsumerState<LocationAccuracyScreen> {
  bool _isProcessing = false;
  LocationAccuracyStatus? _currentAccuracy;

  @override
  void initState() {
    super.initState();
    _checkCurrentAccuracy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              SizedBox(height: 20),

              // Title
              Text(
                'Location Accuracy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'For better attendance tracking, we recommend using precise location.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              SizedBox(height: 40),

              // Main illustration
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Location illustration
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Color(0xFF422F90).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer circle
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFF422F90).withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(80),
                              ),
                            ),
                            // Middle circle
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFF422F90).withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(60),
                              ),
                            ),
                            // Inner location pin
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Color(0xFF422F90),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Status text
                      Text(
                        _getAccuracyStatusText(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _getAccuracyStatusColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Information cards
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Precise location card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.gps_fixed,
                              color: Colors.green[600],
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Precise Location (Recommended)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'More accurate attendance tracking',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Approximate location card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.location_searching,
                              color: Colors.orange[600],
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Approximate Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Less accurate, may affect attendance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // ✅ UPDATED: Only Enable Precise Location button (Skip removed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _enablePreciseLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF422F90),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Setting up...'),
                    ],
                  )
                      : Text(
                    'Enable Precise Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ✅ REMOVED: Privacy note text completely removed
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkCurrentAccuracy() async {
    try {
      _currentAccuracy = await Geolocator.getLocationAccuracy();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> _enablePreciseLocation() async {
    setState(() => _isProcessing = true);

    try {
      // Request precise location permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationDeniedDialog();
      } else {
        // ✅ Fixed: Use modern LocationSettings instead of deprecated parameters
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: _getLocationSettings(),
        );

        _navigateToLogin();
      }

    } catch (e) {
      _showLocationErrorDialog();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✅ NEW: Get platform-specific location settings
  LocationSettings _getLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        timeLimit: const Duration(seconds: 10), // ✅ Now using proper parameter
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: true,
        timeLimit: const Duration(seconds: 10), // ✅ Now using proper parameter
      );
    } else {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _getAccuracyStatusText() {
    if (_currentAccuracy == null) return 'Checking location accuracy...';

    switch (_currentAccuracy!) {
      case LocationAccuracyStatus.precise:
        return 'Precise location is enabled ✓';
      case LocationAccuracyStatus.reduced:
        return 'Using approximate location';
      default:
        return 'Location accuracy unknown';
    }
  }

  Color _getAccuracyStatusColor() {
    if (_currentAccuracy == LocationAccuracyStatus.precise) {
      return Colors.green[600]!;
    }
    return Colors.orange[600]!;  // ✅ Fixed
  }

  void _showLocationDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Permission Denied'),
        content: Text('Location permission is required for attendance tracking. You can enable it later in device settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            child: Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Error'),
        content: Text('Unable to get your location. Please make sure GPS is enabled and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            child: Text('Continue Anyway'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _enablePreciseLocation();
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

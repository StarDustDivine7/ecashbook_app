import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricLockProvider = ChangeNotifierProvider<BiometricLockService>(
  (ref) => BiometricLockService(),
);

class BiometricLockService extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  DateTime? _lastActiveTime;
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  // Called when app goes to background
  void onPaused() {
    _lastActiveTime = DateTime.now();
  }

  // Called when app comes back to foreground
  Future<void> onResumed() async {
    if (_lastActiveTime == null) return;

    final inactiveDuration = DateTime.now().difference(_lastActiveTime!);

    // Lock only if app inactive > 2 minutes
    if (inactiveDuration.inMinutes >= 2) {
      _isLocked = true;
      notifyListeners();
    }
  }

  // Perform biometric authentication
  Future<bool> authenticate(BuildContext context) async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Biometric authentication not available')),
        );
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to access EcashBook',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        _isLocked = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}

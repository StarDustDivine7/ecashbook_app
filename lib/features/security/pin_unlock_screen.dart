import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants.dart';
import 'pin_provider.dart';

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _isLoading = false;
  String? _errorMessage;
  int _attemptCount = 0;
  static const int _maxAttempts = AppConstants.maxPinAttempts;

  // Biometric authentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setSystemUIOverlay();
    _checkBiometricAndAutoAuthenticate();
  }

  void _setSystemUIOverlay() {
    // Hide system UI overlays to prevent notification bar access
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _restoreSystemUIOverlay() {
    // Restore system UI overlays
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  Future<void> _checkBiometricAndAutoAuthenticate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

      // Check if biometric is available
      bool biometricAvailable = false;
      try {
        biometricAvailable = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
      } catch (e) {
        debugPrint('Error checking biometric availability: $e');
      }

      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled && biometricAvailable;
      });

      // Auto-trigger biometric authentication if enabled
      if (_biometricEnabled && _biometricAvailable && !_isAuthenticating) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _authenticateWithBiometric();
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing biometric: $e');
    }
  }

  @override
  void dispose() {
    _restoreSystemUIOverlay();
    _shakeController.dispose();
    super.dispose();
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });
      HapticFeedback.lightImpact();
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _verifyPin);
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length != 4) {
      _showError('Please enter 4-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHash = prefs.getString('app_passcode_hash') ?? '';
      final enteredHash = _hashPin(_pin);

      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate processing

      if (savedHash == enteredHash) {
        // PIN is correct

        // Clear attempt count and PIN requirement
        await prefs.remove('pin_attempt_count');
        await prefs.remove('app_was_backgrounded');
        await prefs.remove('app_paused_time');
        ref.read(pinProvider.notifier).clearPinRequired();

        // Restore system UI and navigate to dashboard using GoRouter
        _restoreSystemUIOverlay();
        if (mounted) {
          // Use pages-safe navigation
          context.go('/dashboard');
        }
      } else {
        // PIN is incorrect
        _attemptCount++;
        await prefs.setInt('pin_attempt_count', _attemptCount);

        if (_attemptCount >= _maxAttempts) {
          _showError('Too many failed attempts. Please restart the app.');
        } else {
          _showError(
              'Incorrect PIN. ${_maxAttempts - _attemptCount} attempts remaining.');
        }

        _shakeController.forward().then((_) => _shakeController.reset());
        setState(() => _pin = '');
      }
    } catch (e) {
      debugPrint('❌ PIN verification error: $e');
      _showError('Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  Future<void> _authenticateWithBiometric() async {
    debugPrint('🔐 Biometric authentication triggered');
    debugPrint('🔐 _isAuthenticating: $_isAuthenticating');
    debugPrint('🔐 _biometricAvailable: $_biometricAvailable');

    if (_isAuthenticating) return;

    // Check if biometric is available
    if (!_biometricAvailable) {
      _showError('Biometric authentication not available on this device');
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock EcashBook',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        // Clear flags and navigate
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pin_attempt_count');
        await prefs.remove('app_was_backgrounded');
        await prefs.remove('app_paused_time');

        // Save biometric preference if user successfully uses it
        await prefs.setBool('biometric_enabled', true);

        ref.read(pinProvider.notifier).clearPinRequired();

        _restoreSystemUIOverlay();
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Use PIN instead.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      setState(() {
        _errorMessage = 'Biometric unavailable. Use PIN instead.';
        _isAuthenticating = false;
      });
    }
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _exitApp();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF6E48AA),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF422F90), Color(0xFF6E48AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            left: true,
            right: true,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo and Title Section
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 30,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'EcashBook',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter PIN to unlock',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // PIN Input Display
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _errorMessage != null
                                      ? Colors.redAccent.withOpacity(0.8)
                                      : Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  return Container(
                                    width: 14,
                                    height: 14,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index < _pin.length
                                          ? Colors.white
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Error Message
                      SizedBox(
                        height: 20,
                        child: _errorMessage != null
                            ? Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : null,
                      ),

                      const SizedBox(height: 20),

                      // Biometric Authentication Button
                      if (_biometricAvailable)
                        Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isAuthenticating
                                  ? null
                                  : _authenticateWithBiometric,
                              icon: Icon(
                                Icons.fingerprint,
                                color: Colors.white.withOpacity(0.9),
                                size: 22,
                              ),
                              label: Text(
                                _isAuthenticating
                                    ? 'Authenticating...'
                                    : 'Use Biometric',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'or enter PIN below',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Keypad
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          children: [
                            for (final row in [
                              ['1', '2', '3'],
                              ['4', '5', '6'],
                              ['7', '8', '9'],
                              ['', '0', '⌫']
                            ])
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (var key in row)
                                      key.isEmpty
                                          ? const SizedBox(width: 50)
                                          : _buildKeypadButton(
                                              key,
                                              isBackspace: key == '⌫',
                                            ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Loading or Instructions
                      if (_isLoading)
                        Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verifying PIN...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Exit Button
                      TextButton(
                        onPressed: _exitApp,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                        ),
                        child: Text(
                          'Exit App',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String text, {bool isBackspace = false}) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          _removeDigit();
        } else {
          _addDigit(text);
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

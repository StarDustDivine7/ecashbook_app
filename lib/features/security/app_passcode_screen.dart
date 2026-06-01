import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';

class AppPasscodeScreen extends ConsumerStatefulWidget {
  const AppPasscodeScreen({super.key});
  @override
  ConsumerState createState() => _AppPasscodeScreenState();
}

class _AppPasscodeScreenState extends ConsumerState<AppPasscodeScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  String _firstPin = '';
  bool _isSetting = false;
  bool _isConfirming = false;
  String? _error;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  
  // Biometric authentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _load();
    _fadeController.forward();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = (prefs.getString('app_passcode_hash') ?? '').isNotEmpty;
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    
    debugPrint('🔐 Loading app passcode screen...');
    debugPrint('🔐 hasPin: $hasPin');
    debugPrint('🔐 biometricEnabled (saved): $biometricEnabled');
    
    // Check if biometric is available
    bool biometricAvailable = false;
    try {
      biometricAvailable = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      debugPrint('🔐 biometricAvailable: $biometricAvailable');
    } catch (e) {
      debugPrint('❌ Error checking biometric availability: $e');
    }
    
    setState(() {
      _isSetting = !hasPin;
      _biometricAvailable = biometricAvailable;
      _biometricEnabled = biometricEnabled && biometricAvailable;
    });
    
    debugPrint('🔐 _isSetting: $_isSetting');
    debugPrint('🔐 _biometricAvailable: $_biometricAvailable');
    debugPrint('🔐 _biometricEnabled: $_biometricEnabled');
    
    // Auto-trigger biometric authentication when unlocking (not setting up) and if enabled
    if (!_isSetting && _biometricEnabled && _biometricAvailable && !_isAuthenticating) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _authenticateWithBiometric();
        }
      });
    }
  }

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = null;
      });
      HapticFeedback.lightImpact();
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _submit);
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _submit() async {
    if (_pin.length != 4) {
      _showError('Enter 4 digits');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (_isSetting) {
      if (!_isConfirming) {
        // First PIN entry - store it and ask for confirmation
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
          _error = null;
        });
      } else {
        // Confirming PIN - check if they match
        if (_pin == _firstPin) {
          // PINs match - save and proceed
          await prefs.setString('app_passcode_hash', _hash(_pin));
          await prefs.setBool('biometric_enabled', _biometricEnabled);
          _next();
        } else {
          // PINs don't match - show error and restart
          _showError('PINs do not match');
          _shakeController.forward().then((_) => _shakeController.reset());
          setState(() {
            _pin = '';
            _firstPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Unlocking with existing PIN
      final saved = prefs.getString('app_passcode_hash') ?? '';
      if (saved == _hash(_pin)) {
        _next();
      } else {
        _showError('Incorrect PIN');
        _shakeController.forward().then((_) => _shakeController.reset());
        setState(() => _pin = '');
      }
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
    HapticFeedback.heavyImpact();
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
        // Save biometric preference if user successfully uses it
        if (!_isSetting) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_enabled', true);
        }
        _next();
      } else {
        setState(() {
          _error = 'Authentication failed. Use PIN instead.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      setState(() {
        _error = 'Biometric unavailable. Use PIN instead.';
        _isAuthenticating = false;
      });
    }
  }
  
  void _next() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_setup_completed', true);

    // Clear PIN requirement flags
    await prefs.remove('app_was_backgrounded');
    await prefs.remove('app_paused_time');

    final hasEverLoggedIn = prefs.getBool('has_ever_logged_in') ?? false;
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime && !hasEverLoggedIn) {
      context.go('/login');
    } else {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6E48AA),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF422F90), Color(0xFF6E48AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back button for confirmation step
                      if (_isSetting && _isConfirming)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _pin = '';
                                _firstPin = '';
                                _isConfirming = false;
                                _error = null;
                              });
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                          ),
                        ),

                      // App Logo and Title Section
                      Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 35,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'EcashBook',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSetting
                                ? (_isConfirming
                                    ? 'Confirm your PIN'
                                    : 'Set your PIN')
                                : 'Enter PIN to unlock',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          // Progress indicator for PIN setup
                          if (_isSetting)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isConfirming
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // PIN Input Display
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  return Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
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

                      const SizedBox(height: 16),

                      // Error Message
                      SizedBox(
                        height: 24,
                        child: _error != null
                            ? Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: 24),
                      
                      // Biometric Authentication Button (only when unlocking)
                      if (!_isSetting && _biometricAvailable)
                        Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isAuthenticating ? null : _authenticateWithBiometric,
                              icon: Icon(
                                Icons.fingerprint,
                                color: Colors.white.withOpacity(0.9),
                                size: 24,
                              ),
                              label: Text(
                                _isAuthenticating ? 'Authenticating...' : 'Use Biometric',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'or enter PIN below',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 24),

                      // Keypad
                      Container(
                        constraints: const BoxConstraints(maxWidth: 260),
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
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (var key in row)
                                      key.isEmpty
                                          ? const SizedBox(width: 60)
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

                      const SizedBox(height: 24),
                      
                      // Enable/Disable Biometric (only during setup and if available)
                      if (_isSetting && _isConfirming && _biometricAvailable)
                        Column(
                          children: [
                            CheckboxListTile(
                              value: _biometricEnabled,
                              onChanged: (value) {
                                setState(() => _biometricEnabled = value ?? false);
                              },
                              title: Text(
                                'Enable Biometric Authentication',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Use fingerprint or face unlock',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              activeColor: Colors.white,
                              checkColor: const Color(0xFF422F90),
                              tileColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Exit Button
                      TextButton(
                        onPressed: () => SystemNavigator.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                        ),
                        child: Text(
                          'Exit App',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
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
        width: 60,
        height: 60,
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
                  size: 20,
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

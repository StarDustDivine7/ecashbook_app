import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/biometric_service.dart';

// Biometric Authentication State
class BiometricState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isRequired;
  final String? errorMessage;
  final BiometricErrorCode? errorCode;
  final String? lastAuthMethod;
  final DateTime? lastAuthTime;

  const BiometricState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isRequired = false,
    this.errorMessage,
    this.errorCode,
    this.lastAuthMethod,
    this.lastAuthTime,
  });

  BiometricState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isRequired,
    String? errorMessage,
    BiometricErrorCode? errorCode,
    String? lastAuthMethod,
    DateTime? lastAuthTime,
  }) {
    return BiometricState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isRequired: isRequired ?? this.isRequired,
      errorMessage: errorMessage,
      errorCode: errorCode,
      lastAuthMethod: lastAuthMethod ?? this.lastAuthMethod,
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
    );
  }

  @override
  String toString() {
    return 'BiometricState(authenticated: $isAuthenticated, loading: $isLoading, required: $isRequired)';
  }
}

// Biometric State Notifier
class BiometricNotifier extends StateNotifier<BiometricState> {
  BiometricNotifier() : super(const BiometricState()) {
    _initialize();
  }

  // Cooldown mechanism
  DateTime? _lastAuthRequest;
  static const Duration _cooldownPeriod = Duration(seconds: 3);

  // Flag to ignore screen events during authentication
  bool _isAuthenticating = false;

  // Navigator Key for Android 16 compatibility
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Set navigator key from main.dart
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    debugPrint('🔑 Navigator key set for biometric navigation');
  }

  void setAuthenticating(bool isAuthenticating) {
    _isAuthenticating = isAuthenticating;
    debugPrint('🔐 Authentication state: $_isAuthenticating');
  }

  Future<void> _initialize() async {
    try {
      debugPrint('🔐 Initializing biometric system...');

      // Get last authentication time first
      final DateTime? lastAuth = await BiometricService.getLastAuthenticationTime();

      // Initialize state with last auth time only
      if (mounted) {
        state = state.copyWith(
          lastAuthTime: lastAuth,
          isRequired: false,  // Start fresh, restart detection will set if needed
        );
      }

      // ✅ IMPORTANT: Check restart state AFTER initial state setup
      // This way restart detection can properly override isRequired
      await _checkAppRestartState();

      debugPrint('🔐 Biometric initialization complete - Required: ${state.isRequired}');

      // ✅ DEBUG: Log final state
      debugPrint('🔄 Final biometric state after init: ${state.toString()}');

    } catch (e) {
      debugPrint('❌ Biometric initialization error: $e');
    }
  }

  Future<void> _checkAppRestartState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastAppCloseTime = prefs.getInt('last_app_close_time') ?? 0;
      final lastScreenOffTime = prefs.getInt('screen_off_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      final appTimeDiff = currentTime - lastAppCloseTime;
      final screenTimeDiff = currentTime - lastScreenOffTime;

      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

      debugPrint('🔍 Enhanced restart analysis:');
      debugPrint('   - User logged in: $isUserLoggedIn');
      debugPrint('   - App close time: $lastAppCloseTime (${appTimeDiff}ms ago)');
      debugPrint('   - Screen off time: $lastScreenOffTime (${screenTimeDiff}ms ago)');

      if (isUserLoggedIn) {
        // IMMEDIATE: Any app restart requires biometric
        if (appTimeDiff > 10 * 60 * 1000 && lastAppCloseTime > 0) {
          // 10+ minutes = Phone restart (Scenario 4)
          debugPrint('📱 Phone restart detected - IMMEDIATE biometric required');
          await _saveRestartType('phone_restart');
          _setAuthenticationRequiredInternal();
        } else if (appTimeDiff > 0 && lastAppCloseTime > 0) {
          // ANY time gap = RAM clear/App background - IMMEDIATE biometric
          debugPrint('🧹 App restart detected (${(appTimeDiff/1000).toStringAsFixed(1)}s) - IMMEDIATE biometric required');

          if (appTimeDiff > 5 * 60 * 1000) {
            await _saveRestartType('ram_clear');
          } else {
            await _saveRestartType('app_background');
          }

          _setAuthenticationRequiredInternal();
        } else if (screenTimeDiff > 0 && lastScreenOffTime > 0) {
          // Screen state change (Scenario 1)
          debugPrint('📱 Screen state change detected - IMMEDIATE biometric required');
          await _saveRestartType('screen_state');
          _setAuthenticationRequiredInternal();
        }
      }

      await prefs.setInt('last_app_close_time', currentTime);

    } catch (e) {
      debugPrint('❌ Error in enhanced restart detection: $e');
    }
  }

  Future<void> _saveRestartType(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_restart_type', type);
      debugPrint('📝 Saved restart type: $type');
    } catch (e) {
      debugPrint('❌ Error saving restart type: $e');
    }
  }

  Future<void> _handleScreenStateChange(int timeDifference) async {
    try {
      debugPrint('📱 Handling screen state change - biometric required (Scenario 1)');

      final prefs = await SharedPreferences.getInstance();
      final screenStateCount = prefs.getInt('screen_state_count') ?? 0;
      await prefs.setInt('screen_state_count', screenStateCount + 1);
      await prefs.setString('last_restart_type', 'screen_state');

      debugPrint('📱 Screen was off for ${(timeDifference / 1000).toStringAsFixed(1)} seconds');

      _setAuthenticationRequiredInternal();

    } catch (e) {
      debugPrint('❌ Error handling screen state change: $e');
    }
  }

  void onScreenStateChanged(bool isScreenOn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (!isUserLoggedIn) {
        debugPrint('📱 Screen state change - user not logged in, ignoring');
        return;
      }

      // Ignore screen events during authentication
      if (_isAuthenticating) {
        debugPrint('📱 Screen state change - authentication in progress, ignoring');
        return;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (isScreenOn) {
        debugPrint('📱 Screen turned ON - checking biometric requirement');
        await _handleScreenTurnedOn();
      } else {
        debugPrint('📱 Screen turned OFF - saving timestamp');
        await prefs.setInt('screen_off_time', currentTime);
      }
    } catch (e) {
      debugPrint('❌ Error in screen state change: $e');
    }
  }

  Future<void> _handleScreenTurnedOn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final screenOffTime = prefs.getInt('screen_off_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final offDuration = currentTime - screenOffTime;

      debugPrint('📱 Screen turned on after ${offDuration}ms');

      if (screenOffTime > 0 && offDuration > 0) {
        debugPrint('🔐 Screen was off - biometric required (Scenario 1)');
        await _handleScreenStateChange(offDuration);
      }

      await prefs.remove('screen_off_time');

    } catch (e) {
      debugPrint('❌ Error handling screen turned on: $e');
    }
  }

  void _setAuthenticationRequiredInternal() {
    final now = DateTime.now();

    if (_lastAuthRequest != null && now.difference(_lastAuthRequest!) < _cooldownPeriod) {
      debugPrint('🔐 Cooldown active - skipping auth request');
      return;
    }

    if (mounted && !state.isRequired) {
      state = state.copyWith(isRequired: true);
      _lastAuthRequest = now;
      debugPrint('🔐 Authentication requirement set internally');
      debugPrint('🔄 Current biometric state: ${state.toString()}');
      debugPrint('🔄 Should trigger navigation now!');

      _triggerBiometricNavigation(); // ✅ FIXED: ENABLED AUTOMATIC NAVIGATION
    } else if (state.isRequired) {
      debugPrint('🔐 Authentication already required - skipping');
    }
  }

  void _triggerBiometricNavigation() {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptNavigation();
      });
    } catch (e) {
      debugPrint('❌ Error triggering biometric navigation: $e');
    }
  }

  // ✅ FIXED: Single _attemptNavigation method with enhanced null safety
  void _attemptNavigation({int retryCount = 0}) {
    if (!mounted) {
      debugPrint('❌ Navigation cancelled - widget not mounted');
      return;
    }

    try {
      // ✅ SAFE: Check navigator key with null safety
      if (_navigatorKey?.currentState?.mounted == true) {
        debugPrint('🧭 SUCCESS: Navigating via navigator key (attempt ${retryCount + 1})');
        _navigatorKey!.currentState!.pushNamedAndRemoveUntil(
          '/biometric',
              (route) => false,
        );
        return;
      }

      // ✅ SAFE: Check context with null safety
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context?.mounted == true) {
        debugPrint('🧭 SUCCESS: Navigating via context (attempt ${retryCount + 1})');
        Navigator.of(context!).pushNamedAndRemoveUntil(
          '/biometric',
              (route) => false,
        );
        return;
      }

      // ✅ RETRY: If both methods fail
      if (retryCount < 5) {
        final delay = (retryCount + 1) * 200; // Increased delay
        debugPrint('⏳ Navigation not ready, retrying in ${delay}ms... (attempt ${retryCount + 1}/5)');
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted) {
            _attemptNavigation(retryCount: retryCount + 1);
          }
        });
      } else {
        debugPrint('❌ Navigation failed after 5 attempts - giving up');
      }

    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      if (retryCount < 3) {
        Future.delayed(Duration(milliseconds: (retryCount + 1) * 300), () {
          if (mounted) {
            _attemptNavigation(retryCount: retryCount + 1);
          }
        });
      }
    }
  }

  void onAppLifecycleChanged(AppLifecycleState lifecycleState) async {
    debugPrint('📱 App lifecycle changed to: $lifecycleState');

    final prefs = await SharedPreferences.getInstance();
    final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

    if (!isUserLoggedIn) {
      debugPrint('📱 User not logged in - ignoring lifecycle change');
      return;
    }

    switch (lifecycleState) {
      case AppLifecycleState.paused:
        await _onAppPaused();
        onScreenStateChanged(false);
        break;
      case AppLifecycleState.resumed:
        await _onAppResumed();
        onScreenStateChanged(true);
        break;
      case AppLifecycleState.inactive:
        debugPrint('⏸️ App inactive - potential screen state change');
        onScreenStateChanged(false);
        break;
      case AppLifecycleState.detached:
        debugPrint('🔌 App detached - saving state');
        await _onAppPaused();
        break;
      case AppLifecycleState.hidden:
        debugPrint('👁️ App hidden - screen off state');
        onScreenStateChanged(false);
        break;
    }
  }

  Future<void> _onAppPaused() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (isUserLoggedIn) {
        debugPrint('⏸️ App paused (logged in user) - saving timestamps');
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('app_paused_time', currentTime);
        await prefs.setInt('screen_off_time', currentTime);
      } else {
        debugPrint('⏸️ App paused (not logged in) - no action needed');
      }
    } catch (e) {
      debugPrint('❌ Error handling app paused: $e');
    }
  }

  Future<void> _onAppResumed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (!isUserLoggedIn) {
        debugPrint('▶️ App resumed (not logged in) - no action needed');
        return;
      }

      if (state.isRequired) {
        debugPrint('🔄 Clearing existing biometric requirement for fresh detection');
        state = state.copyWith(isRequired: false);
      }

      final pausedTime = prefs.getInt('app_paused_time') ?? 0;
      final screenOffTime = prefs.getInt('screen_off_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      final pauseDuration = currentTime - pausedTime;
      final screenOffDuration = currentTime - screenOffTime;

      debugPrint('▶️ App resumed (logged in user) - checking biometric need');
      debugPrint('📊 Resume analysis:');
      debugPrint('   - Pause duration: ${pauseDuration}ms');
      debugPrint('   - Screen off duration: ${screenOffDuration}ms');
      debugPrint('   - Was required: ${state.isRequired}');

      final shouldRequireAuth = isUserLoggedIn &&
          ((pauseDuration > 1000 && pausedTime > 0) || (screenOffDuration > 0 && screenOffTime > 0)) &&
          (_lastAuthRequest == null ||
              DateTime.now().difference(_lastAuthRequest!) > _cooldownPeriod);

      if (shouldRequireAuth) {
        if (pauseDuration > 1000 && pausedTime > 0) {
          debugPrint('🔐 App was backgrounded - setting biometric requirement (Scenario 2)');
        }
        if (screenOffDuration > 0 && screenOffTime > 0) {
          debugPrint('🔐 Screen was off - setting biometric requirement (Scenario 1)');
        }
        _setAuthenticationRequiredInternal();
      } else {
        debugPrint('⚡ Quick resume - no biometric needed');
      }

    } catch (e) {
      debugPrint('❌ Error handling app resumed: $e');
    }
  }

  void clearAuthenticationRequired() {
    if (mounted) {
      state = state.copyWith(
        isRequired: false,
        isAuthenticated: true,
        errorMessage: null,
        errorCode: null,
      );

      _lastAuthRequest = DateTime.now();
      setAuthenticating(false);
      debugPrint('✅ Authentication requirement cleared with cooldown reset');
    }
  }

  Future<bool> checkDeviceSecurity() async {
    try {
      debugPrint('🔍 Checking device security capabilities...');

      final bool isSecure = await BiometricService.isDeviceSecure();
      final List<BiometricType> available = await BiometricService.getAvailableBiometrics();

      debugPrint('📱 Device secure: $isSecure');
      debugPrint('📋 Available biometrics: $available');

      return isSecure;
    } catch (e) {
      debugPrint('❌ Error checking device security: $e');
      return false;
    }
  }

  Future<bool> authenticateUser({String? reason}) async {
    if (mounted) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        errorCode: null,
      );
    }

    setAuthenticating(true);

    try {
      debugPrint('🔐 Starting user authentication...');

      final bool isSecure = await checkDeviceSecurity();
      if (!isSecure) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'No screen lock set up on device',
            errorCode: BiometricErrorCode.noAuthenticationSet,
          );
        }
        setAuthenticating(false);
        return false;
      }

      final BiometricResult result = await BiometricService.authenticateWithSystem(
        reason: reason ?? 'Please authenticate to access EcashBook',
      );

      if (mounted) {
        if (result.success) {
          state = state.copyWith(
            isAuthenticated: true,
            isRequired: false,
            isLoading: false,
            lastAuthMethod: result.authMethod,
            lastAuthTime: DateTime.now(),
            errorMessage: null,
            errorCode: null,
          );

          final prefs = await SharedPreferences.getInstance();
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          await prefs.setInt('app_paused_time', currentTime);
          await prefs.setInt('last_app_close_time', currentTime);
          await prefs.setInt('screen_off_time', currentTime);

          _lastAuthRequest = null;

          debugPrint('✅ User authentication successful');
          setAuthenticating(false);
          return true;
        } else {
          state = state.copyWith(
            isAuthenticated: false,
            isLoading: false,
            errorMessage: result.errorMessage,
            errorCode: result.errorCode,
          );

          debugPrint('❌ User authentication failed: ${result.errorMessage}');
          setAuthenticating(false);
          return false;
        }
      }

      setAuthenticating(false);
      return result.success;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication error: $e',
          errorCode: BiometricErrorCode.unknown,
        );
      }

      debugPrint('❌ Authentication exception: $e');
      setAuthenticating(false);
      return false;
    }
  }

  Future<bool> quickAuthenticate() async {
    debugPrint('⚡ Quick authentication check...');

    final bool timeoutRequired = await BiometricService.isAuthenticationRequired(
      timeout: const Duration(minutes: 2),
    );

    if (!timeoutRequired) {
      debugPrint('✅ Authentication not required (within 2-minute window)');
      clearAuthenticationRequired();
      return true;
    }

    return await authenticateUser();
  }

  Future<void> resetAuthenticationState() async {
    await BiometricService.clearAuthenticationData();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('phone_restart_count');
      await prefs.remove('ram_clear_count');
      await prefs.remove('screen_state_count');
      await prefs.remove('last_restart_type');
      await prefs.remove('app_paused_time');
      await prefs.remove('screen_off_time');
      await prefs.remove('last_app_close_time');
    } catch (e) {
      debugPrint('❌ Error clearing restart data: $e');
    }

    _lastAuthRequest = null;
    setAuthenticating(false);

    if (mounted) {
      state = const BiometricState();
      debugPrint('🧹 Biometric authentication state reset');
    }
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(
        errorMessage: null,
        errorCode: null,
      );
    }
  }

  Future<Map<String, dynamic>> getAuthenticationSummary() async {
    try {
      final Map<String, dynamic> info = await BiometricService.getAuthenticationInfo();
      final prefs = await SharedPreferences.getInstance();

      return {
        'current_state': state.toString(),
        'device_info': info,
        'cooldown_active': _lastAuthRequest != null ? DateTime.now().difference(_lastAuthRequest!).inSeconds : null,
        'authentication_in_progress': _isAuthenticating,
        'navigator_key_available': _navigatorKey != null,
        'scenarios': {
          'phone_restart_count': prefs.getInt('phone_restart_count') ?? 0,
          'ram_clear_count': prefs.getInt('ram_clear_count') ?? 0,
          'screen_state_count': prefs.getInt('screen_state_count') ?? 0,
          'last_restart_type': prefs.getString('last_restart_type') ?? 'none',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  String getErrorDisplayMessage() {
    if (state.errorMessage == null) return '';

    switch (state.errorCode) {
      case BiometricErrorCode.noAuthenticationSet:
        return 'Please set up screen lock (PIN, Pattern, Password, or Biometric) in device settings to secure the app.';
      case BiometricErrorCode.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case BiometricErrorCode.notEnrolled:
        return 'No biometric credentials are enrolled. Please set up fingerprint or face authentication in device settings.';
      case BiometricErrorCode.deviceNotSecure:
        return 'Device is not secure. Please enable screen lock in device settings.';
      case BiometricErrorCode.lockedOut:
        return 'Too many failed attempts. Please try again later or use your device PIN/Pattern.';
      case BiometricErrorCode.cancelled:
        return 'Authentication was cancelled. Please try again to continue.';
      case BiometricErrorCode.timeout:
        return 'Authentication timeout. Please try again.';
      case BiometricErrorCode.unknown:
      default:
        return state.errorMessage ?? 'Authentication failed. Please try again.';
    }
  }

  bool canRetryAuthentication() {
    switch (state.errorCode) {
      case BiometricErrorCode.cancelled:
      case BiometricErrorCode.timeout:
      case BiometricErrorCode.unknown:
        return true;
      case BiometricErrorCode.lockedOut:
        return false;
      case BiometricErrorCode.noAuthenticationSet:
      case BiometricErrorCode.notAvailable:
      case BiometricErrorCode.notEnrolled:
      case BiometricErrorCode.deviceNotSecure:
        return false;
      default:
        return true;
    }
  }

  void openDeviceSettings() {
    clearError();
    debugPrint('🔧 User should open device settings to set up authentication');
  }
}

final biometricProvider = StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
  return BiometricNotifier();
});

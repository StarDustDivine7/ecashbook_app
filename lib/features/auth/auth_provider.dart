import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final String? rememberedEmail;
  final String? rememberedPassword;
  final String? currentLocation;
  final bool isLocationLoading;
  final bool isInitializing;
  final bool isFirstTime;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.rememberedEmail,
    this.rememberedPassword,
    this.currentLocation,
    this.isLocationLoading = false,
    this.isInitializing = true,
    this.isFirstTime = true,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    String? rememberedEmail,
    String? rememberedPassword,
    String? currentLocation,
    bool? isLocationLoading,
    bool? isInitializing,
    bool? isFirstTime,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      rememberedEmail: rememberedEmail ?? this.rememberedEmail,
      rememberedPassword: rememberedPassword ?? this.rememberedPassword,
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('🚀 Initializing auth system...');
      final isFirstTime = await _checkFirstTimeUser();
      await loadRememberedCredentials();
      await _checkLoginState();
      if (mounted) {
        state = state.copyWith(isInitializing: false, isFirstTime: isFirstTime);
        debugPrint(
            '✅ Auth initialization complete - Logged in: ${state.isLoggedIn}');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isInitializing: false);
      }
      debugPrint('❌ Auth initialization error: $e');
    }
  }

  Future<bool> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_first_time') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setNotFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time', false);
      if (mounted) state = state.copyWith(isFirstTime: false);
    } catch (e) {
      debugPrint('❌ Error setting first time: $e');
    }
  }

  Future<void> _checkLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('user_logged_in') ?? false;
      // Also verify token exists — prevents stale isLoggedIn=true after force-logout
      final token = prefs.getString('auth_token');
      final isActuallyLoggedIn =
          wasLoggedIn && token != null && token.isNotEmpty;
      if (mounted) {
        state = state.copyWith(isLoggedIn: isActuallyLoggedIn);
        debugPrint(
            '✅ Login state: wasLoggedIn=$wasLoggedIn, hasToken=${token != null}, effective=$isActuallyLoggedIn');
      }
    } catch (e) {
      debugPrint('❌ Error checking login state: $e');
    }
  }

  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', true);
      debugPrint('✅ Login state saved');
    } catch (e) {
      debugPrint('❌ Error saving login state: $e');
    }
  }

  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_logged_in');
      debugPrint('✅ Login state cleared');
    } catch (e) {
      debugPrint('❌ Error clearing login state: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    if (mounted) state = state.copyWith(isLocationLoading: true);
    try {
      final position = await AuthService.getCurrentLocation();
      if (mounted) {
        if (position != null) {
          final locationString = AuthService.formatLocation(position);
          state = state.copyWith(
              currentLocation: locationString, isLocationLoading: false);
          debugPrint('✅ Location: $locationString');
        } else {
          state = state.copyWith(
              currentLocation: 'Location access denied',
              isLocationLoading: false);
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            currentLocation: 'Unable to get location',
            isLocationLoading: false);
      }
      debugPrint('❌ Location error: $e');
    }
  }

  Future<void> loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');
      if (rememberedEmail != null && rememberedPassword != null && mounted) {
        state = state.copyWith(
            rememberedEmail: rememberedEmail,
            rememberedPassword: rememberedPassword);
        debugPrint('📝 Remembered credentials loaded');
      }
    } catch (e) {
      debugPrint('❌ Error loading credentials: $e');
    }
  }

  Future<bool> login(String email, String password, bool rememberMe) async {
    if (mounted) state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await AuthService.loginWithAPI(email.trim(), password);
      if (!result.success) {
        if (mounted) {
          state = state.copyWith(
            isLoggedIn: false,
            isLoading: false,
            errorMessage: result.message ??
                'Invalid username or password. Please try again.',
          );
        }
        debugPrint('❌ Login failed - ${result.message}');
        return false;
      }

      if (rememberMe) {
        await _saveCredentials(email, password);
      } else {
        await _clearSavedCredentials();
      }

      await _saveLoginState();
      await AuthService.saveAuthSession();
      if (mounted) {
        state = state.copyWith(
            isLoggedIn: true, isLoading: false, errorMessage: null);
      }
      getCurrentLocation();
      debugPrint('✅ API Login successful');
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Login error. Please try again.');
      }
      debugPrint('❌ Login exception: $e');
      return false;
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('remembered_email', email);
      await prefs.setString('remembered_password', password);
      if (mounted) {
        state = state.copyWith(
            rememberedEmail: email, rememberedPassword: password);
      }
      debugPrint('💾 Credentials saved');
    } catch (e) {
      debugPrint('❌ Error saving credentials: $e');
    }
  }

  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      if (mounted) {
        state = state.copyWith(rememberedEmail: null, rememberedPassword: null);
      }
      debugPrint('🧹 Saved credentials cleared');
    } catch (e) {
      debugPrint('❌ Error clearing credentials: $e');
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🚪 Starting logout process with API call...');

      // Call logout API
      final logoutResult = await AuthService.logoutWithAPI();

      if (logoutResult.isUnauthorized) {
        debugPrint('🔒 Unauthorized token - data already cleared');
      } else if (logoutResult.success) {
        debugPrint('✅ Logout API successful');
      } else {
        debugPrint(
            '⚠️ Logout API failed but data cleared: ${logoutResult.message}');
      }

      // Always clear local session and login flag regardless of API outcome
      try {
        await AuthService.clearAllAppData();
      } catch (e) {
        debugPrint('❌ Error clearing app data on logout: $e');
      }
      await _clearLoginState();

      // Update state
      if (mounted) {
        state = state.copyWith(
          isLoggedIn: false,
          isFirstTime: false,
          currentLocation: null,
          errorMessage: null,
          rememberedEmail: state.rememberedEmail,
          rememberedPassword: state.rememberedPassword,
        );
      }

      debugPrint('✅ Logout process completed - will redirect to login page');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      // Even if there's an error, ensure user is logged out locally
      try {
        await AuthService.clearAllAppData();
      } catch (_) {}
      await _clearLoginState();

      if (mounted) {
        state = state.copyWith(
            isLoggedIn: false,
            isFirstTime: false,
            currentLocation: null,
            errorMessage: null);
      }
    }
  }

  bool shouldNavigateToLogin() {
    return !state.isLoggedIn && !state.isFirstTime;
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Called when a force-logout happens (e.g. token invalidated by another device login)
  /// Immediately updates in-memory state so no widget re-triggers the unauthorized flow
  void forceLoggedOut() {
    if (mounted) {
      state = state.copyWith(
        isLoggedIn: false,
        isFirstTime: false,
        currentLocation: null,
        errorMessage: null,
      );
      debugPrint('🔒 AuthNotifier: forceLoggedOut called - state updated');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

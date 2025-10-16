import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinState {
  final bool isRequired;
  final bool isLoading;
  final String? errorMessage;

  const PinState({
    this.isRequired = false,
    this.isLoading = false,
    this.errorMessage,
  });

  PinState copyWith({
    bool? isRequired,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PinState(
      isRequired: isRequired ?? this.isRequired,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'PinState(required: $isRequired, loading: $isLoading)';
  }
}

class PinNotifier extends StateNotifier<PinState> {
  PinNotifier() : super(const PinState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Add a small delay to ensure SharedPreferences are ready
      await Future.delayed(const Duration(milliseconds: 100));
      await _checkAppRestartState();
    } catch (e) {
      debugPrint('❌ PIN initialization error: $e');
    }
  }

  Future<void> _checkAppRestartState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPin = (prefs.getString('app_passcode_hash') ?? '').isNotEmpty;
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;
      final lastAppCloseTime = prefs.getInt('last_app_close_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceClose = currentTime - lastAppCloseTime;

      // Always require PIN if user is logged in and has PIN set
      // This covers app restart, minimize/restore, and screen off/on scenarios
      if (isUserLoggedIn && hasPin) {
        _setPinRequired();
      }

      // Update the close time for next check
      await prefs.setInt('last_app_close_time', currentTime);
    } catch (e) {
      debugPrint('❌ Error in PIN restart detection: $e');
    }
  }

  void onAppLifecycleChanged(AppLifecycleState lifecycleState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;
      final hasPin = (prefs.getString('app_passcode_hash') ?? '').isNotEmpty;

      if (!isUserLoggedIn || !hasPin) {
        return;
      }

      switch (lifecycleState) {
        case AppLifecycleState.paused:
          await _onAppPaused();
          break;
        case AppLifecycleState.resumed:
          await _onAppResumed();
          break;
        case AppLifecycleState.inactive:
          // Also handle inactive state for screen off/on scenarios
          await _onAppPaused();
          break;
        case AppLifecycleState.detached:
          await _onAppPaused();
          break;
        case AppLifecycleState.hidden:
          await _onAppPaused();
          break;
      }
    } catch (e) {
      debugPrint('❌ Error in lifecycle change: $e');
    }
  }

  Future<void> _onAppPaused() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (isUserLoggedIn) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('app_paused_time', currentTime);
        await prefs.setBool('app_was_backgrounded', true);
      }
    } catch (e) {
      debugPrint('❌ Error handling app paused: $e');
    }
  }

  Future<void> _onAppResumed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasBackgrounded = prefs.getBool('app_was_backgrounded') ?? false;
      final pausedTime = prefs.getInt('app_paused_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final pauseDuration = currentTime - pausedTime;

      // Always require PIN if app was backgrounded (even for short durations)
      // This ensures PIN is required for minimize/restore and screen off/on
      if (wasBackgrounded) {
        _setPinRequired();
      }

      // Clear the backgrounded flag after checking
      await prefs.remove('app_was_backgrounded');
    } catch (e) {
      debugPrint('❌ Error handling app resumed: $e');
    }
  }

  void _setPinRequired() {
    if (mounted && !state.isRequired) {
      state = state.copyWith(isRequired: true);
    }
  }

  void clearPinRequired() {
    if (mounted) {
      state = state.copyWith(isRequired: false, errorMessage: null);
    }
  }

  void setError(String error) {
    if (mounted) {
      state = state.copyWith(errorMessage: error);
    }
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(errorMessage: null);
    }
  }

  // Public method to force PIN requirement (can be called from outside)
  void requirePin() {
    _setPinRequired();
  }


}

final pinProvider = StateNotifierProvider<PinNotifier, PinState>((ref) {
  return PinNotifier();
});

// Helper method to check if PIN should be required
Future<bool> shouldRequirePin() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;
    final hasPin = (prefs.getString('app_passcode_hash') ?? '').isNotEmpty;
    final wasBackgrounded = prefs.getBool('app_was_backgrounded') ?? false;
    
    return isUserLoggedIn && hasPin && wasBackgrounded;
  } catch (e) {
    debugPrint('❌ Error checking PIN requirement: $e');
    return false;
  }
}
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
      debugPrint('🔐 PIN Provider: Starting initialization...');
      // Immediately check app restart state without delay
      await _checkAppRestartState();
      debugPrint('🔐 PIN Provider: Initialization complete');
    } catch (e) {
      debugPrint('❌ PIN initialization error: $e');
    }
  }

  Future<void> _checkAppRestartState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPin = (prefs.getString('app_passcode_hash') ?? '').isNotEmpty;
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;
      final wasKilled = prefs.getBool('app_was_killed') ?? false;
      final lastAppCloseTime = prefs.getInt('last_app_close_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceClose = currentTime - lastAppCloseTime;

      debugPrint('🔄 Checking app restart state...');
      debugPrint('🔄 isUserLoggedIn: $isUserLoggedIn, hasPin: $hasPin');
      debugPrint('🔄 wasKilled: $wasKilled, timeSinceClose: ${timeSinceClose}ms');

      // Always require PIN on app restart if user is logged in and has PIN set
      // This ensures security without complex lifecycle detection
      if (isUserLoggedIn && hasPin) {
        debugPrint('🔒 Requiring PIN on app restart (always for security)');
        _setPinRequired();
      } else {
        debugPrint('✅ No PIN required - user not logged in or no PIN set');
      }

      // Update the close time for next check
      await prefs.setInt('last_app_close_time', currentTime);
      // Clear the killed flag
      await prefs.remove('app_was_killed');
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

      debugPrint('🔄 App lifecycle changed: $lifecycleState');

      switch (lifecycleState) {
        case AppLifecycleState.paused:
          // App is going to background (home button, app switcher, etc.)
          await _onAppPaused();
          break;
        case AppLifecycleState.resumed:
          // App is coming back to foreground
          await _onAppResumed();
          break;
        case AppLifecycleState.inactive:
          // App is inactive (notification shade, system dialog, etc.)
          // DO NOT trigger lock screen for inactive state
          // This is just a temporary interruption
          debugPrint('🔄 App inactive - ignoring (notification shade or system dialog)');
          break;
        case AppLifecycleState.detached:
          // App is detached (about to be killed)
          await _onAppDetached();
          break;
        case AppLifecycleState.hidden:
          // App is hidden but still in memory
          debugPrint('🔄 App hidden - ignoring');
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
        debugPrint('🔄 App paused - background flag set');
      }
    } catch (e) {
      debugPrint('❌ Error handling app paused: $e');
    }
  }

  Future<void> _onAppDetached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUserLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (isUserLoggedIn) {
        // Mark that app was completely closed
        await prefs.setBool('app_was_killed', true);
        debugPrint('🔄 App detached - app will require lock on restart');
      }
    } catch (e) {
      debugPrint('❌ Error handling app detached: $e');
    }
  }

  Future<void> _onAppResumed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // If a trusted picker (like FilePicker) was launched, suppress next lock
      final suppressNextLock = prefs.getBool('suppress_next_lock') ?? false;
      final wasBackgrounded = prefs.getBool('app_was_backgrounded') ?? false;
      final wasKilled = prefs.getBool('app_was_killed') ?? false;
      final pausedTime = prefs.getInt('app_paused_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final pauseDuration = currentTime - pausedTime;

      debugPrint('🔄 App resumed - wasBackgrounded: $wasBackgrounded, pauseDuration: ${pauseDuration}ms');
      if (suppressNextLock) {
        debugPrint('✅ Suppressing lock due to trusted picker flow');
        // Clear flags to avoid unintended locks
        await prefs.remove('app_was_backgrounded');
        await prefs.remove('app_paused_time');
        await prefs.remove('app_was_killed');
        await prefs.remove('suppress_next_lock');
        return;
      }

      // Only require PIN if app was truly backgrounded for a significant time
      // or if app was killed and restarted
      if (wasBackgrounded && pauseDuration > 30000) { // More than 30 seconds
        debugPrint('🔒 Requiring PIN - app was backgrounded for ${pauseDuration}ms (>30s threshold)');
        _setPinRequired();
      } else if (wasKilled) {
        debugPrint('🔒 Requiring PIN - app was killed and restarted');
        _setPinRequired();
      } else {
        debugPrint('✅ No PIN required - brief interruption (<30s)');
      }

      // Clear the flags after checking
      await prefs.remove('app_was_backgrounded');
      await prefs.remove('app_was_killed');
    } catch (e) {
      debugPrint('❌ Error handling app resumed: $e');
    }
  }

  void _setPinRequired() {
    if (mounted && !state.isRequired) {
      debugPrint('🔐 PIN Provider: Setting PIN as required');
      state = state.copyWith(isRequired: true);
    } else {
      debugPrint('🔐 PIN Provider: PIN already required or not mounted');
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
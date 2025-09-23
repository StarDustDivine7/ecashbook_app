import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/biometric_provider.dart';
import '../../core/constants.dart';
import '../../core/services/biometric_service.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => BiometricScreenState();
}

class BiometricScreenState extends ConsumerState<BiometricScreen>
    with TickerProviderStateMixin {
  late AnimationController pulseController;
  late AnimationController fadeController;
  late Animation<double> pulseAnimation;
  late Animation<double> fadeAnimation;

  bool hasStartedAuth = false;
  bool isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    initAnimations();
    startAuthenticationFlow();
  }

  void initAnimations() {
    pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
    pulseController.repeat(reverse: true);

    fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeOut),
    );
    fadeController.forward();
  }

  void startAuthenticationFlow() {
    if (!hasStartedAuth) {
      hasStartedAuth = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !isAuthenticating) {
          performAuthentication();
        }
      });
    }
  }

  Future<void> performAuthentication() async {
    if (isAuthenticating) return;
    setState(() => isAuthenticating = true);
    try {
      final notifier = ref.read(biometricProvider.notifier);
      final success = await notifier.authenticateUser(
        reason: 'Please authenticate to access EcashBook',
      );
      if (!mounted) return;
      if (success) {
        await navigateToSmartDestination();
      }
    } finally {
      if (mounted) setState(() => isAuthenticating = false);
    }
  }

  Future<void> navigateToSmartDestination() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final restartType = prefs.getString('last_restart_type') ?? 'unknown';
      final lastActivePage = prefs.getString('last_active_page') ?? '/dashboard';
      String destination;
      switch (restartType) {
        case 'screen_state':
        case 'app_background':
          destination = lastActivePage;
          break;
        case 'ram_clear':
        case 'phone_restart':
          destination = '/dashboard';
          break;
        default:
          destination = await BiometricService.getSmartNavigationDestination();
          break;
      }
      if (!mounted) return;
      ref.read(biometricProvider.notifier).clearAuthenticationRequired();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
    } catch (_) {
      if (!mounted) return;
      ref.read(biometricProvider.notifier).clearAuthenticationRequired();
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }
  }

  void retryAuthentication() {
    if (isAuthenticating) return;
    ref.read(biometricProvider.notifier).clearError();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !isAuthenticating) performAuthentication();
    });
  }

  void exitApp() => SystemNavigator.pop();

  @override
  void dispose() {
    pulseController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biometricProvider);
    final notifier = ref.read(biometricProvider.notifier);
    final bool canRetry = notifier.canRetryAuthentication(); // FIX: call method

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          exitApp();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding / 2),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    64,
              ),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildAppLogo(),
                    const SizedBox(height: 32),
                    buildAuthenticationStatus(state),
                    const SizedBox(height: 24),
                    buildBiometricIcon(state),
                    const SizedBox(height: 24),
                    buildStatusMessage(state),
                    const SizedBox(height: 32),
                    buildActionButtons(state, canRetry),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAppLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          Assets.appIcon,
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.business, size: 40, color: Colors.white);
          },
        ),
      ),
    );
  }

  Widget buildAuthenticationStatus(BiometricState state) {
    return Column(
      children: [
        const Text(
          'EcashBook',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          isAuthenticating || state.isLoading
              ? 'Authenticating...'
              : (state.errorMessage != null ? 'Authentication Required' : 'Unlock Required'),
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget buildBiometricIcon(BiometricState state) {
    IconData iconData;
    Color iconColor;
    if (isAuthenticating || state.isLoading) {
      iconData = Icons.fingerprint;
      iconColor = Colors.white;
    } else if (state.errorMessage != null) {
      iconData = getErrorIcon(state.errorCode);
      iconColor = Colors.white70;
    } else {
      iconData = Icons.fingerprint;
      iconColor = Colors.white;
    }
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (isAuthenticating || state.isLoading) ? pulseAnimation.value : 1.0,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(iconData, size: 48, color: iconColor),
          ),
        );
      },
    );
  }

  IconData getErrorIcon(BiometricErrorCode? errorCode) {
    switch (errorCode) {
      case BiometricErrorCode.noAuthenticationSet:
      case BiometricErrorCode.deviceNotSecure:
        return Icons.security;
      case BiometricErrorCode.notAvailable:
      case BiometricErrorCode.notEnrolled:
        return Icons.fingerprint_outlined;
      case BiometricErrorCode.lockedOut:
        return Icons.lock_clock;
      case BiometricErrorCode.cancelled:
        return Icons.cancel_outlined;
      case BiometricErrorCode.timeout:
        return Icons.timer_off;
      case BiometricErrorCode.unknown:
      default:
        return Icons.error_outline;
    }
  }

  Widget buildStatusMessage(BiometricState state) {
    String message;
    if (isAuthenticating || state.isLoading) {
      message = 'Please authenticate using your fingerprint, face, PIN, pattern, or password';
    } else if (state.errorMessage != null) {
      message = ref.read(biometricProvider.notifier).getErrorDisplayMessage();
    } else {
      message = 'Touch the fingerprint sensor or use your device authentication method';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
      ),
    );
  }

  Widget buildActionButtons(BiometricState state, bool canRetry) {
    if (isAuthenticating || state.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (state.errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canRetry)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAuthenticating ? null : retryAuthentication,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (isSetupError(state.errorCode))
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: showSettingsDialog,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: exitApp,
            child: const Text(
              'Exit App',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  bool isSetupError(BiometricErrorCode? errorCode) {
    return errorCode == BiometricErrorCode.noAuthenticationSet ||
        errorCode == BiometricErrorCode.deviceNotSecure ||
        errorCode == BiometricErrorCode.notEnrolled;
  }

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Required'),
        content: const Text(
          'Please set up screen lock PIN, Pattern, Password, or Biometric in your device settings, then return to EcashBook.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              retryAuthentication();
            },
            child: const Text("I've Set It Up"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

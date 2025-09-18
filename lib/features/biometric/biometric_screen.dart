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
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  bool _hasStartedAuth = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAuthenticationFlow();
  }

  // ✅ REUSED: Existing animation initialization
  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    _fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  // ✅ REUSED: Existing authentication flow start
  void _startAuthenticationFlow() {
    if (!_hasStartedAuth) {
      _hasStartedAuth = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isAuthenticating) {
          _performAuthentication();
        }
      });
    }
  }

  // ✅ REUSED: Existing authentication logic
  Future<void> _performAuthentication() async {
    if (_isAuthenticating) {
      debugPrint('🔐 BiometricScreen: Authentication already in progress - skipping');
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final biometricNotifier = ref.read(biometricProvider.notifier);
      debugPrint('🔐 BiometricScreen: Starting authentication');

      final bool success = await biometricNotifier.authenticateUser(
        reason: 'Please authenticate to access EcashBook',
      );

      if (mounted) {
        if (success) {
          debugPrint('✅ BiometricScreen: Authentication successful');
          await _navigateToSmartDestination();
        } else {
          debugPrint('❌ BiometricScreen: Authentication failed - showing error UI');
        }
      }
    } catch (e) {
      debugPrint('❌ BiometricScreen: Authentication exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  // ✅ ENHANCED: Smart navigation with restart type detection
  Future<void> _navigateToSmartDestination() async {
    try {
      debugPrint('🧭 Getting smart navigation destination...');

      final prefs = await SharedPreferences.getInstance();
      final restartType = prefs.getString('last_restart_type') ?? 'unknown';
      final lastActivePage = prefs.getString('last_active_page') ?? '/dashboard';

      String destination;

      debugPrint('🔍 Navigation analysis:');
      debugPrint('   - Restart type: $restartType');
      debugPrint('   - Last active page: $lastActivePage');

      switch (restartType) {
        case 'screen_state':
          destination = lastActivePage;
          debugPrint('📱 Screen state change - returning to: $destination');
          break;
        case 'app_background':
          destination = lastActivePage;
          debugPrint('📱 App background - returning to: $destination');
          break;
        case 'ram_clear':
          destination = '/dashboard';
          debugPrint('🧹 RAM clear - going to dashboard');
          break;
        case 'phone_restart':
          destination = '/dashboard';
          debugPrint('📱 Phone restart - going to dashboard');
          break;
        default:
          destination = await BiometricService.getSmartNavigationDestination();
          debugPrint('🎯 Using service logic - going to: $destination');
          break;
      }

      debugPrint('🎯 Final navigation to: $destination');

      // ✅ CLEAR biometric requirement BEFORE navigation
      if (mounted) {
        ref.read(biometricProvider.notifier).clearAuthenticationRequired();
        debugPrint('🧹 Biometric requirement cleared before navigation');
      }

      // ✅ Add delay to prevent immediate re-trigger
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          destination,
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Smart navigation error: $e');
      if (mounted) {
        ref.read(biometricProvider.notifier).clearAuthenticationRequired();
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
              (route) => false,
        );
      }
    }
  }

  // ✅ REUSED: Existing retry logic
  void _retryAuthentication() {
    if (_isAuthenticating) {
      debugPrint('🔐 Authentication in progress - ignoring retry request');
      return;
    }

    debugPrint('🔄 User requested retry - clearing error and restarting auth');
    ref.read(biometricProvider.notifier).clearError();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isAuthenticating) {
        _performAuthentication();
      }
    });
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ✅ REUSED: Existing build method - no changes needed
  @override
  Widget build(BuildContext context) {
    final biometricState = ref.watch(biometricProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _exitApp();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom - 64,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppLogo(),
                    const SizedBox(height: 32),
                    _buildAuthenticationStatus(biometricState),
                    const SizedBox(height: 24),
                    _buildBiometricIcon(biometricState),
                    const SizedBox(height: 24),
                    _buildStatusMessage(biometricState),
                    const SizedBox(height: 32),
                    _buildActionButtons(biometricState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ REUSED: All existing UI builder methods - no changes needed
  Widget _buildAppLogo() {
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
            return const Icon(
              Icons.business,
              size: 40,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticationStatus(BiometricState state) {
    return Column(
      children: [
        Text(
          'EcashBook',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isAuthenticating || state.isLoading
              ? 'Authenticating...'
              : state.errorMessage != null
              ? 'Authentication Required'
              : 'Unlock Required',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricIcon(BiometricState state) {
    IconData iconData;
    Color iconColor;

    if (_isAuthenticating || state.isLoading) {
      iconData = Icons.fingerprint;
      iconColor = Colors.white;
    } else if (state.errorMessage != null) {
      iconData = _getErrorIcon(state.errorCode);
      iconColor = Colors.white70;
    } else {
      iconData = Icons.fingerprint;
      iconColor = Colors.white;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (_isAuthenticating || state.isLoading) ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              iconData,
              size: 48,
              color: iconColor,
            ),
          ),
        );
      },
    );
  }

  IconData _getErrorIcon(BiometricErrorCode? errorCode) {
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
      default:
        return Icons.error_outline;
    }
  }

  Widget _buildStatusMessage(BiometricState state) {
    String message;

    if (_isAuthenticating || state.isLoading) {
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
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BiometricState state) {
    if (_isAuthenticating || state.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (state.errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ref.read(biometricProvider.notifier).canRetryAuthentication()) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _retryAuthentication,
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
          ],

          if (_isSetupError(state.errorCode))
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(biometricProvider.notifier).openDeviceSettings();
                  _showSettingsDialog();
                },
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
            onPressed: _exitApp,
            child: const Text(
              'Exit App',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  bool _isSetupError(BiometricErrorCode? errorCode) {
    return errorCode == BiometricErrorCode.noAuthenticationSet ||
        errorCode == BiometricErrorCode.deviceNotSecure ||
        errorCode == BiometricErrorCode.notEnrolled;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Required'),
        content: const Text(
          'Please set up screen lock (PIN, Pattern, Password, or Biometric) in your device settings, then return to EcashBook.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _retryAuthentication();
            },
            child: const Text('I\'ve Set It Up'),
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

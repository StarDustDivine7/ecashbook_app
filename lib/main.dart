import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/security/pin_provider.dart';
import 'features/auth/login_page.dart';
import 'features/onboarding/introduction_screen.dart';
import 'features/permissions/permission_screen.dart';
import 'features/permissions/location_accuracy_screen.dart';
import 'features/security/app_passcode_screen.dart';
import 'features/security/pin_unlock_screen.dart';
import 'shared/main_layout.dart';

void main() => runApp(const ProviderScope(child: EcashbookApp()));

class EcashbookApp extends ConsumerStatefulWidget {
  const EcashbookApp({super.key});

  @override
  ConsumerState<EcashbookApp> createState() => _EcashbookAppState();
}

class _EcashbookAppState extends ConsumerState<EcashbookApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // —— Splash/Error scaffolds ——
  Widget _buildErrorApp() => MaterialApp(
    title: 'EcashBook',
    debugShowCheckedModeBanner: false,
    theme: ecTheme,
    home: Scaffold(
      backgroundColor: const Color(0xFF422F90),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 24),
            const Text('App Loading Error', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Something went wrong during startup', style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF422F90)),
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildSplashScreen(String message, {String? subtitle}) => MaterialApp(
    title: 'EcashBook',
    debugShowCheckedModeBanner: false,
    theme: ecTheme,
    home: _buildSplashScreenWidget(message, subtitle: subtitle),
  );

  Widget _buildSplashScreenWidget(String message, {String? subtitle}) => Scaffold(
    backgroundColor: const Color(0xFF422F90),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.1)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/icon/icon.png', width: 80, height: 80, errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 64, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('EcashBook', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ],
      ),
    ),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final pinNotifier = ref.read(pinProvider.notifier);
      pinNotifier.onAppLifecycleChanged(state);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      try {
        final authState = ref.watch(authProvider);
        final pinState = ref.watch(pinProvider);
        final isPinRequired = pinState.isRequired;

        // Auth initializing splash
        if (authState.isInitializing) {
          return _buildSplashScreen('Initializing...', subtitle: 'Setting up your secure workspace');
        }

        // PIN requirement is handled automatically by the PIN provider

        // When logged-in and PIN is required, show PIN unlock screen
        if (authState.isLoggedIn && isPinRequired) {
          return MaterialApp(
            title: 'EcashBook',
            debugShowCheckedModeBanner: false,
            theme: ecTheme,
            home: const PinUnlockScreen(),
          );
        }

        // Main router
        return MaterialApp(
          title: 'EcashBook',
          debugShowCheckedModeBanner: false,
          theme: ecTheme,
          navigatorKey: navigatorKey,
          initialRoute: _getInitialRoute(authState),
          onGenerateRoute: (settings) => _generateRoute(settings, authState),
        );
      } catch (e) {

        return _buildErrorApp();
      }
    });
  }

  String _getInitialRoute(AuthState authState) {
    return '/resolver';
  }

  Route _generateRoute(RouteSettings settings, AuthState authState) {
    switch (settings.name) {
      case '/resolver':
        return MaterialPageRoute(builder: (_) => _StartupResolver(authState: authState));
      case '/introduction':
        return MaterialPageRoute(builder: (_) => const IntroductionScreen(), settings: settings);
      case '/permissions':
        return MaterialPageRoute(builder: (_) => const PermissionScreen(), settings: settings);
      case '/location-accuracy':
        return MaterialPageRoute(builder: (_) => const LocationAccuracyScreen(), settings: settings);
      case '/app-passcode':
        return MaterialPageRoute(builder: (_) => const AppPasscodeScreen(), settings: settings);
      case '/pin-unlock':
        return MaterialPageRoute(builder: (_) => const PinUnlockScreen(), settings: settings);
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage(), settings: settings);
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) SystemNavigator.pop();
            },
            child: const MainLayout(initialIndex: 2),
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage(), settings: const RouteSettings(name: '/login'));
    }
  }
}

// —— Startup Resolver ——
class _StartupResolver extends ConsumerStatefulWidget {
  final AuthState authState;
  const _StartupResolver({required this.authState});

  @override
  ConsumerState<_StartupResolver> createState() => _StartupResolverState();
}

class _StartupResolverState extends ConsumerState<_StartupResolver> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future _decide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      final permsDone = prefs.getBool('permissions_granted') ?? false;
      final lockSetup = prefs.getBool('lock_setup_completed') ?? false;
      final hasEverLoggedIn = prefs.getBool('has_ever_logged_in') ?? false;
      final isLoggedIn = widget.authState.isLoggedIn;



      // FIRST-TIME APP LAUNCH FLOW
      if (isFirstTime) {
        // Step 1: Show Dashboard first (as per requirement)
        if (!onboardingDone) {
          // Set a flag to trigger permissions after dashboard is shown
          await prefs.setBool('show_permissions_after_dashboard', true);
          _go('/dashboard');
          return;
        }

        // Step 2: Request permissions
        if (!permsDone) {
          _go('/permissions');
          return;
        }

        // Step 3: Set up lock screen
        if (!lockSetup) {
          _go('/app-passcode');
          return;
        }

        // Step 4: Show login screen (one-time only)
        if (!hasEverLoggedIn) {
          _go('/login');
          return;
        }
      }

      // NORMAL USAGE AFTER FIRST LOGIN
      if (hasEverLoggedIn && isLoggedIn) {
        // Check if PIN is required (app reopen/background)
        final pin = ref.read(pinProvider);
        if (pin.isRequired) {
          _go('/pin-unlock');
          return;
        }

        _go('/dashboard');
        return;
      }

      // FALLBACK: Not logged in
      _go('/login');
    } catch (e) {
      debugPrint('❌ Startup decision error: $e');
      _go('/login');
    }
  }

  void _go(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF422F90),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Preparing...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

import 'package:ecashbook_app/features/security/pin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/prefs_keys.dart';

// Main app class with optimized routing and lazy loading

void main() => runApp(const ProviderScope(child: EcashbookApp()));

class EcashbookApp extends ConsumerStatefulWidget {
  const EcashbookApp({super.key});

  @override
  ConsumerState<EcashbookApp> createState() => _EcashbookAppState();
}

class _EcashbookAppState extends ConsumerState<EcashbookApp>
    with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final pinNotifier = ref.read(pinProvider.notifier);
      pinNotifier.onAppLifecycleChanged(state);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'eCashbook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // Force light theme only
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

// Splash Screen that will be shown on app start
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add your app initialization logic here
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading

    // Ensure PIN provider is initialized by reading it
    debugPrint('🔐 SplashScreen: Ensuring PIN provider initialization...');
    ref.read(pinProvider); // This should trigger initialization

    // Wait for PIN provider to fully initialize
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted =
        prefs.getBool(PrefKeys.onboardingCompleted) ?? false;

    if (!onboardingCompleted) {
      // First time user - show introduction screen
      context.go('/onboarding');
    } else {
      // Onboarding completed - check login state
      final isLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (isLoggedIn) {
        // User is logged in - check if PIN is required
        final pinState = ref.read(pinProvider);

        debugPrint('🔐 SplashScreen: PIN required = ${pinState.isRequired}');

        if (pinState.isRequired) {
          // PIN is required - show unlock screen
          debugPrint('🔐 SplashScreen: Navigating to PIN unlock screen');
          context.go('/pin-unlock');
        } else {
          // No PIN required - go to dashboard
          debugPrint('🔐 SplashScreen: Navigating to dashboard');
          context.go('/dashboard');
        }
      } else {
        // User not logged in - go to login
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF422F90),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo or loading indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.account_balance_wallet,
                  size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'eCashbook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

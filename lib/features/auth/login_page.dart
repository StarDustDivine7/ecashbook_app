import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'
    show canLaunchUrl, launchUrl, LaunchMode;

import '../auth/auth_provider.dart';
import '../security/pin_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberedCredentials();
      // Check if we should auto-navigate to dashboard
      _checkAutoLogin();
    });
  }

  void _checkAutoLogin() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final isLoggedIn = prefs.getBool('user_logged_in') ?? false;
      final token = prefs.getString('auth_token');

      debugPrint(
          '🔐 Auto-login check: isLoggedIn=$isLoggedIn, hasToken=${token != null}');

      if (isLoggedIn && token != null && token.isNotEmpty && mounted) {
        debugPrint(
            '🔐 Auto-login: Verified login state, navigating to dashboard');
        context.pushReplacement('/dashboard');
      } else {
        debugPrint(
            '🔐 Auto-login: Not logged in or missing token, staying on login');
      }
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  void _loadRememberedCredentials() {
    final authState = ref.read(authProvider);
    if (authState.rememberedEmail != null &&
        authState.rememberedPassword != null) {
      _email.text = authState.rememberedEmail!;
      _password.text = authState.rememberedPassword!;
      setState(() {
        _rememberMe = true;
      });
      debugPrint('📝 Remembered credentials loaded');
      _showAutoLoginOption();
    }
  }

  void _showAutoLoginOption() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.login, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('Welcome back! Tap to login automatically.')),
          ],
        ),
        backgroundColor: const Color(0xFF422F90),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'LOGIN',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _handleLogin();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Dynamic API Login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoggingIn) {
      debugPrint('🔐 Login already in progress - ignoring duplicate request');
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      debugPrint('🔐 Starting login process...');
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.login(
        _email.text.trim(),
        _password.text,
        _rememberMe,
      );

      if (success) {
        debugPrint('✅ Login successful - preparing navigation');

        // Mark as having logged in at least once
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_ever_logged_in', true);
        await prefs.setBool('is_first_time', false);

        ref.read(pinProvider.notifier).clearPinRequired();
        debugPrint('🧹 PIN requirement cleared after login');
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && context.mounted) {
          context.pushReplacement('/dashboard');
        }
      } else {
        debugPrint('❌ Login failed - error will be shown by state listener');
      }
    } catch (e) {
      debugPrint('❌ Login exception: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Login failed. Please try again.')),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  void _showForgotPasswordModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xFF422F90),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Click below to reset your password.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse(
                  'https://portal.ecashbook.in/forget-password',
                );

                bool launched = await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );

                print('Launched: $launched');
              },
              child: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Color(0xFF422F90),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(authProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF422F90), Color(0xFF5A4FCF), Color(0xFF6B63FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logo section
              Expanded(
                flex: 3,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/white-logo.png',
                          width: 300,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.business,
                                      size: 60, color: Colors.white),
                                  SizedBox(height: 8),
                                  Text(
                                    'EcashBook',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Login form section
              Expanded(
                flex: 8,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              'Welcome to Ecashbook',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF422F90)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please login to continue.',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            if (authState.currentLocation != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 16, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Location detected',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                            // Email
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Username/Email Address',
                                prefixIcon: Icon(Icons.person_outline,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF422F90), width: 2),
                                ),
                                labelStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF422F90), fontSize: 16),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Password
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF422F90), width: 2),
                                ),
                                labelStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF422F90), fontSize: 16),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Remember / Forgot
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) => setState(
                                        () => _rememberMe = value ?? false),
                                    activeColor: const Color(0xFF422F90),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                Text('Remember Me',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                                const Spacer(),
                                TextButton(
                                  onPressed: _showForgotPasswordModal,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF422F90),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF422F90),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                  shadowColor: const Color(0xFF422F90)
                                      .withValues(alpha: 0.3),
                                ),
                                onPressed: (_isLoggingIn || authState.isLoading)
                                    ? null
                                    : _handleLogin,
                                child: (_isLoggingIn || authState.isLoading)
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Logging in...'),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login, size: 20),
                                          SizedBox(width: 8),
                                          Text('Log in',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

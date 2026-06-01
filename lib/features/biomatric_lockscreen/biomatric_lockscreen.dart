import 'package:ecashbook_app/features/biomatric_lockscreen/service/biomatric_lockScreen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricLockScreen extends ConsumerWidget {
  const BiometricLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockService = ref.watch(biometricLockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF422F90),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.fingerprint, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          label: const Text(
            'Unlock with Biometrics',
            style: TextStyle(fontSize: 18),
          ),
          onPressed: () async {
            final success = await lockService.authenticate(context);
            if (success) {
              // Once authenticated, return to dashboard or main page
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
      ),
    );
  }
}

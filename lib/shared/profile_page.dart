import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF422F90),
                    Color(0xFF5A4FCF),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar-dummy.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF422F90),
                              size: 35,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'admin@admin.com',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Options
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Personal Information',
              subtitle: 'Update your details',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and support',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and info',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF422F90).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF422F90),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // ✅ ENHANCED: Safe Logout with Loading State and Comprehensive Error Handling
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFF422F90),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // ✅ SAFE: Check context before navigation
              if (!context.mounted) return;

              Navigator.pop(context); // Close confirmation dialog

              // ✅ SAFE: Double check context
              if (!context.mounted) return;

              // Show loading with safe context check
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return const Dialog(
                    backgroundColor: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF422F90)),
                          SizedBox(height: 16),
                          Text(
                            'Logging out...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

              try {
                debugPrint('🚪 Profile page: Starting safe logout process');

                // ✅ SAFE: Clear preferences with null checks
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_first_time', false);
                  await prefs.setBool('user_logged_in', false);
                  debugPrint('✅ Preferences cleared safely from profile page');
                } catch (prefsError) {
                  debugPrint('⚠️ Preferences error (continuing): $prefsError');
                }

                // ✅ SAFE: Call auth logout with try-catch
                try {
                  await ref.read(authProvider.notifier).logout();
                  debugPrint('✅ Auth logout completed from profile page');
                } catch (authError) {
                  debugPrint('⚠️ Auth logout error (continuing): $authError');
                }

                // ✅ SAFE: Close loading dialog
                if (context.mounted) {
                  try {
                    Navigator.pop(context); // Close loading dialog
                    debugPrint('✅ Loading dialog closed from profile page');
                  } catch (popError) {
                    debugPrint('⚠️ Could not close loading dialog: $popError');
                  }
                }

                // ✅ SAFE: Wait and navigate
                await Future.delayed(const Duration(milliseconds: 50));

                if (context.mounted) {
                  try {
                    // ✅ SAFE: Use pushNamedAndRemoveUntil with error handling
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                          (route) => false,
                    );
                    debugPrint('✅ Safe navigation to login completed from profile page');
                  } catch (navError) {
                    debugPrint('❌ Navigation error from profile page, trying fallback: $navError');

                    // ✅ FALLBACK: Try alternative navigation
                    try {
                      Navigator.pushReplacementNamed(context, '/login');
                    } catch (fallbackError) {
                      debugPrint('❌ Fallback navigation failed from profile page: $fallbackError');
                    }
                  }
                }

              } catch (e) {
                debugPrint('❌ Profile page logout process error: $e');

                // ✅ EMERGENCY: Force navigation even on error
                if (context.mounted) {
                  try {
                    Navigator.pop(context); // Close any open dialog
                  } catch (_) {}

                  try {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                          (route) => false,
                    );
                  } catch (emergencyError) {
                    debugPrint('❌ Emergency navigation failed from profile page: $emergencyError');
                  }
                }
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isRequestingPermissions = false;

  final List<PermissionItem> _permissions = [
    PermissionItem(
      title: 'Location Access',
      description: 'Track your work location for accurate attendance',
      icon: Icons.location_on,
      permission: Permission.location,
      color: const Color(0xFF4CAF50),
    ),
    PermissionItem(
      title: 'Camera Access',
      description: 'Enable face authentication and profile photos',
      icon: Icons.camera_alt,
      permission: Permission.camera,
      color: const Color(0xFF2196F3),
    ),
    PermissionItem(
      title: 'Storage Access',
      description: 'Save and access payslips and documents',
      icon: Icons.folder,
      permission: Permission.storage,
      color: const Color(0xFFFF9800),
    ),
    PermissionItem(
      title: 'Notification',
      description: 'Receive important work updates and reminders',
      icon: Icons.notifications,
      permission: Permission.notification,
      color: const Color(0xFF9C27B0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 20),
              // Title + subtitle
              const Text(
                'App Permissions',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'EcashBook needs these permissions to provide the best experience. All data is secured and never shared.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 32),
              // Permissions list
              Expanded(
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permission = _permissions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[10],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: permission.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(permission.icon, color: permission.color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(permission.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  permission.description,
                                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red[10], borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Required',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[10],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your privacy is protected. Permissions can be managed in device settings.',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Allow All
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequestingPermissions ? null : _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF422F90),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isRequestingPermissions
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Requesting...'),
                    ],
                  )
                      : const Text('Allow All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequestingPermissions = true);
    try {
      // Request each permission sequentially
      for (final permissionItem in _permissions) {
        await permissionItem.permission.request();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Persist one-time flag so this page won’t reappear on app reopen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_granted', true);

      // Continue to location accuracy step
      _navigateToLocationAccuracy();
    } catch (e) {
      debugPrint('Permission request error: $e');
      _showPermissionError();
    } finally {
      if (mounted) setState(() => _isRequestingPermissions = false);
    }
  }

  void _navigateToLocationAccuracy() {
    Navigator.pushReplacementNamed(context, '/location-accuracy');
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Error'),
        content: const Text('Some permissions were denied. You can enable them later in device settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLocationAccuracy();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// Data Model
class PermissionItem {
  final String title;
  final String description;
  final IconData icon;
  final Permission permission;
  final Color color;

  PermissionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
    required this.color,
  });
}

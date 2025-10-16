import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_provider.dart';
import '../features/dashboard/dashboard_employee_provider.dart';
import '../core/utils/logout_handler.dart';
import 'main_layout.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch employee data from dashboard provider
    final employeeState = ref.watch(dashboardEmployeeProvider);
    final employeeDetails = employeeState.details;
    
    // Fetch employee data if not loaded or refresh if needed
    if (employeeDetails == null && !employeeState.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardEmployeeProvider.notifier).load();
      });
    }
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85, // Responsive width
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // User Profile Header - Fixed height to prevent overflow
            Container(
              height: 160, // Reduced height to prevent overflow
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF422F90),
                    Color(0xFF5A4FCF),
                    Color(0xFF6B63FF),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false, // Don't apply safe area to bottom
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                  child: Row(
                    children: [
                      // Profile Image - Smaller size
                      Container(
                        width: 55, // Smaller size
                        height: 55, // Smaller size
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: employeeState.loading
                            ? Container(
                                width: 55,
                                height: 55,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF422F90)),
                                ),
                              )
                            : employeeDetails?.profileImg != null && employeeDetails!.profileImg!.isNotEmpty
                              ? Image.network(
                                  employeeDetails.profileImg!,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 55,
                                      height: 55,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF422F90)),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback if network image fails
                                    return Container(
                                      width: 55,
                                      height: 55,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF422F90),
                                        size: 30,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 55,
                                  height: 55,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF422F90),
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      // User Info - Flexible to prevent overflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Name - Dynamic from API
                            Text(
                              employeeState.loading 
                                ? 'Loading...' 
                                : (employeeDetails?.name.isNotEmpty == true 
                                    ? employeeDetails!.name 
                                    : 'Employee'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Reduced from 18
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Job Role - Dynamic from API
                            Text(
                              employeeState.loading 
                                ? 'Loading...' 
                                : (employeeDetails?.designationName.isNotEmpty == true 
                                    ? '${employeeDetails!.designationName} • ${employeeDetails.employeeId}' 
                                    : 'Employee'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12, // Reduced from 13
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                            // Email - Dynamic from API
                            Text(
                              employeeState.loading 
                                ? 'Loading...' 
                                : (employeeDetails?.email.isNotEmpty == true 
                                    ? employeeDetails!.email 
                                    : 'No email'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10, // Reduced from 11
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  // ✅ 1. Dashboard
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMainLayout(context, 2); // Dashboard index
                    },
                  ),

                  // ✅ 2. Attendance History
                  _buildMenuItem(
                    context,
                    icon: Icons.fingerprint,
                    title: 'Attendance History',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMainLayout(context, 5); // Attendance index
                    },
                  ),

                  // ✅ 3. Task Management
                  _buildMenuItem(
                    context,
                    icon: Icons.task_alt,
                    title: 'Task Management',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMainLayout(context, 1); // Tasks index
                    },
                  ),

                  // ✅ 4. Generate Payslip
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Generate Payslip',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMainLayout(context, 0); // Payslip index
                    },
                  ),

                  // ✅ 5. Leave Management (Expandable) - UPDATED
                  _buildExpandableMenuItem(
                    context,
                    icon: Icons.event_note,
                    title: 'Leave Management',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
                    ),
                    children: [
                      // ✅ 5.1 Leave Requests
                      _buildSubMenuItem(
                        context,
                        title: 'Leave Requests',
                        icon: Icons.assignment,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToMainLayout(context, 7); // Leave List index
                        },
                      ),
                      // ✅ 5.2 Apply for Leave
                      _buildSubMenuItem(
                        context,
                        title: 'Apply for Leave',
                        icon: Icons.add_circle_outline,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToMainLayout(context, 3); // Apply Leave index
                        },
                      ),
                    ],
                  ),

                  // ✅ 6. HR Letter
                  _buildMenuItem(
                    context,
                    icon: Icons.mail_outline,
                    title: 'HR Letter',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMainLayout(context, 6); // HR Letters index
                    },
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ),

                  // Help & Support
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NAVIGATION HELPER - Navigate to MainLayout with specific index
  void _navigateToMainLayout(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainLayout(initialIndex: index),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Gradient gradient,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18, // Reduced icon size
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13, // Reduced from 15
                      color: Color(0xFF2C3E50),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Gradient gradient,
        required List<Widget> children,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Remove divider lines
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18, // Reduced icon size
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13, // Reduced from 15
              color: Color(0xFF2C3E50),
            ),
          ),
          iconColor: const Color(0xFF422F90),
          collapsedIconColor: const Color(0xFF422F90),
          childrenPadding: const EdgeInsets.only(bottom: 10),
          children: children,
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 40), // Indent for sub-items
                Icon(
                  icon,
                  size: 14, // Reduced icon size
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12, // Reduced from 14
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFF422F90),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF422F90),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog immediately
                
                // Use the new logout handler
                await LogoutHandler.performLogout(context, ref);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF422F90)),
            SizedBox(width: 10),
            Text(
              'Help & Support',
              style: TextStyle(
                color: Color(0xFF422F90),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance? Contact our support team:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.email, color: Color(0xFF422F90), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'support@ecashbook.com',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: Color(0xFF422F90), size: 18),
                SizedBox(width: 8),
                Text(
                  '+91 98765 43210',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              'App Version: 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF422F90),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

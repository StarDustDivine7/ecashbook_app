import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_employee_provider.dart';
import '../features/auth/auth_provider.dart';
import '../core/utils/logout_handler.dart';
import '../core/services/auth_service.dart';
import '../features/profile/personal_info_page.dart';
import '../features/profile/help_support_page.dart';
import '../features/profile/about_page.dart';
import '../features/policy/policy_list_page.dart';
import 'bottom_sheet_host.dart';
import 'fullscreen_bottom_sheet.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _handledEmployeeError = false;

  /// Returns true only for actual authentication/authorization errors
  bool _isAuthError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('unauthorized') ||
        lower.contains('unauthenticated') ||
        lower.contains('token') ||
        lower.contains('401') ||
        lower.contains('not authenticated') ||
        lower.contains('token_mismatch');
  }

  @override
  void initState() {
    super.initState();
    // Load employee details when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardEmployeeProvider.notifier).load();
    });
  }

  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(dashboardEmployeeProvider);

    if (!_handledEmployeeError &&
        employeeState.error != null &&
        employeeState.error!.isNotEmpty) {
      _handledEmployeeError = true;
      // Only force-logout on actual auth errors, not generic network/server errors
      if (_isAuthError(employeeState.error!)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await LogoutHandler.handleUnauthorizedResponse(context, ref);
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardEmployeeProvider.notifier).load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(employeeState),
              const SizedBox(height: 20),

              // Profile Options

              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: 'Update your details',
                onTap: () {
                  showFullScreenBottomSheet(
                    context: context,
                    title: 'Personal Information',
                    child: const PersonalInfoPage(),
                  );

                  // _openProfileSheet(context, 'Personal Information',
                  //     const PersonalInfoPage());
                },
              ),

              _buildProfileOption(
                icon: Icons.policy_outlined,
                title: 'Company Policy',
                subtitle: 'Privacy Policy, Terms & Conditions',
                onTap: () {
                  showFullScreenBottomSheet(
                    context: context,
                    title: 'Company Policies',
                    child: const CompanyPolicyListPage(),
                  );
                  // _openProfileSheet(context, 'Company Policies',
                  //     const CompanyPolicyListPage());
                },
              ),
              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and support',
                onTap: () {
                  showFullScreenBottomSheet(
                    context: context,
                    title: 'Help & Support',
                    child: const HelpSupportPage(),
                  );

                  // _openProfileSheet(
                  //     context, 'Help & Support', const HelpSupportPage());
                },
              ),
              _buildProfileOption(
                icon: Icons.info_outline,
                title: 'About Us',
                subtitle: 'App version and info',
                onTap: () {
                  showFullScreenBottomSheet(
                    context: context,
                    title: 'About EcashBoo',
                    child: const AboutPage(),
                  );
                  // _openProfileSheet(
                  //     context, 'About EcashBook', const AboutPage());
                },
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
      ),
    );
  }

  void showFullScreenBottomSheet({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF422F90),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(DashboardEmployeeState employeeState) {
    final details = employeeState.details;
    final loading = employeeState.loading;
    final error = employeeState.error;

    final status = details?.status ?? '—';
    final isActive = (status.toLowerCase() == 'active');
    final name =
        (details != null && details.name.isNotEmpty) ? details.name : '—';
    final empId = (details != null && details.employeeId.isNotEmpty)
        ? details.employeeId
        : '—';
    final designation = (details != null && details.designationName.isNotEmpty)
        ? details.designationName
        : '';

    return Container(
      // margin: const EdgeInsets.all(20).copyWith(top: 0, bottom: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_primaryPurple, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _primaryPurple.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: loading
                      ? Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : details?.profileImg != null &&
                              details!.profileImg!.isNotEmpty
                          ? Image.network(
                              details.profileImg!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                );
                              },
                              errorBuilder: (context, e, st) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 36),
                                );
                              },
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 36),
                            ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isActive ? Colors.green : Colors.red)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: (isActive ? Colors.green : Colors.red)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive
                                    ? 'Active'
                                    : (status.isNotEmpty ? status : '—'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading ? 'Loading...' : name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      designation.isEmpty ? empId : '$designation • $empId',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  _getCurrentDate(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
              ],
            ),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Text(
                error,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white,
      child: const Icon(
        Icons.person,
        color: Color(0xFF422F90),
        size: 35,
      ),
    );
  }

  void _openProfileSheet(
    BuildContext context,
    String title,
    Widget child,
  ) {
    final host = BottomSheetHost.of(context);
    if (host == null) return;

    late PersistentBottomSheetController sheetController;

    sheetController = host.show((ctx) {
      return Container(
        width: double.maxFinite,
        height: MediaQuery.of(ctx).size.height,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF422F90),
                    Color(0xFF6E48AA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      sheetController.close();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    });
  }

  // void _openProfileSheet(BuildContext context, String title, Widget child) {
  //   final host = BottomSheetHost.of(context);
  //   if (host == null) return;
  //   late PersistentBottomSheetController sheetController;
  //   sheetController = host.show((ctx) {
  //     final h = MediaQuery.of(ctx).size.height;
  //     return Container(
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //       ),
  //       child: SizedBox(
  //         height: h,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
  //               decoration: const BoxDecoration(
  //                 gradient: LinearGradient(
  //                   colors: [Color(0xFF422F90), Color(0xFF6E48AA)],
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                 ),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Expanded(
  //                     child: Text(
  //                       title,
  //                       style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.w700),
  //                     ),
  //                   ),
  //                   IconButton(
  //                     onPressed: () {
  //                       sheetController.close();
  //                     },
  //                     icon:
  //                         const Icon(Icons.close_rounded, color: Colors.white),
  //                   )
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               child: child,
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   });
  // }

  Future<T?> showFullscreenBottomSheet<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FullscreenBottomSheet(
        title: title,
        child: child,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not specified',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
  void _showLogoutDialog(BuildContext outerContext, WidgetRef ref) {
    showDialog(
      context: outerContext,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // SAFE: Check context before navigation
              if (!outerContext.mounted) return;

              Navigator.pop(dialogContext); // Close confirmation dialog

              // SAFE: Double check context
              if (!outerContext.mounted) return;

              // Use auth provider's logout method to properly clear data and update state
              try {
                debugPrint('🚪 Starting logout from profile page');
                await ref.read(authProvider.notifier).logout();
                debugPrint('✅ Logout completed successfully');
              } catch (e) {
                debugPrint('❌ Logout error: $e');
                // Fallback: clear data manually if logout fails
                try {
                  await AuthService.clearAllAppData();
                } catch (_) {}
              }

              if (!outerContext.mounted) return;
              // Navigate to Login using Go Router
              debugPrint('🔄 Navigating to login page');
              outerContext.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

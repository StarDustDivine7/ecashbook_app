import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/dashboard/dashboard.dart';
import '../features/leave/apply_leave.dart';
import '../features/payslip/payslip_page.dart' as payslip;
import '../features/tasks/task_list.dart' as tasks;
// ✅ Import the 6 additional pages
import '../features/attendance/attendance.dart';
import '../features/hr_letter/hr_letter_list.dart';
import '../features/leave/leave_list.dart';
import '../features/leave/leave_status.dart';
import '../features/tasks/task_view.dart';
import '../features/expenditure/claims_list.dart';
import '../features/supply/supply_list.dart';
import 'bottom_menu.dart';
import 'header.dart';
import 'profile_page.dart';
import 'side_menu.dart';
import 'bottom_sheet_host.dart';
import '../features/profile/personal_info_page.dart';
import '../features/profile/help_support_page.dart';
import '../features/profile/about_page.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  final String? taskId; // For TaskViewPage
  final String? requestId; // For LeaveStatusPage
  final bool isReadOnlyTask; // For making task view read-only

  const MainLayout({
    super.key,
    this.initialIndex = 2, // Default to Dashboard (index 2)
    this.taskId,
    this.requestId,
    this.isReadOnlyTask = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPressTime;
  PersistentBottomSheetController? _bottomSheetController;
  bool _justClosedSheet = false;

  // Double-tap detection for refresh
  DateTime? _lastTabTapTime;
  int? _lastTappedIndex;
  int _pageRefreshKey = 0; // Key to force page rebuild

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Page titles for all 11 pages
  final List<String> _pageTitles = [
    'Generate Payslip', // 0 - Payslip
    'Task Management', // 1 - Tasks
    'Dashboard', // 2 - Dashboard (default)
    'Leave Requests', // 3 - Leave List
    'My Profile', // 4 - Profile
    'Attendance History', // 5 - Attendance
    'HR Letters', // 6 - HR Letters
    'Apply for Leave', // 7-  Apply for leave
    'Leave Status', // 8 - Leave Status
    'Task Details', // 9 - Task View
    'Expenditure Claims', // 10 - Expenditure Claims
    'Supply Requisitions', // 11 - Supply Requisitions
    'Personal Information', // 12 - Personal Info
    'Help & Support', // 13 - Help & Support
    'About', // 14 - About
  ];

  // All pages - getter to handle conditional parameters
  List<Widget> get _pages => [
        const payslip.PayslipPage(), // 0 - Payslip
        const tasks.TaskListPage(), // 1 - Tasks
        const Dashboard(), // 2 - Dashboard (default)
        const LeaveListPage(), // 3 - Leave List
        const ProfilePage(), // 4 - Profile
        const AttendancePage(), // 5 - Attendance
        const HrLetterListPage(), // 6 - HR Letters
        const ApplyLeavePage(), // 7 - Apply Leave
        // Conditional pages with parameters
        widget.requestId != null
            ? LeaveStatusPage(requestId: widget.requestId!) // 8 - Leave Status
            : const _PlaceholderPage(
                title: 'Leave Status', message: 'Request ID required'),
        widget.taskId != null
            ?
        TaskViewPage(
                taskId: widget.taskId!,
                isReadOnly: widget.isReadOnlyTask,
              ) // 9 - Task View
            : const _PlaceholderPage(
                title: 'Task Details', message: 'Task ID required'),
        const ClaimsListPage(), // 10 - Expenditure Claims
        const SupplyListPage(), // 11 - Supply Requisitions
        const PersonalInfoPage(), // 12 - Personal Info
        const HelpSupportPage(), // 13 - Help & Support
        const AboutPage(), // 14 - About
      ];

  // Handle navigation from side menu or other sources
  void _navigateToIndex(int index) {
    // Close any open bottom sheet when navigating
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
    }
    
    setState(() {
      _currentIndex = index;
      // Reset double-tap tracking when changing pages
      _lastTabTapTime = null;
      _lastTappedIndex = null;
    });
    
    HapticFeedback.lightImpact();
  }

  void _onTabTapped(int index) {
    // Validate index range
    if (index < 0 || index >= _pages.length) {
      return;
    }

    // Close any open bottom sheet when navigating
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
    }

    final now = DateTime.now();

    if (_currentIndex == index) {
      // Same tab tapped - check for double tap
      if (_lastTappedIndex == index &&
          _lastTabTapTime != null &&
          now.difference(_lastTabTapTime!) <
              const Duration(milliseconds: 500)) {
        // Double tap detected - refresh the page
        _refreshCurrentPage();

        // Reset double-tap tracking
        _lastTabTapTime = null;
        _lastTappedIndex = null;
      } else {
        // First tap on same tab - start tracking
        _lastTabTapTime = now;
        _lastTappedIndex = index;

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Tap again to refresh ${_pageTitles[index]}'),
              ],
            ),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: const Color(0xFF422F90),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    // Navigate to different page
    _navigateToIndex(index);
  }

  void _refreshCurrentPage() {
    HapticFeedback.mediumImpact();

    setState(() {
      // Increment key to force page rebuild
      _pageRefreshKey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('${_pageTitles[_currentIndex]} refreshed'),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        //   margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Handle back button with smart navigation
  Future<bool> _handleBackPress() async {
    if (_currentIndex != 2) {
      // Go to Dashboard if not already there
      _onTabTapped(2);
      return false;
    }

    // Double tap to exit from Dashboard
    final currentTime = DateTime.now();
    if (_lastBackPressTime == null ||
        currentTime.difference(_lastBackPressTime!) >
            const Duration(seconds: 2)) {
      _lastBackPressTime = currentTime;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Press back again to exit app'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF422F90),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return true; // Exit app
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // If there is any modal route/sheet/dialog on top, let Navigator pop it first
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
            return;
          }
          // If a persistent bottom sheet is open, close it first
          if (_bottomSheetController != null) {
            setState(() => _justClosedSheet = true);
            _bottomSheetController!.close();
            return;
          }
          // Consume the back press right after a sheet was closed
          if (_justClosedSheet) {
            setState(() => _justClosedSheet = false);
            return;
          }
          final shouldPop = await _handleBackPress();
          if (shouldPop && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        // Side drawer
        drawer: const SideMenu(),
        // Dynamic header
        appBar: Header(
          pageTitle: _pageTitles[_currentIndex],
          onMenuPressed: () {
            _scaffoldKey.currentState?.openDrawer();
            HapticFeedback.lightImpact();
          },
        ),
        // Main content wrapped with BottomSheetHost so children can show persistent sheets
        body: BottomSheetHost(
          show: (builder) {
            final state = _scaffoldKey.currentState;
            if (state == null) {
              throw StateError('ScaffoldState is not available');
            }
            // Close any existing sheet before opening a new one
            _bottomSheetController?.close();
            final controller = state.showBottomSheet(
              (ctx) {
                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    // Intercept back press to close only the sheet
                    if (_bottomSheetController != null) {
                      _bottomSheetController!.close();
                    }
                  },
                  child: Builder(builder: builder),
                );
              },
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              elevation: 8,
            );
            setState(() {
              _bottomSheetController = controller;
            });
            controller.closed.whenComplete(() {
              if (mounted) {
                setState(() {
                  _bottomSheetController = null;
                });
              }
            });
            return controller;
          },
          child: IndexedStack(
            key: ValueKey(_pageRefreshKey), // Force rebuild when key changes
            index: _currentIndex,
            children: _pages,
          ),
        ),
        // Bottom navigation
        bottomNavigationBar: BottomMenuBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

// Placeholder widget for conditional/future pages
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderPage({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF64748B).withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to dashboard
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainLayout(initialIndex: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.home_rounded, size: 16),
                label: const Text('Go to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF422F90),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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

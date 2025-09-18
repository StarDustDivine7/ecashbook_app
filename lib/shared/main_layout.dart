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
import 'bottom_menu.dart';
import 'header.dart';
import 'profile_page.dart';
import 'side_menu.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  final String? taskId; // For TaskViewPage
  final String? requestId; // For LeaveStatusPage

  const MainLayout({
    super.key,
    this.initialIndex = 2, // Default to Dashboard (index 2)
    this.taskId,
    this.requestId,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    debugPrint('🎯 MainLayout initialized with index: $_currentIndex');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Page titles for all 11 pages
  final List<String> _pageTitles = [
    'Generate Payslip',    // 0 - Payslip
    'Task Management',     // 1 - Tasks
    'Dashboard',           // 2 - Dashboard (default)
    'Leave Requests',      // 3 - Leave List
    'My Profile',          // 4 - Profile
    'Attendance History',  // 5 - Attendance
    'HR Letters',          // 6 - HR Letters
    'Apply for Leave',     // 7-  Apply for leave
    'Leave Status',        // 8 - Leave Status
    'Task Details',        // 9 - Task View
    'Reserved',            // 10 - Reserved for future
  ];

  // All pages - getter to handle conditional parameters
  List<Widget> get _pages => [
    const payslip.PayslipPage(),     // 0 - Payslip
    const tasks.TaskListPage(),      // 1 - Tasks
    const Dashboard(),               // 2 - Dashboard (default)
    const LeaveListPage(),           // 3 - Leave List
    const ProfilePage(),             // 4 - Profile
    const AttendancePage(),          // 5 - Attendance
    const HrLetterListPage(),        // 6 - HR Letters
    const ApplyLeavePage(),          // 7 - Apply Leave
    // Conditional pages with parameters
    widget.requestId != null
        ? LeaveStatusPage(requestId: widget.requestId!)  // 8 - Leave Status
        : const _PlaceholderPage(title: 'Leave Status', message: 'Request ID required'),
    widget.taskId != null
        ? TaskViewPage(taskId: widget.taskId!)           // 9 - Task View
        : const _PlaceholderPage(title: 'Task Details', message: 'Task ID required'),
    const _PlaceholderPage(title: 'Reserved', message: 'Feature coming soon'),  // 10 - Reserved
  ];

  void _onTabTapped(int index) {
    // Validate index range
    if (index < 0 || index >= _pages.length) {
      debugPrint('❌ Invalid page index: $index (max: ${_pages.length - 1})');
      return;
    }

    debugPrint('🎯 Navigating to page: $index (${_pageTitles[index]})');

    if (_currentIndex == index) {
      // Same tab tapped - provide feedback
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('${_pageTitles[index]} refreshed'),
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
      return;
    }

    // Navigate to different page
    setState(() {
      _currentIndex = index;
    });

    HapticFeedback.lightImpact();
  }

  // Handle back button with smart navigation
  Future<bool> _handleBackPress() async {
    if (_currentIndex != 2) {
      // Go to Dashboard if not already there
      debugPrint('🔄 Back pressed: Going to Dashboard');
      _onTabTapped(2);
      return false;
    }

    // Double tap to exit from Dashboard
    final currentTime = DateTime.now();
    if (_lastBackPressTime == null ||
        currentTime.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
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

    debugPrint('🚪 Exiting app');
    return true; // Exit app
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ Building MainLayout with page: ${_pageTitles[_currentIndex]}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
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

        // Main content - No swipe, only button navigation
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

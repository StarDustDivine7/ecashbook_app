import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/models/holiday_model.dart';
import '../../core/models/daily_activity_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/network/api_client.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with TickerProviderStateMixin {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late AnimationController _slideController;

  // Colors based on your existing page design
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _accentBlue = Color(0xFF3B82F6);

  // Map of Date to attendance status string from API
  Map<DateTime, String> _attendanceStatus = {};
  

  
  // Summary data from API
  Map<String, int> _attendanceSummary = {};

  // Daily activity data from API
  DailyActivityData? _selectedDayActivity;
  bool _loadingDailyActivity = false;

  bool _loadingAttendance = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize dates properly - normalize to date only (no time)
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedDay = DateTime(now.year, now.month, now.day);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController.forward();
    _fetchAttendanceFromApi();
    
    // Fetch today's activity since today's date is selected by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDailyActivity(_selectedDay);
      // Force a rebuild to ensure the calendar shows the correct selection
      if (mounted) {
        setState(() {
          // Ensure _selectedDay is properly set to today
          final now = DateTime.now();
          _selectedDay = DateTime(now.year, now.month, now.day);
        });
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceFromApi() async {
    setState(() { _loadingAttendance = true; });
    try {
      final user = await AuthService.getSavedUser();
      if (user?.employeeId == null) return;
      final secure = await AuthService.getSecure();
      if (secure == null) return;

      final result = await AttendanceService.fetchMonthlyAttendance(
        empId: user!.employeeId,
        month: _focusedDay,
        secure: secure,
      );
      
      setState(() { 
        _attendanceStatus = result['statusMap'] as Map<DateTime, String>;
        _attendanceSummary = result['summary'] as Map<String, int>;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to load attendance data: ${e.toString()}');
      }
    } finally {
      setState(() { _loadingAttendance = false; });
    }
  }

  Future<void> _showHolidayModal() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryPurple),
        ),
      ),
    );

    try {
      final user = await AuthService.getSavedUser();
      if (user == null || user.employeeId.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          _showErrorSnackbar('Please login again to continue');
        }
        return;
      }
      final secure = await AuthService.getSecure();
      if (secure == null || secure.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          _showErrorSnackbar('Session expired. Please login again');
        }
        return;
      }

      final holidayData = await ApiClient.fetchCompanyHolidays(
        empId: user.employeeId,
        year: DateTime.now().year.toString(),
        secure: secure,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (holidayData.isEmpty) {
        _showInfoSnackbar('No holidays found for this year');
        return;
      }

      final holidays = holidayData
          .map<Holiday>((e) => Holiday.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_note_rounded,
                          color: _accentOrange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Holiday Calendar ${DateTime.now().year}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const Text(
                            "National holidays and festivals",
                            style: TextStyle(
                              fontSize: 13,
                              color: _textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${holidays.length} Days",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 500,
                  child: ListView.builder(
                    itemCount: holidays.length,
                    itemBuilder: (context, index) {
                      final holiday = holidays[index];
                      final date = DateFormat("dd MMM yyyy")
                          .format(DateFormat("yyyy-MM-dd").parse(holiday.holidayDate));

                      final isNational = holiday.holidayType
                          .toLowerCase()
                          .contains("national");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isNational
                                  ? _errorRed.withOpacity(0.15)
                                  : _accentOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isNational
                                  ? Icons.flag_rounded
                                  : Icons.celebration_rounded,
                              color: isNational ? _errorRed : _accentOrange,
                            ),
                          ),
                          title: Text(
                            holiday.holidayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isNational
                                        ? _errorRed.withOpacity(0.15)
                                        : _accentOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    holiday.holidayType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isNational ? _errorRed : _accentOrange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackbar("Failed to fetch holidays: ${e.toString()}");
    }
  }

  void _showErrorSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.blue),
    );
  }

  void _handleDaySelection(DateTime selectedDay, DateTime focusedDay) {
    // Normalize dates to date only (no time components)
    final normalizedSelectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final normalizedFocusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
    
    // Always fetch daily activity, even if it's the same date
    _fetchDailyActivity(normalizedSelectedDay);
    
    setState(() {
      _selectedDay = normalizedSelectedDay;
      _focusedDay = normalizedFocusedDay;
    });
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _fetchDailyActivity(DateTime selectedDate) async {
    if (!mounted) return;
    
    setState(() {
      _loadingDailyActivity = true;
      _selectedDayActivity = null;
    });

    try {
      final user = await AuthService.getSavedUser();
      if (user == null || user.employeeId.isEmpty) {
        if (mounted) {
          _showErrorSnackbar('Please login again to continue');
        }
        return;
      }
      
      final secure = await AuthService.getSecure();
      if (secure == null || secure.isEmpty) {
        if (mounted) {
          _showErrorSnackbar('Session expired. Please login again');
        }
        return;
      }

      final dailyActivity = await AttendanceService.fetchDailyActivity(
        empId: user.employeeId,
        date: selectedDate,
        secure: secure,
      );

      if (!mounted) return;

      if (dailyActivity != null && dailyActivity.success) {
        setState(() {
          _selectedDayActivity = dailyActivity.data;
        });
      } else {
        setState(() {
          _selectedDayActivity = null;
        });
        _showInfoSnackbar(dailyActivity?.message ?? 'No activity data found for this date');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedDayActivity = null;
      });
      _showErrorSnackbar("Failed to fetch daily activity: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _loadingDailyActivity = false;
        });
      }
    }
  }



  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return _accentGreen;
      case 'absent':
        return _errorRed;
      case 'leave':
        return _accentOrange;
      case 'holiday':
        return _accentBlue;
      default:
        return _textLight;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'leave':
        return Icons.event_busy_rounded;
      case 'holiday':
        return Icons.celebration_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildHolidayButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showHolidayModal,
          icon: const Icon(Icons.event_available_rounded, size: 20),
          label: const Text(
            'Show Holiday List',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryCard() {
    if (_attendanceSummary.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryPurple, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      _getMonthYear(_focusedDay),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Present',
                    _attendanceSummary['totalPresent']?.toString() ?? '0',
                    _accentGreen,
                    Icons.check_circle_rounded,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Absent',
                    _attendanceSummary['totalAbsent']?.toString() ?? '0',
                    _errorRed,
                    Icons.cancel_rounded,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Leave',
                    _attendanceSummary['totalLeave']?.toString() ?? '0',
                    _accentOrange,
                    Icons.event_busy_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Holiday',
                    _attendanceSummary['totalHoliday']?.toString() ?? '0',
                    _accentBlue,
                    Icons.celebration_rounded,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Office Off',
                    _attendanceSummary['totalOfficeOff']?.toString() ?? '0',
                    Colors.black54,
                    Icons.business_rounded,
                  ),
                ),
                const Expanded(child: SizedBox()), // Empty space for alignment
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: _loadingAttendance
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHolidayButton(),
                _buildAttendanceSummaryCard(),
                _buildCalendarCard(),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _slideController.value) * 50),
                  child: Opacity(
                    opacity: _slideController.value,
                    child: _buildDayDetailsCard(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryPurple.withOpacity(0.1),
                  _primaryDark.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryPurple, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      _getMonthYear(_focusedDay),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getPresentDays()}P',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<String>(
              firstDay: DateTime(_focusedDay.year, 1, 1),
              lastDay: DateTime(_focusedDay.year, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay), // Enable proper selection
              enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
              eventLoader: (day) {
                final status = _attendanceStatus[DateTime(day.year, day.month, day.day)];
                return status == null ? [] : [status];
              },
              //-------- Full date number colored-------
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  final status = _attendanceStatus[DateTime(date.year, date.month, date.day)];
                  final isDisabled = date.isAfter(DateTime.now());
                  final isToday = isSameDay(date, DateTime.now());
                  final isSelected = isSameDay(date, _selectedDay);
                  
                  // Determine base color from attendance status
                  Color numberColor;
                  if (status == null) {
                    numberColor = _textDark;
                  } else {
                    switch (status) {
                      case 'present': numberColor = _accentGreen; break;
                      case 'absent': numberColor = _errorRed; break;
                      case 'leave': numberColor = _accentOrange; break;
                      case 'office off': numberColor = Colors.black; break;
                      case 'holiday': numberColor = _accentBlue; break;
                      default: numberColor = Colors.grey;
                    }
                  }

                  // Determine decoration and text color based on state
                  BoxDecoration decoration;
                  Color textColor;
                  
                  if (isSelected) {
                    // Selected date - use purple gradient (this includes today if selected)
                    decoration = BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryPurple, _primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    );
                    textColor = Colors.white;
                  } else if (isToday) {
                    // Today's date (not selected) - use orange border
                    decoration = BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentOrange, width: 2),
                    );
                    textColor = _accentOrange;
                  } else {
                    // Regular date - transparent background with status color
                    decoration = BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    );
                    textColor = numberColor;
                  }

                  return GestureDetector(
                    onTap: isDisabled ? null : () {
                      _handleDaySelection(date, _focusedDay);
                    },
                    child: Container(
                      decoration: decoration,
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                
                // Add selected day builder to ensure proper selection highlighting
                selectedBuilder: (context, date, _) {
                  final status = _attendanceStatus[DateTime(date.year, date.month, date.day)];
                  
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryPurple, _primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
                
                // Add today builder to ensure today is highlighted when not selected
                todayBuilder: (context, date, _) {
                  final status = _attendanceStatus[DateTime(date.year, date.month, date.day)];
                  final isSelected = isSameDay(date, _selectedDay);
                  
                  // If today is selected, let selectedBuilder handle it
                  if (isSelected) return null;
                  
                  // Determine base color from attendance status
                  Color numberColor;
                  if (status == null) {
                    numberColor = _accentOrange;
                  } else {
                    switch (status) {
                      case 'present': numberColor = _accentGreen; break;
                      case 'absent': numberColor = _errorRed; break;
                      case 'leave': numberColor = _accentOrange; break;
                      case 'office off': numberColor = Colors.black; break;
                      case 'holiday': numberColor = _accentBlue; break;
                      default: numberColor = _accentOrange;
                    }
                  }
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentOrange, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _accentOrange,
                        ),
                      ),
                    ),
                  );
                },
              ),


              //----- Small colored dot below the date number ----
              // calendarBuilders: CalendarBuilders(
              //   defaultBuilder: (context, date, _) {
              //     final status = _attendanceStatus[DateTime(date.year, date.month, date.day)];
              //     if (status == null) return null;
              //
              //     Color dotColor;
              //     switch (status) {
              //       case 'present': dotColor = _accentGreen; break;
              //       case 'absent': dotColor = _errorRed; break;
              //       case 'leave': dotColor = _accentOrange; break;
              //       case 'office off': dotColor = Colors.black; break;
              //       case 'holiday': dotColor = _accentBlue; break;
              //       default: dotColor = Colors.grey;
              //     }
              //
              //     return Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Text(
              //           '${date.day}',
              //           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textDark),
              //         ),
              //         const SizedBox(height: 2),
              //         Container(
              //           width: 6,
              //           height: 6,
              //           decoration: BoxDecoration(
              //             color: dotColor,
              //             shape: BoxShape.circle,
              //           ),
              //         ),
              //       ],
              //     );
              //   },
              // ),

              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isAfter(DateTime.now())) return;
                _handleDaySelection(selectedDay, focusedDay);
              },
              onDayLongPressed: (selectedDay, focusedDay) {
                if (selectedDay.isAfter(DateTime.now())) return;
                _handleDaySelection(selectedDay, focusedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _fetchAttendanceFromApi();
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: _textDark),
                holidayTextStyle: const TextStyle(color: _errorRed),
                // Disable built-in decorations since we use custom builder
                selectedDecoration: const BoxDecoration(),
                selectedTextStyle: const TextStyle(),
                todayDecoration: const BoxDecoration(),
                todayTextStyle: const TextStyle(),
                defaultDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledTextStyle: TextStyle(
                  color: const Color(0xFF64748B).withOpacity(0.5),
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                markerSize: 6,
                markersMaxCount: 1,
              ),

              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: _primaryPurple,
                    size: 20,
                  ),
                ),
                rightChevronIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: _primaryPurple,
                    size: 20,
                  ),
                ),
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                weekendStyle: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  int _getPresentDays() {
    return _attendanceSummary['totalPresent'] ?? 0;
  }

  Widget _buildDayDetailsCard() {
    // Check if the selected day is in the future
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final isFuture = _selectedDay.isAfter(DateTime.now());
    
    if (isFuture) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 40, color: _textLight),
              const SizedBox(height: 12),
              Text(
                'Future date selected',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textLight),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a past or current date to view attendance details.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _textLight.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingDailyActivity) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryPurple),
              ),
              SizedBox(height: 12),
              Text(
                'Loading daily activity...',
                style: TextStyle(fontSize: 14, color: _textLight),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedDayActivity == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, size: 40, color: _textLight),
              const SizedBox(height: 12),
              Text(
                isToday 
                  ? 'No attendance data for today yet.'
                  : 'No attendance data for ${DateFormat('dd MMM yyyy').format(_selectedDay)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textLight),
              ),
            ],
          ),
        ),
      );
    }

    final data = _selectedDayActivity!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(data.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(data.status), 
                  size: 18, 
                  color: _getStatusColor(data.status)
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details for ${DateFormat('dd MMM yyyy').format(_selectedDay)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    Text(
                      '${data.dayName} • ${data.status.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: _textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(data.status),
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 24, thickness: 1, color: _borderColor),
          
          // Timing Details
          _buildTimingRow('In Time:', data.inTime ?? '--:--', Icons.login_rounded, _accentGreen),
          _buildTimingRow('Out Time:', data.outTime ?? '--:--', Icons.logout_rounded, _errorRed),
          _buildInfoRow('Working Hours:', data.workingHours ?? '0h 0m', Icons.hourglass_bottom_rounded),
          
          if (data.isLate && data.lateBy != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Late By:', data.lateBy!, Icons.warning_rounded, isWarning: true),
          ],
          
          // Office Hours
          const SizedBox(height: 8),
          _buildInfoRow('Office Hours:', '${data.openingTime} - ${data.closingTime}', Icons.business_rounded),
          _buildInfoRow('Work Location:', data.workLocationStatus, Icons.location_on_rounded),
          
          // Lunch Section
          if (data.lunchIn != null || data.lunchOut != null || data.lunchStatus.isNotEmpty) ...[
            const Divider(height: 24, thickness: 1, color: _borderColor),
            _buildSectionTitle('Lunch Break', Icons.restaurant_rounded),
            const SizedBox(height: 8),
            _buildInfoRow('Lunch In:', data.lunchIn ?? 'Not started', Icons.restaurant_rounded),
            _buildInfoRow('Lunch Out:', data.lunchOut ?? 'Ongoing', Icons.restaurant_rounded),
            _buildInfoRow('Status:', data.lunchStatus.toUpperCase(), Icons.info_rounded),
            if (data.totalLunchTime != null)
              _buildInfoRow('Total Time:', data.totalLunchTime!, Icons.timer_rounded),
          ],
          
          // Breaks Section
          if (data.breaks.entries.isNotEmpty) ...[
            const Divider(height: 24, thickness: 1, color: _borderColor),
            _buildSectionTitle('Breaks', Icons.coffee_rounded),
            const SizedBox(height: 8),
            _buildInfoRow('Total Break Time:', data.breaks.totalBreakTime, Icons.coffee_rounded),
            ...data.breaks.entries.map((breakEntry) => 
              _buildInfoRow(
                'Break:', 
                '${breakEntry.breakIn ?? 'Started'} - ${breakEntry.breakOut ?? 'Ongoing'}',
                Icons.pause_circle_rounded
              ),
            ),
          ],
          
          // Task History Section
          if (data.taskHistory.isNotEmpty) ...[
            const Divider(height: 24, thickness: 1, color: _borderColor),
            _buildSectionTitle('Task History', Icons.task_rounded),
            const SizedBox(height: 8),
            ...data.taskHistory.map((task) => 
              _buildListItem(
                '${task.taskName ?? 'Unknown Task'} - ${task.status ?? 'Unknown'} (${task.duration ?? 'N/A'})',
                isTask: true,
              ),
            ),
          ],
          
          // Additional Information
          if (data.reason != null || data.leaveReason != null || data.holidayName != null) ...[
            const Divider(height: 24, thickness: 1, color: _borderColor),
            _buildSectionTitle('Additional Information', Icons.info_rounded),
            const SizedBox(height: 8),
            if (data.reason != null)
              _buildInfoRow('Reason:', data.reason!, Icons.note_rounded),
            if (data.leaveType != null)
              _buildInfoRow('Leave Type:', data.leaveType!, Icons.event_busy_rounded),
            if (data.leaveReason != null)
              _buildInfoRow('Leave Reason:', data.leaveReason!, Icons.event_busy_rounded),
            if (data.holidayName != null)
              _buildInfoRow('Holiday:', data.holidayName!, Icons.celebration_rounded),
          ],
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }



  Widget _buildTimingRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: _textLight, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isWarning ? _errorRed : _textLight.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: _textLight, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value, 
            style: TextStyle(
              fontSize: 13, 
              color: isWarning ? _errorRed : _textDark, 
              fontWeight: FontWeight.w600
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryPurple),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
      ],
    );
  }

  Widget _buildListItem(String item, {bool isLog = false, bool isTask = false}) {
    IconData icon;
    Color iconColor;
    
    if (isTask) {
      icon = Icons.task_alt_rounded;
      iconColor = _accentBlue.withOpacity(0.8);
    } else if (isLog) {
      icon = Icons.timer_outlined;
      iconColor = _textLight.withOpacity(0.7);
    } else {
      icon = Icons.check_circle_outline_rounded;
      iconColor = _accentGreen.withOpacity(0.8);
    }
    
    return Padding(
      padding: EdgeInsets.only(left: isLog ? 0 : 8.0, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(item, style: TextStyle(fontSize: 12, color: _textLight))),
        ],
      ),
    );
  }
}

// lib/features/attendance/attendance.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting if needed for holidays

// Assuming your models and services are correctly pathed
import '../../core/models/holiday_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/network/api_client.dart'; // To make the API call

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late AnimationController _slideController;

  // Premium Design Colors
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

  // REMOVED: Mock holiday data as we will fetch from API
  // final List<Map<String, String>> _holidays = [ ... ];

  // Mock attendance data - replace with real data from your backend
  final Map<DateTime, Map<String, dynamic>> _attendanceData = {
    DateTime(2025, 8, 21): {
      'inTime': '09:15 AM',
      'outTime': '06:00 PM',
      'workingHours': '8h 45m',
      'breakTime': '1h 15m',
      'tiffinTime': '30m',
      'tasks': [
        'Reviewed dashboard UI designs',
        'Fixed payslip PDF generation',
        'Updated authentication system',
        'Code review for mobile app'
      ],
      'logs': [
        'Checked in at 09:15 AM',
        'Started work session',
        'Break started at 11:30 AM',
        'Break ended at 11:45 AM',
        'Tiffin break at 01:00 PM',
        'Tiffin ended at 01:30 PM',
        'Checked out at 06:00 PM'
      ],
      'status': 'present'
    },
    DateTime(2025, 8, 20): {
      'inTime': '09:30 AM',
      'outTime': '05:45 PM',
      'workingHours': '8h 15m',
      'breakTime': '45m',
      'tiffinTime': '25m',
      'tasks': [
        'Team meeting attendance',
        'Project planning session',
        'Database optimization'
      ],
      'logs': [
        'Checked in at 09:30 AM',
        'Team meeting at 10:00 AM',
        'Break at 03:00 PM',
        'Checked out at 05:45 PM'
      ],
      'status': 'present'
    },
    DateTime(2025, 8, 19): {
      'inTime': '--:--',
      'outTime': '--:--',
      'workingHours': '0h 0m',
      'breakTime': '0m',
      'tiffinTime': '0m',
      'tasks': [],
      'logs': ['Leave taken - Personal work'],
      'status': 'leave'
    },
  };

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // Method to show the holiday list modal
  Future<void> _showHolidayModal() async {
    // Show a loading indicator immediately
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss while loading
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();

      if (user == null || secure == null || user.employeeId.isEmpty) {
        if (mounted) Navigator.pop(context); // Dismiss loading
        _showErrorSnackbar('Could not load user details for holidays.');
        return;
      }

      final String currentYear = DateTime.now().year.toString();
      final List<dynamic> holidayData = await ApiClient.fetchCompanyHolidays(
        empId: user.employeeId,
        year: currentYear, // Fetching for the current year
        secure: secure,
      );

      if (mounted) Navigator.pop(context); // Dismiss loading dialog

      final List<Holiday> holidays = holidayData
          .map((data) => Holiday.fromJson(data as Map<String, dynamic>))
          .toList();

      if (holidays.isEmpty) {
        _showInfoSnackbar('No holidays found for the current year.');
        return;
      }

      // Show the actual holiday list dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Company Holidays'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: holidays.length,
                itemBuilder: (BuildContext context, int index) {
                  final holiday = holidays[index];
                  // Assuming holidayDate is in 'YYYY-MM-DD' format, parse and reformat
                  String formattedDate = holiday.holidayDate;
                  try {
                    final date = DateFormat('yyyy-MM-dd').parse(holiday.holidayDate);
                    formattedDate = DateFormat('dd MMM yyyy').format(date); // Example: 25 Dec 2025
                  } catch (e) {
                    // If parsing fails, use the original date string
                    print("Error parsing holiday date: ${holiday.holidayDate}, $e");
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(holiday.holidayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${holiday.holidayType}\n${holiday.holidayDescription}'),
                      trailing: Text(formattedDate, style: const TextStyle(fontSize: 12, color: _textLight)),
                      isThreeLine: holiday.holidayDescription.isNotEmpty,
                    ),
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading if it's still shown
      print('Error fetching holidays: $e');
      _showErrorSnackbar('Failed to fetch holidays. Please try again.');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorRed,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _accentBlue, // Assuming you have an _accentBlue or use Colors.blue
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHolidayButton(),
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

  Widget _buildHolidayButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showHolidayModal, // This now calls the API and shows the modal
          icon: const Icon(Icons.event_available_rounded, size: 20),
          label: const Text(
            'Show Holiday List',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    // ... (rest of your calendar card code - unchanged)
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Fixed Colors.black.withValues
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryPurple.withOpacity(0.1), _primaryDark.withOpacity(0.05)], // Fixed withValues
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
                    color: _accentGreen.withOpacity(0.1), // Fixed withValues
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getPresentDays()}/${DateTime.now().day}',
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

          // Calendar Widget
          Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime(DateTime.now().year, 1, 1),
              lastDay: DateTime.now(), // Consider if you want to allow future dates
              focusedDay: _focusedDay,
              availableGestures: AvailableGestures.none,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) {
                final data = _attendanceData[DateTime(day.year, day.month, day.day)];
                return data != null ? [data] : [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isAfter(DateTime.now())) return;
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _slideController.reset();
                _slideController.forward();
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: _textDark),
                holidayTextStyle: const TextStyle(color: _errorRed),
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryPurple, _primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                todayDecoration: BoxDecoration(
                  color: _accentOrange.withOpacity(0.8), // Fixed withValues
                  borderRadius: BorderRadius.circular(8),
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                defaultDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledTextStyle: TextStyle(
                  color: _textLight.withOpacity(0.5), // Fixed withValues
                ),
                markerDecoration: BoxDecoration(
                  color: _accentGreen,
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
                    color: _primaryPurple.withOpacity(0.1), // Fixed withValues
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
                    color: _primaryPurple.withOpacity(0.1), // Fixed withValues
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
              daysOfWeekStyle: DaysOfWeekStyle( // Assuming DaysOfWeekStyle was intended
                weekdayStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textLight,
                ),
                weekendStyle: const TextStyle( // Added missing weekendStyle for consistency
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textLight, // Or a different color if you prefer for weekends
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format month and year
  String _getMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // Helper method to get present days (example, adjust as per your logic)
  int _getPresentDays() {
    return _attendanceData.values.where((d) => d['status'] == 'present').length;
  }

  // Widget to display day details
  Widget _buildDayDetailsCard() {
    final data = _attendanceData[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)];

    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Fixed withValues
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
                'No attendance data for ${DateFormat('dd MMM yyyy').format(_selectedDay)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textLight),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced vertical margin
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Fixed withValues
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important for SliverFillRemaining
        children: [
          // Header for selected day
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1), // Fixed
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today_rounded, size: 18, color: _primaryPurple),
              ),
              const SizedBox(width: 10),
              Text(
                'Details for ${DateFormat('dd MMM yyyy').format(_selectedDay)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
              ),
              const Spacer(),
              _buildStatusChip(data['status'] ?? 'unknown'),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: _borderColor),

          // Timings
          _buildTimingRow('In Time:', data['inTime'] ?? '--:--', Icons.login_rounded, _accentGreen),
          _buildTimingRow('Out Time:', data['outTime'] ?? '--:--', Icons.logout_rounded, _errorRed),
          const SizedBox(height: 8),
          _buildInfoRow('Working Hours:', data['workingHours'] ?? '0h 0m', Icons.hourglass_bottom_rounded),
          _buildInfoRow('Break Time:', data['breakTime'] ?? '0m', Icons.coffee_rounded),
          _buildInfoRow('Tiffin Time:', data['tiffinTime'] ?? '0m', Icons.restaurant_rounded),


          if ((data['tasks'] as List?)?.isNotEmpty ?? false) ...[
            const Divider(height: 24, thickness: 1, color: _borderColor),
            _buildSectionTitle('Tasks Completed', Icons.checklist_rtl_rounded),
            const SizedBox(height: 8),
            ... (data['tasks'] as List<String>).map((task) => _buildListItem(task)).toList(),
          ],

          if ((data['logs'] as List?)?.isNotEmpty ?? false) ...[
            const Divider(height: 24, thickness: 1, color: _borderColor),
            _buildSectionTitle('Activity Logs', Icons.history_rounded),
            const SizedBox(height: 8),
            ... (data['logs'] as List<String>).map((log) => _buildListItem(log, isLog: true)).toList(),
          ],
          const SizedBox(height: 10), // Add some padding at the bottom if content is short
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor = _textLight;
    String statusText = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'present':
        chipColor = _accentGreen;
        break;
      case 'absent':
        chipColor = _errorRed;
        break;
      case 'leave':
        chipColor = _accentOrange;
        break;
      case 'holiday':
        chipColor = _accentBlue; // Define _accentBlue or use Colors.blue
        break;
    }
    return Chip(
      label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _textLight.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: _textLight, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w600)),
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

  Widget _buildListItem(String item, {bool isLog = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isLog ? 0 : 8.0, top: 4, bottom: 4), // Indent tasks, not logs
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isLog) Icon(Icons.check_circle_outline_rounded, size: 14, color: _accentGreen.withOpacity(0.8)),
          if (isLog) Icon(Icons.timer_outlined, size: 14, color: _textLight.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(child: Text(item, style: TextStyle(fontSize: 12, color: _textLight))),
        ],
      ),
    );
  }
  // Define _accentBlue if not already present, or use a standard color
  static const Color _accentBlue = Color(0xFF3B82F6); // Example blue color

}

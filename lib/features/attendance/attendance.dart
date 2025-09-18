import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  // Holiday data
  final List<Map<String, String>> _holidays = [
    {'date': '26 Jan 2025', 'name': 'Republic Day', 'type': 'National Holiday'},
    {'date': '14 Mar 2025', 'name': 'Holi', 'type': 'Festival'},
    {'date': '15 Aug 2025', 'name': 'Independence Day', 'type': 'National Holiday'},
    {'date': '02 Oct 2025', 'name': 'Gandhi Jayanti', 'type': 'National Holiday'},
    {'date': '12 Nov 2025', 'name': 'Diwali', 'type': 'Festival'},
    {'date': '25 Dec 2025', 'name': 'Christmas', 'type': 'Festival'},
  ];

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

  // ✅ ADDED: Scaffold back
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
          onPressed: _showHolidayModal,
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
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                colors: [_primaryPurple.withValues(alpha: 0.1), _primaryDark.withValues(alpha: 0.05)],
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
                    color: _accentGreen.withValues(alpha: 0.1),
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
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,

              // Disable swipe gestures - Only arrow buttons work
              availableGestures: AvailableGestures.none,

              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
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

              // Month change: Only via arrow buttons
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },

              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: _textDark),
                holidayTextStyle: const TextStyle(color: _errorRed),

                // Selected day style
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

                // Today's style
                todayDecoration: BoxDecoration(
                  color: _accentOrange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),

                // Default day style
                defaultDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),

                // Disabled (future) days
                disabledTextStyle: TextStyle(
                  color: _textLight.withValues(alpha: 0.5),
                ),

                // Marker style for days with data
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

                // Enhanced arrow buttons for month navigation
                leftChevronIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: _primaryPurple,
                    size: 20,
                  ),
                ),
                rightChevronIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
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

              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textLight,
                ),
                weekendStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetailsCard() {
    final dayData = _attendanceData[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ?? {};
    final hasData = dayData.isNotEmpty;

    return hasData ? _buildAttendanceDetails(dayData) : _buildNoDataMessage();
  }

  Widget _buildAttendanceDetails(Map<String, dynamic> dayData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card 1: Date & Time Details
          _buildDateTimeCard(dayData),

          const SizedBox(height: 16),

          // Card 2: Tasks Completed
          if (dayData['tasks'] != null && (dayData['tasks'] as List).isNotEmpty)
            _buildTasksCard(dayData['tasks'] as List),

          const SizedBox(height: 16),

          // Card 3: Activity Logs
          if (dayData['logs'] != null && (dayData['logs'] as List).isNotEmpty)
            _buildActivityLogsCard(dayData['logs'] as List),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard(Map<String, dynamic> dayData) {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final hasData = dayData.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header with Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasData
                      ? (dayData['status'] == 'leave' ? _errorRed : _accentGreen)
                      : _textLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasData
                      ? (dayData['status'] == 'leave' ? Icons.event_busy_rounded : Icons.event_available_rounded)
                      : Icons.event_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatSelectedDate(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    isToday ? 'Today' : _getRelativeDateText(),
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
                  color: hasData
                      ? (dayData['status'] == 'leave'
                      ? _errorRed.withValues(alpha: 0.1)
                      : _accentGreen.withValues(alpha: 0.1))
                      : _textLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasData
                      ? (dayData['status'] == 'leave' ? 'LEAVE' : 'PRESENT')
                      : 'NO DATA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasData
                        ? (dayData['status'] == 'leave' ? _errorRed : _accentGreen)
                        : _textLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // In Time & Out Time Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayData['inTime'] ?? '--:--',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: _borderColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Out Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayData['outTime'] ?? '--:--',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Working Hours (Full Width)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Total Working Hours',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayData['workingHours'] ?? '0h 0m',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(List tasks) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: _accentGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tasks Completed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildActivityLogsCard(List logs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: _primaryPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Activity Logs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${logs.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...logs.map((log) => _buildLogItem(log)),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.event_note_rounded,
                color: _textLight,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No attendance data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No records found for ${_formatSelectedDate()}',
              style: TextStyle(
                fontSize: 14,
                color: _textLight.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _accentGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              task,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _primaryPurple,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              log,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Holiday modal
  void _showHolidayModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentOrange, _accentOrange.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Holiday Calendar 2025',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          'National holidays and festivals',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_holidays.length} Days',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Holiday List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _holidays.length,
                itemBuilder: (context, index) {
                  final holiday = _holidays[index];
                  return _buildHolidayItem(
                    holiday['date']!,
                    holiday['name']!,
                    holiday['type']!,
                    index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayItem(String date, String name, String type, int index) {
    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'National Holiday':
        typeColor = _errorRed;
        typeIcon = Icons.flag_rounded;
        break;
      case 'Festival':
        typeColor = _accentOrange;
        typeIcon = Icons.celebration_rounded;
        break;
      default:
        typeColor = _textLight;
        typeIcon = Icons.event_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            typeIcon,
            color: typeColor,
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Holiday: $name on $date'),
              backgroundColor: typeColor,
            ),
          );
        },
      ),
    );
  }

  String _formatSelectedDate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_selectedDay.day} ${months[_selectedDay.month - 1]} ${_selectedDay.year}';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getRelativeDateText() {
    final now = DateTime.now();
    final difference = now.difference(_selectedDay).inDays;

    if (difference == 1) return 'Yesterday';
    if (difference > 1) return '$difference days ago';
    return 'Selected date';
  }

  int _getPresentDays() {
    return _attendanceData.values.where((data) => data['status'] == 'present').length;
  }
}

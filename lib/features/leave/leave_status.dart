import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leave_service.dart';
import '../../core/services/leave_api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/bottom_menu.dart';
import '../../shared/main_layout.dart';

final leaveDetailsProvider = FutureProvider.family<LeaveRequest, String>((ref, leaveId) async {
  final user = await AuthService.getSavedUser();
  final secure = await AuthService.getSecure();
  if (user == null || secure == null) {
    throw Exception('Session expired. Please login again.');
  }
  final res = await LeaveApiService.getLeaveDetails(
    empId: user.employeeId,
    leaveId: leaveId,
    secure: secure,
  );
  if (res['success'] == true && res['data'] != null) {
    final data = res['data'] as Map<String, dynamic>;
    return LeaveRequest.fromJson(data);
  }
  throw Exception(res['message'] ?? 'Failed to fetch leave details');
});

class LeaveStatusPage extends ConsumerWidget {
  final String requestId;

  const LeaveStatusPage({super.key, required this.requestId});

  // Premium Design Colors
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentGreenLight = Color(0xFF34D399);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentOrangeLight = Color(0xFFFBBF24);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _errorRedLight = Color(0xFFF87171);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(leaveServiceProvider);
    final leaveService = ref.read(leaveServiceProvider.notifier);
    final baseRequest = leaveService.getLeaveRequestById(requestId);
    final details = ref.watch(leaveDetailsProvider(requestId));

    final request = details.when<LeaveRequest?>(
      data: (value) => value,
      loading: () => baseRequest,
      error: (_, __) => baseRequest,
    );

    if (request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Not Found'),
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Leave request not found'),
        ),
        bottomNavigationBar: BottomMenuBar(
          currentIndex: 3,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainLayout(initialIndex: index)),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Leave Request Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (details.isLoading)
              const LinearProgressIndicator(minHeight: 3),
            if (details.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  details.error.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            // Enhanced Status Card
            _buildEnhancedStatusCard(request),

            // Request Overview Card
            _buildRequestOverviewCard(request),

            // Request Details Card
            _buildEnhancedDetailsCard(request),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomMenuBar(
        currentIndex: 3,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainLayout(initialIndex: index)),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedStatusCard(LeaveRequest request) {
    final statusColor = _getStatusColor(request.status);
    final statusLightColor = _getStatusLightColor(request.status);
    final statusIcon = _getStatusIcon(request.status);
    final statusMessage = _getStatusMessage(request.status);

    return Container(
      margin: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Background Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 30),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Status Text
                Text(
                  request.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 8),

                // Status Message
                Text(
                  statusMessage,
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Request Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    request.isMultipleDays
                        ? '${request.totalDays} Days Leave'
                        : 'Single Day Leave',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Status Icon
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusLightColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestOverviewCard(LeaveRequest request) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - CENTERED
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // CENTERED THE ROW
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
                  Icons.calendar_view_day_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Leave Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Date Range Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryPurple.withValues(alpha: 0.08),
                  _primaryDark.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryPurple.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  color: _primaryPurple,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  request.dateRange,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave Period',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailsCard(LeaveRequest request) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: _accentGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Request Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Details Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Employee',
                  request.employeeName,
                  Icons.person_rounded,
                  _primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Duration',
                  '${request.totalDays} ${request.totalDays == 1 ? 'day' : 'days'}',
                  Icons.schedule_rounded,
                  _accentOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Applied On',
                  _formatDate(request.appliedDate),
                  Icons.calendar_today_rounded,
                  _accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Leave Type',
                  request.isMultipleDays ? 'Multiple Days' : 'Single Day',
                  Icons.category_rounded,
                  Colors.indigo,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reason Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.message_rounded,
                        color: Colors.amber.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Reason for Leave',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    request.reason,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Your request is being reviewed by HR';
      case LeaveStatus.approved:
        return 'Your leave request has been approved';
      case LeaveStatus.rejected:
        return 'Your leave request has been declined';
    }
  }

  IconData _getStatusIcon(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Icons.hourglass_top_rounded;
      case LeaveStatus.approved:
        return Icons.check_circle_rounded;
      case LeaveStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return _accentOrange;
      case LeaveStatus.approved:
        return _accentGreen;
      case LeaveStatus.rejected:
        return _errorRed;
    }
  }

  Color _getStatusLightColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return _accentOrangeLight;
      case LeaveStatus.approved:
        return _accentGreenLight;
      case LeaveStatus.rejected:
        return _errorRedLight;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

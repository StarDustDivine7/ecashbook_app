import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/leave_api_service.dart';

enum LeaveStatus { pending, approved, rejected }

extension LeaveStatusExtension on LeaveStatus {
  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  String get colorCode {
    switch (this) {
      case LeaveStatus.pending:
        return '#F59E0B'; // Orange
      case LeaveStatus.approved:
        return '#10B981'; // Green
      case LeaveStatus.rejected:
        return '#EF4444'; // Red
    }
  }
}

class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final bool isMultipleDays;
  final DateTime fromDate;
  final DateTime? toDate;
  final String reason;
  final String? leaveType;
  LeaveStatus status;
  final DateTime appliedDate;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.isMultipleDays,
    required this.fromDate,
    this.toDate,
    required this.reason,
    this.leaveType,
    this.status = LeaveStatus.pending,
    required this.appliedDate,
  });

  // Factory constructor from API JSON
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    // Parse dates
    DateTime parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Parse status
    LeaveStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'approved':
          return LeaveStatus.approved;
        case 'rejected':
          return LeaveStatus.rejected;
        default:
          return LeaveStatus.pending;
      }
    }

    // Support both API key styles
    final fromDate = parseDate((json['from_date'] ?? json['start_date'])?.toString());
    final toDate = parseDate((json['to_date'] ?? json['end_date'])?.toString());
    final totalDaysFromApi = int.tryParse(json['total_days']?.toString() ?? '') ??
        ((toDate.difference(fromDate).inDays).abs() + 1);
    final isMultipleDays = totalDaysFromApi > 1;

    return LeaveRequest(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: json['emp_id']?.toString() ?? '',
      employeeName: json['emp_name']?.toString() ?? 'Unknown',
      isMultipleDays: isMultipleDays,
      fromDate: fromDate,
      toDate: isMultipleDays ? toDate : null,
      reason: json['reason']?.toString() ?? '',
      leaveType: json['leave_type']?.toString(),
      status: parseStatus(json['status']?.toString()),
      appliedDate: parseDate(json['created_at']?.toString()),
    );
  }

  // Calculate total days
  int get totalDays {
    if (isMultipleDays && toDate != null) {
      return toDate!.difference(fromDate).inDays + 1;
    }
    return 1;
  }

  // Get formatted date range
  String get dateRange {
    if (isMultipleDays && toDate != null) {
      return '${_formatDate(fromDate)} - ${_formatDate(toDate!)}';
    }
    return _formatDate(fromDate);
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  LeaveRequest copyWith({
    LeaveStatus? status,
    String? reason,
  }) {
    return LeaveRequest(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      isMultipleDays: isMultipleDays,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason ?? this.reason,
      leaveType: leaveType,
      status: status ?? this.status,
      appliedDate: appliedDate,
    );
  }
}

class LeaveService extends StateNotifier<List<LeaveRequest>> {
  LeaveService() : super([]) {
    print('🏗️ LeaveService constructor called');
    // Don't auto-load here, let the screen control when to load
  }

  bool _isLoading = false;
  String? _error;
  Map<String, int>? _summary; // from API: total, pending, approved, rejected

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int>? get summary => _summary;

  // Load leave list from API
  Future<void> loadLeaveList() async {
    print('🔄 loadLeaveList() called');
    if (_isLoading) {
      print('⏳ loadLeaveList ignored: already loading');
      return;
    }
    _isLoading = true;
    _error = null;
    // Trigger rebuild to show loading state
    state = state;

    try {
      // Get user data
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();

      print('👤 User: ${user?.employeeId}');
      print('🔐 Secure: ${secure?.substring(0, 20)}...');

      if (user == null || secure == null) {
        print('❌ User or secure is null');
        _error = 'Session expired. Please login again.';
        _isLoading = false;
        state = []; // Trigger rebuild
        return;
      }

      print('🚀 Calling LeaveApiService.getLeaveList...');
      
      // Call API
      final result = await LeaveApiService.getLeaveList(
        empId: user.employeeId,
        secure: secure,
      );

      print('📦 API Result: ${result['success']}');
      print('📊 Data: ${result['data']}');

      if (result['success'] == true && result['data'] != null) {
        final dynamic payload = result['data'];
        List<dynamic> leaveData = const [];
        if (payload is List) {
          leaveData = payload;
        } else if (payload is Map<String, dynamic>) {
          // New API shape: { summary: {...}, leaves: [...] }
          leaveData = (payload['leaves'] as List?) ?? const [];
          final s = payload['summary'];
          if (s is Map) {
            _summary = {
              'total': int.tryParse(s['total']?.toString() ?? '') ?? 0,
              'pending': int.tryParse(s['pending']?.toString() ?? '') ?? 0,
              'approved': int.tryParse(s['approved']?.toString() ?? '') ?? 0,
              'rejected': int.tryParse(s['rejected']?.toString() ?? '') ?? 0,
            };
            print('📈 Summary from API: $_summary');
          } else {
            _summary = null;
          }
        }
        print('📝 Number of leaves: ${leaveData.length}');
        
        final List<LeaveRequest> leaves = leaveData
            .map((json) => LeaveRequest.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ Parsed ${leaves.length} leave requests');
        state = leaves;
        print('✅ State updated with ${state.length} items');
      } else {
        print('⚠️ API returned success=false or no data');
        _error = result['message'] ?? 'Failed to load leave list';
        _summary = null;
        state = []; // Trigger rebuild with empty list
      }
    } catch (e, stackTrace) {
      print('❌ Exception in loadLeaveList: $e');
      print('Stack trace: $stackTrace');
      _error = 'Failed to load leave list: ${e.toString()}';
      _summary = null;
      state = []; // Trigger rebuild
    } finally {
      _isLoading = false;
      print('✅ loadLeaveList() completed');
    }
  }


  // Apply for leave
  void applyLeave(LeaveRequest request) {
    state = [...state, request];
  }

  // Get leave request by ID
  LeaveRequest? getLeaveRequestById(String id) {
    try {
      return state.firstWhere((request) => request.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update leave status
  void updateLeaveStatus(String id, LeaveStatus status) {
    final requestIndex = state.indexWhere((request) => request.id == id);
    if (requestIndex != -1) {
      final updatedRequest = state[requestIndex].copyWith(status: status);
      final List<LeaveRequest> updatedList = [...state];
      updatedList[requestIndex] = updatedRequest;
      state = updatedList;
    }
  }

  // Approve leave
  void approveLeave(String id) {
    updateLeaveStatus(id, LeaveStatus.approved);
  }

  // Reject leave
  void rejectLeave(String id) {
    updateLeaveStatus(id, LeaveStatus.rejected);
  }

  // Cancel leave request
  void cancelLeaveRequest(String id) {
    state = state.where((request) => request.id != id).toList();
  }

  // Get statistics
  Map<String, int> getLeaveStatistics() {
    if (_summary != null) {
      return _summary!;
    }
    final pending = state.where((r) => r.status == LeaveStatus.pending).length;
    final approved = state.where((r) => r.status == LeaveStatus.approved).length;
    final rejected = state.where((r) => r.status == LeaveStatus.rejected).length;
    return {
      'total': state.length,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  // Get filtered requests
  List<LeaveRequest> getFilteredRequests(LeaveStatus? status) {
    if (status == null) {
      return state;
    }
    return state.where((request) => request.status == status).toList();
  }
}

// Providers
final leaveServiceProvider =
    StateNotifierProvider<LeaveService, List<LeaveRequest>>((ref) {
  return LeaveService();
});

final leaveStatisticsProvider = Provider<Map<String, int>>((ref) {
  // Watch state so this provider recomputes when list changes
  ref.watch(leaveServiceProvider);
  final leaveService = ref.read(leaveServiceProvider.notifier);
  return leaveService.getLeaveStatistics();
});

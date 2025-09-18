import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.status = LeaveStatus.pending,
    required this.appliedDate,
  });

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      status: status ?? this.status,
      appliedDate: appliedDate,
    );
  }
}

class LeaveService extends StateNotifier<List<LeaveRequest>> {
  LeaveService() : super([]) {
    _loadInitialData();
  }

  // Load sample data
  void _loadInitialData() {
    final sampleRequests = [
      LeaveRequest(
        id: '1',
        employeeId: 'EMP001',
        employeeName: 'John Doe',
        isMultipleDays: false,
        fromDate: DateTime.now().add(const Duration(days: 5)),
        reason: 'Personal work',
        status: LeaveStatus.pending,
        appliedDate: DateTime.now(),
      ),
      LeaveRequest(
        id: '2',
        employeeId: 'EMP001',
        employeeName: 'John Doe',
        isMultipleDays: true,
        fromDate: DateTime.now().add(const Duration(days: 10)),
        toDate: DateTime.now().add(const Duration(days: 12)),
        reason: 'Family vacation',
        status: LeaveStatus.approved,
        appliedDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LeaveRequest(
        id: '3',
        employeeId: 'EMP001',
        employeeName: 'John Doe',
        isMultipleDays: true,
        fromDate: DateTime.now().subtract(const Duration(days: 5)),
        toDate: DateTime.now().subtract(const Duration(days: 3)),
        reason: 'Medical emergency',
        status: LeaveStatus.rejected,
        appliedDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    state = sampleRequests;
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
    final totalRequests = state.length;
    final pendingRequests = state.where((r) => r.status == LeaveStatus.pending).length;
    final approvedRequests = state.where((r) => r.status == LeaveStatus.approved).length;
    final rejectedRequests = state.where((r) => r.status == LeaveStatus.rejected).length;

    return {
      'total': totalRequests,
      'pending': pendingRequests,
      'approved': approvedRequests,
      'rejected': rejectedRequests,
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
final leaveServiceProvider = StateNotifierProvider<LeaveService, List<LeaveRequest>>((ref) {
  return LeaveService();
});

final leaveStatisticsProvider = Provider<Map<String, int>>((ref) {
  final leaveService = ref.read(leaveServiceProvider.notifier);
  return leaveService.getLeaveStatistics();
});

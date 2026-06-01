import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/expenditure_api_service.dart';

enum ClaimStatus { pending, approved, rejected }

extension ClaimStatusX on ClaimStatus {
  String get displayName {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }
}

class ClaimItem {
  final String id;
  final String employeeId;
  final DateTime date;
  final String category;
  final double amount;
  final String paymentMethod;
  final String details;
  final ClaimStatus status;

  ClaimItem({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.details,
    required this.status,
  });

  factory ClaimItem.fromJson(Map<String, dynamic> j) {
    ClaimStatus parseStatus(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'approved':
          return ClaimStatus.approved;
        case 'rejected':
          return ClaimStatus.rejected;
        default:
          return ClaimStatus.pending;
      }
    }

    DateTime parseDate(dynamic s) {
      try {
        return DateTime.parse(s.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    double parseAmount(dynamic s) => double.tryParse(s?.toString() ?? '') ?? 0.0;

    return ClaimItem(
      id: j['id']?.toString() ?? '',
      employeeId: (j['employee_id'] ?? j['emp_id'] ?? '').toString(),
      date: parseDate(j['date'] ?? j['claim_date'] ?? j['created_at']),
      category: (j['category'] ?? '').toString(),
      amount: parseAmount(j['claim_amount'] ?? j['amount']),
      paymentMethod: (j['payment_method'] ?? '').toString(),
      details: (j['details'] ?? j['description'] ?? '').toString(),
      status: parseStatus(j['status']?.toString()),
    );
  }
}

class ExpenditureService extends StateNotifier<List<ClaimItem>> {
  ExpenditureService() : super([]);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClaims() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    // Force a rebuild to reflect loading state in listeners that also read notifier flags
    state = [...state];

    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();
      if (user == null || secure == null) {
        _error = 'Session expired. Please login again.';
        state = [];
        return;
      }
      final res = await ExpenditureApiService.getClaimList(
        employeeId: user.employeeId,
        secure: secure,
      );
      if (res['success'] == true) {
        final payload = res['data'];
        List items = const [];
        if (payload is List) {
          items = payload;
        } else if (payload is Map<String, dynamic>) {
          // Try common keys
          items = (payload['claims'] as List?) ??
                  (payload['list'] as List?) ??
                  (payload['data'] as List?) ??
                  const [];
        }
        final list = items
            .map((e) => ClaimItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = list;
      } else {
        _error = res['message']?.toString();
        state = [];
      }
    } catch (e) {
      _error = e.toString();
      state = [];
    } finally {
      _isLoading = false;
      // Ensure any listeners depending on isLoading update
      state = [...state];
    }
  }

  ClaimItem? getById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

final expenditureServiceProvider =
    StateNotifierProvider<ExpenditureService, List<ClaimItem>>((ref) {
  return ExpenditureService();
});

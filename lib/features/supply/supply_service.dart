import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/supply_api_service.dart';

enum SupplyStatus { pending, approved, rejected }

extension SupplyStatusX on SupplyStatus {
  String get displayName {
    switch (this) {
      case SupplyStatus.pending:
        return 'Pending';
      case SupplyStatus.approved:
        return 'Approved';
      case SupplyStatus.rejected:
        return 'Rejected';
    }
  }
}

class SupplyItem {
  final String id;
  final String employeeId;
  final DateTime date;
  final String category;
  final String details;
  final String quantity;
  final double amount;
  final String priority;
  final String returnExchange;
  final SupplyStatus status;

  SupplyItem({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.category,
    required this.details,
    required this.quantity,
    required this.amount,
    required this.priority,
    required this.returnExchange,
    required this.status,
  });

  factory SupplyItem.fromJson(Map<String, dynamic> j) {
    SupplyStatus parseStatus(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'approved':
          return SupplyStatus.approved;
        case 'rejected':
          return SupplyStatus.rejected;
        default:
          return SupplyStatus.pending;
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

    return SupplyItem(
      id: j['id']?.toString() ?? '',
      employeeId: (j['employee_id'] ?? j['emp_id'] ?? '').toString(),
      date: parseDate(j['date'] ?? j['claim_date'] ?? j['created_at']),
      category: (j['category'] ?? '').toString(),
      details: (j['details'] ?? j['description'] ?? '').toString(),
      quantity: (j['quantity'] ?? '0').toString(),
      amount: parseAmount(j['amount']),
      priority: (j['priority'] ?? '').toString(),
      returnExchange: (j['return_exchange'] ?? '').toString(),
      status: parseStatus(j['status']?.toString()),
    );
  }
}

class SupplyService extends StateNotifier<List<SupplyItem>> {
  SupplyService() : super([]);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSupply() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    state = [...state];

    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();
      if (user == null || secure == null) {
        _error = 'Session expired. Please login again.';
        state = [];
        return;
      }
      final res = await SupplyApiService.getSupplyList(
        employeeId: user.employeeId,
        secure: secure,
      );
      if (res['success'] == true) {
        final payload = res['data'];
        List items = const [];
        if (payload is List) {
          items = payload;
        } else if (payload is Map<String, dynamic>) {
          items = (payload['supplies'] as List?) ?? (payload['list'] as List?) ?? (payload['data'] as List?) ?? const [];
        }
        final list = items.map((e) => SupplyItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
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
      state = [...state];
    }
  }

  SupplyItem? getById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

final supplyServiceProvider = StateNotifierProvider<SupplyService, List<SupplyItem>>((ref) {
  return SupplyService();
});

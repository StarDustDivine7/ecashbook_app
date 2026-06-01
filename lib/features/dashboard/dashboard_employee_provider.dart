// lib/features/dashboard/dashboard_employee_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/employee_details.dart';
import '../../core/services/auth_service.dart';

class DashboardEmployeeState {
  final bool loading;
  final String? error;
  final EmployeeDetailsData? details;

  const DashboardEmployeeState({
    this.loading = false,
    this.error,
    this.details,
  });

  DashboardEmployeeState copyWith({
    bool? loading,
    String? error,
    EmployeeDetailsData? details,
  }) {
    return DashboardEmployeeState(
      loading: loading ?? this.loading,
      error: error,
      details: details ?? this.details,
    );
  }
}

class DashboardEmployeeNotifier extends StateNotifier<DashboardEmployeeState> {
  DashboardEmployeeNotifier() : super(const DashboardEmployeeState());

  Future<void> load([String? overrideDate]) async {
    try {
      state = state.copyWith(loading: true, error: null);
      final prefs = await SharedPreferences.getInstance();
      final secure = await AuthService.getSecure() ?? '';
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final todayDate =
          overrideDate ?? DateTime.now().toIso8601String().substring(0, 10);

      final resp = await AuthService.fetchEmployeeDetails(
        empId: empId,
        todayDate: todayDate,
        secure: secure,
      );
      if (!resp.success) {
        // Preserve the actual server message so auth errors can be detected upstream
        state = state.copyWith(loading: false, error: resp.message);
        return;
      }
      await prefs.setString('last_employee_details_date', resp.data.date);
      state = state.copyWith(loading: false, details: resp.data, error: null);
    } on Exception catch (e) {
      final msg = e.toString();
      debugPrint('Employee details load error: $msg');
      // Preserve the original message so auth errors (401, token) are detectable
      state = state.copyWith(loading: false, error: msg);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final dashboardEmployeeProvider =
    StateNotifierProvider<DashboardEmployeeNotifier, DashboardEmployeeState>(
        (ref) {
  return DashboardEmployeeNotifier();
});

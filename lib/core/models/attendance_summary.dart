import 'package:flutter/material.dart';

class AttendanceSummary {
  final Totals totals;
  final List<DayAttendance> timeline;
  final AttendanceContext context;

  AttendanceSummary({
    required this.totals,
    required this.timeline,
    required this.context,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totals: Totals.fromJson(json['data']['totals']),
      timeline: (json['data']['timeline'] as List)
          .map((e) => DayAttendance.fromJson(e))
          .toList(),
      context: AttendanceContext.fromJson(json['context']),
    );
  }
}

class DayAttendance {
  final String date;
  final String status;
  final String badgeClass;
  final String checkIn;
  final String checkOut;
  final String notes;

  DayAttendance({
    required this.date,
    required this.status,
    required this.badgeClass,
    required this.checkIn,
    required this.checkOut,
    required this.notes,
  });

  factory DayAttendance.fromJson(Map<String, dynamic> json) {
    return DayAttendance(
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      badgeClass: json['badge_class'] ?? '',
      checkIn: json['check_in'] ?? '-',
      checkOut: json['check_out'] ?? '-',
      notes: json['notes'] ?? '',
    );
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF10B981); // _accentGreen
      case 'absent':
        return const Color(0xFFEF4444); // _errorRed
      case 'leave':
        return const Color(0xFFF59E0B); // _accentOrange
      case 'holiday':
        return const Color(0xFF3B82F6); // _accentBlue
      default:
        return const Color(0xFF64748B); // _textLight
    }
  }
}

class Totals {
  final int totalPresent;
  final int totalAbsent;
  final int totalLeave;
  final int totalHoliday;
  final int totalOfficeOff;

  Totals({
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLeave,
    required this.totalHoliday,
    required this.totalOfficeOff,
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      totalPresent: json['totalPresent'] ?? 0,
      totalAbsent: json['totalAbsent'] ?? 0,
      totalLeave: json['totalLeave'] ?? 0,
      totalHoliday: json['totalHoliday'] ?? 0,
      totalOfficeOff: json['totalOfficeOff'] ?? 0,
    );
  }
}

class AttendanceContext {
  final EmployeeInfo employee;
  final String from;
  final String to;

  AttendanceContext({
    required this.employee,
    required this.from,
    required this.to,
  });

  factory AttendanceContext.fromJson(Map<String, dynamic> json) {
    return AttendanceContext(
      employee: EmployeeInfo.fromJson(json['employee']),
      from: json['from'],
      to: json['to'],
    );
  }
}

class EmployeeInfo {
  final String name;
  final String employeeId;

  EmployeeInfo({
    required this.name,
    required this.employeeId,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      name: json['name'] ?? '',
      employeeId: json['employee_id'] ?? '',
    );
  }
}
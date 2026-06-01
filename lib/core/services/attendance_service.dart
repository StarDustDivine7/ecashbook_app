import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../models/attendance_summary.dart';
import '../models/daily_activity_model.dart';
import 'auth_service.dart';

class AttendanceService {
  static Future<AttendanceSummary?> fetchAttendanceSummary({
    required String empId,
    required DateTime fromDate,
    required DateTime toDate,
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await ApiClient.dio.post(
        ApiConfig.attendanceSummary,
        data: {
          'empId': empId,
          'from_date': DateFormat('yyyy-MM-dd').format(fromDate),
          'to_date': DateFormat('yyyy-MM-dd').format(toDate),
          'secure': secure,
        },
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        return AttendanceSummary.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to fetch attendance summary: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchMonthlyAttendance({
    required String empId,
    required DateTime month,
    required String secure,
  }) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    final summary = await fetchAttendanceSummary(
      empId: empId,
      fromDate: firstDay,
      toDate: lastDay,
      secure: secure,
    );
    
    if (summary == null) {
      throw Exception('Failed to fetch monthly attendance');
    }
    
    // Convert timeline to maps for easier use in UI
    Map<DateTime, String> statusMap = {};
    Map<DateTime, Map<String, dynamic>> dataMap = {};
    
    for (var dayAttendance in summary.timeline) {
      DateTime date = DateFormat('dd-MM-yyyy').parse(dayAttendance.date);
      String status = dayAttendance.status.toLowerCase();
      
      statusMap[date] = status;
      dataMap[date] = {
        'status': status,
        'inTime': dayAttendance.checkIn != '-' ? dayAttendance.checkIn : null,
        'outTime': dayAttendance.checkOut != '-' ? dayAttendance.checkOut : null,
        'notes': dayAttendance.notes != '-' ? dayAttendance.notes : null,
        'badgeClass': dayAttendance.badgeClass,
        'workingHours': _calculateWorkingHours(dayAttendance.checkIn, dayAttendance.checkOut),
        'breakTime': '0m', // Default values since not in API
        'tiffinTime': '0m',
        'tasks': <String>[], // Empty for now
        'logs': <String>[], // Empty for now
      };
    }
    
    return {
      'statusMap': statusMap,
      'dataMap': dataMap,
      'summary': {
        'totalPresent': summary.totals.totalPresent,
        'totalAbsent': summary.totals.totalAbsent,
        'totalLeave': summary.totals.totalLeave,
        'totalHoliday': summary.totals.totalHoliday,
        'totalOfficeOff': summary.totals.totalOfficeOff,
      },
    };
  }
  
  static Future<DailyActivityResponse?> fetchDailyActivity({
    required String empId,
    required DateTime date,
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final response = await ApiClient.dio.post(
        ApiConfig.attendanceDailyActivity,
        data: {
          'empId': empId,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'secure': secure,
        },
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        return DailyActivityResponse.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to fetch daily activity: $e');
    }
  }

  static String _calculateWorkingHours(String checkIn, String checkOut) {
    if (checkIn == '-' || checkOut == '-') return '0h 0m';
    
    try {
      // Parse time strings (assuming format like "10:00 AM")
      final inTime = DateFormat('h:mm a').parse(checkIn);
      final outTime = DateFormat('h:mm a').parse(checkOut);
      
      final duration = outTime.difference(inTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      return '${hours}h ${minutes}m';
    } catch (e) {
      return '0h 0m';
    }
  }
}
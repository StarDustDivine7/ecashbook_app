// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class UnauthorizedInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check for 401 status code
    if (response.statusCode == 401) {
      _handleUnauthorized(response.data);
      handler.next(response);
      return;
    }

    // Check for unauthorized in response data
    if (response.data is Map) {
      final data = response.data as Map;
      if (_isUnauthorizedResponse(data, response.statusCode)) {
        _handleUnauthorized(data);
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _handleUnauthorized(err.response?.data);
    }
    handler.next(err);
  }

  // Local implementation to avoid static method call issues
  bool _isUnauthorizedResponse(dynamic responseData, int? statusCode) {
    if (statusCode == 401) return true;
    
    if (responseData is Map) {
      final success = responseData['success'];
      final errorCode = responseData['error_code']?.toString();
      final message = responseData['message']?.toString() ?? '';
      
      return success == false && 
             (errorCode == 'TOKEN_MISMATCH' || 
              message.toLowerCase().contains('unauthorized') ||
              (message.toLowerCase().contains('invalid') && message.toLowerCase().contains('token')) ||
              (message.toLowerCase().contains('expired') && message.toLowerCase().contains('token')));
    }
    
    return false;
  }

  void _handleUnauthorized(dynamic responseData) {
    // Handle unauthorized response asynchronously
    AuthService.clearAllAppData().then((_) {
      // Note: Navigation should be handled by the calling widget/provider
      // since we can't access BuildContext from here
    });
  }
}

class ApiClient {
  static final dio = Dio()
    ..interceptors.addAll([
      LogInterceptor(responseBody: true),
      UnauthorizedInterceptor(),
    ]);

  static Future<Response> getEmployeeDetails({
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.employeeDetails, data: {
      "empId": empId,
      "secure": secure,
    });
  }

  static Future<Response> punchIn({
    required String todayDate,
    required String punchInTime,
    required String empId,
    required String secure,
    required double punchInLat,
    required double punchInLong,
    required String workLocationStatus,
  }) {
    return dio.post(ApiConfig.punchIn, data: {
      "todayDate": todayDate,
      "punchInTime": punchInTime,
      "empId": empId,
      "secure": secure,
      "punchInLat": punchInLat,
      "punchInLong": punchInLong,
      "workLocationStatus": workLocationStatus,
    });
  }

  static Future<Response> punchOut({
    required String todayDate,
    required String punchOutTime,
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.punchOut, data: {
      "todayDate": todayDate,
      "punchOutTime": punchOutTime,
      "empId": empId,
      "secure": secure,
    });
  }

  static Future<Response> breakIn({
    required String breakDate,
    required String breakIn,
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.breakIn, data: {
      "break_date": breakDate,
      "break_in": breakIn,
      "empId": empId,
      "secure": secure,
    });
  }

  static Future<Response> breakOut({
    required String breakDate,
    required String breakOutTime,
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.breakOut, data: {
      "break_date": breakDate,
      "breakOutTime": breakOutTime,
      "empId": empId,
      "secure": secure,
    });
  }

  static Future<Response> lunchIn({
    required String todayDate,
    required String lunchInTime,
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.lunchIn, data: {
      "todayDate": todayDate,
      "lunchInTime": lunchInTime,
      "empId": empId,
      "secure": secure,
    });
  }

  static Future<Response> lunchOut({
    required String todayDate,
    required String lunchOutTime,
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.lunchOut, data: {
      "todayDate": todayDate,
      "lunchOutTime": lunchOutTime,
      "empId": empId,
      "secure": secure,
    });
  }

  // ✅ ADDED: New API calls for tasks
  static Future<Response> fetchTaskList({
    required String empId,
    required String toDayDate,
    required String currentTime,
    required String secure,
  }) {
    return dio.post(ApiConfig.taskList, data: {
      "empId": empId,
      "toDayDate": toDayDate,
      "currentTime": currentTime,
      "secure": secure,
    });
  }

  static Future<Response> fetchTaskDetails({
    required String empId,
    required String taskId,
    required String toDayDate,
    required String currentTime,
    required String secure,
  }) {
    return dio.post(ApiConfig.taskDetails, data: {
      "empId": empId,
      "taskId": taskId,
      "toDayDate": toDayDate,
      "currentTime": currentTime,
      "secure": secure,
    });
  }

  static Future<List<dynamic>> fetchCompanyHolidays({
    required String empId,
    required String year,
    required String secure,
  }) async {
    final headers = await AuthService.getAuthHeaders();

    final response = await dio.post(
      ApiConfig.companyHolidays,
      data: jsonEncode({
        'empId': empId,
        'year': year,
        'secure': secure,
      }),
      options: Options(
        headers: headers,
        validateStatus: (status) => true, // Allow any status code
      ),
    );

    if (response.statusCode == 401) {
      throw Exception('401 Unauthorized - Token/session expired or invalid.');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch holidays: ${response.statusCode}');
    }

    final data = response.data;
    if (data is! Map) throw Exception('Invalid response format');

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to fetch holidays');
    }

    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> attendanceSummaryApi({
    required String empId, required String fromDate, required String toDate, required String secure
  }) async {
    final resp = await dio.post(
      ApiConfig.attendanceSummary,
      data: {
        'empId': empId,
        'from_date': fromDate,
        'to_date': toDate,
        'secure': secure,
      },
    );
    return resp.data;
  }

}
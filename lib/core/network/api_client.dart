// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

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
    final response = await dio.post(
      ApiConfig.companyHolidays,
      data: {
        "empId": empId,
        "year": year,
        "secure": secure,
      },
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data'] as List;
    }
    return [];
  }


}
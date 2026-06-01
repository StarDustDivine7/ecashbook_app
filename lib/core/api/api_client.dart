// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
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

  static Future<Response> punchIn({
    required String todayDate,
    required String punchInTime,
    required String empId,
    required String secure,
  }) {
    return dio.post(ApiConfig.punchIn, data: {
      "todayDate": todayDate,
      "punchInTime": punchInTime,
      "empId": empId,
      "secure": secure,
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

  static Future<Response> getEmployeeDetails({
    required String empId,
    required String secure,
  }) {
    return dio.get(ApiConfig.employeeDetails, queryParameters: {
      "empId": empId,
      "secure": secure,
    });
  }

  static Future<Response> getTaskList({
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

  static Future<Response> getTaskDetails({
    required String empId,
    required String secure,
    required String taskId,
  }) {
    return dio.post(ApiConfig.taskDetails, data: {
      "empId": empId,
      "secure": secure,
      "taskId": taskId,
    });
  }

  static Future<Response> updateTaskStatus({
    required String empId,
    required String secure,
    required String taskId,
    required String status,
  }) {
    return dio.post(ApiConfig.taskStatusUpdate, data: {
      "empId": empId,
      "secure": secure,
      "taskId": taskId,
      "status": status,
    });
  }

  static Future<List<dynamic>> fetchCompanyHolidays({
    required String empId,
    required String year,
    required String secure,
  }) async {
    try {
      // Validate input parameters
      if (empId.isEmpty || year.isEmpty || secure.isEmpty) {
        throw Exception('Invalid parameters provided');
      }

      final headers = await AuthService.getAuthHeaders();
      if (headers == null) {
        throw Exception('Failed to get authentication headers');
      }

      final response = await dio.post<Map<String, dynamic>>(
        ApiConfig.companyHolidays,
        data: <String, dynamic>{
          "empId": empId,
          "year": year,
          "secure": secure,
        },
        options: Options(
          headers: headers,
          validateStatus: (int? code) => code != null && code < 500,
        ),
      );

      final responseData = response.data;
      if (response.statusCode == 200 && 
          responseData != null && 
          responseData['success'] == true) {
        final data = responseData['data'];
        if (data is List) {
          return data;
        }
        throw Exception('Invalid data format received from server');
      }
      
      final errorMessage = responseData?['message']?.toString() ?? 
          'Server returned status code: ${response.statusCode}';
      throw Exception(errorMessage);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception("401 Unauthorized - Token/session expired or invalid.");
      }
      throw Exception("API exception: ${e.message ?? 'Unknown network error'}");
    } catch (e) {
      throw Exception('Failed to fetch company holidays: ${e.toString()}');
    }
  }
}

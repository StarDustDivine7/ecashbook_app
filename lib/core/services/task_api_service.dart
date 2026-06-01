import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/task_models.dart';
import 'auth_service.dart';

class TaskApiService {
  final Dio _dio;

  TaskApiService(this._dio);

  Future<TaskListResponse> fetchTaskList() async {
    try {
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';

      if (empId.isEmpty || secure.isEmpty) {
        throw Exception('Missing employee credentials');
      }

      final now = DateTime.now();
      final todayDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Get authentication headers
      final headers = await AuthService.getAuthHeaders();
      
      final response = await _dio.post(
        ApiConfig.taskList,
        data: jsonEncode({
          "empId": empId,
          "toDayDate": todayDate,
          "currentTime": currentTime,
          "secure": secure,
        }),
        options: Options(headers: headers),
      );

      final Map<String, dynamic> map = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : Map<String, dynamic>.from(json.decode(response.data as String) as Map);

      return TaskListResponse.fromJson(map);
    } catch (e) {
      throw Exception('Failed to fetch task list: ${e.toString()}');
    }
  }

  Future<TaskListResponse> fetchCompletedTasks() async {
    try {
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';

      if (empId.isEmpty || secure.isEmpty) {
        throw Exception('Missing employee credentials');
      }

      final now = DateTime.now();
      final todayDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Get authentication headers
      final headers = await AuthService.getAuthHeaders();
      
      final response = await _dio.post(
        ApiConfig.completedTaskList,
        data: jsonEncode({
          "empId": empId,
          "toDayDate": todayDate,
          "currentTime": currentTime,
          "secure": secure,
        }),
        options: Options(headers: headers),
      );

      final Map<String, dynamic> map = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : Map<String, dynamic>.from(json.decode(response.data as String) as Map);

      return TaskListResponse.fromJson(map);
    } catch (e) {
      throw Exception('Failed to fetch completed tasks: ${e.toString()}');
    }
  }

  Future<TaskDetailsResponse> fetchTaskDetails(String taskId) async {
    try {
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';

      if (empId.isEmpty || secure.isEmpty) {
        throw Exception('Missing employee credentials');
      }

      final now = DateTime.now();
      final todayDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Get authentication headers
      final headers = await AuthService.getAuthHeaders();
      
      final response = await _dio.post(
        ApiConfig.taskDetails,
        data: jsonEncode({
          "empId": empId,
          "taskId": taskId,
          "toDayDate": todayDate,
          "currentTime": currentTime,
          "secure": secure,
        }),
        options: Options(headers: headers),
      );

      final Map<String, dynamic> map = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : Map<String, dynamic>.from(json.decode(response.data as String) as Map);

      return TaskDetailsResponse.fromJson(map);
    } catch (e) {
      throw Exception('Failed to fetch task details: ${e.toString()}');
    }
  }

  Future<bool> updateTaskStatus({
    required String taskId,
    required String status,
    String? completedDate,
  }) async {
    try {
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (empId.isEmpty || secure.isEmpty) {
        throw Exception('Missing employee credentials');
      }

      final headers = await AuthService.getAuthHeaders();
      final body = <String, dynamic>{
        "empId": empId,
        "taskId": taskId,
        "status": status,
        "secure": secure,
      };
      if (completedDate != null && completedDate.isNotEmpty) {
        body['completedDate'] = completedDate;
      }

      final resp = await _dio.post(
        ApiConfig.taskStatusUpdate,
        data: jsonEncode(body),
        options: Options(headers: headers),
      );

      final Map<String, dynamic> map = resp.data is Map
          ? Map<String, dynamic>.from(resp.data as Map)
          : Map<String, dynamic>.from(json.decode(resp.data as String) as Map);

      return (map['success'] == true);
    } catch (e) {
      rethrow;
    }
  }
}
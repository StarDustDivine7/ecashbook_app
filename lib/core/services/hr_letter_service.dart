import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

class HrLetterService {
  static Future<Map<String, dynamic>> getLetterList({
    required String employeeId,
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final body = {
        'employee_id': employeeId,
        'secure': secure,
      };

      final response = await ApiClient.dio.post(
        ApiConfig.hrLetterList,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final success = (map['status']?.toString().toLowerCase() == 'success') || (map['success'] == true);
        return {
          'success': success,
          'message': map['message']?.toString() ?? (success ? 'OK' : 'Failed'),
          'data': map['data'] is List ? List<Map<String, dynamic>>.from(map['data'] as List) : <Map<String, dynamic>>[],
        };
      }

      return {
        'success': false,
        'message': 'Unexpected response',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map && (e.response!.data['message'] != null)
            ? e.response!.data['message'].toString()
            : e.message ?? 'Network error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getLetterListForCurrentUser() async {
    final user = await AuthService.getSavedUser();
    final secure = await AuthService.getSecure();
    if (user == null || secure == null) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }
    return getLetterList(employeeId: user.employeeId, secure: secure);
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

class PerformanceReviewService {
  /// POST https://testapp.ecashbook.in/api/users/review/employee_review_list
  static Future<Map<String, dynamic>> fetchReviews({
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
        ApiConfig.performanceReviewList,
        data: body,
        options: Options(headers: headers),
      );

      if (response.data is Map<String, dynamic>) {
        final out = Map<String, dynamic>.from(response.data as Map);
        out['status_code'] = response.statusCode;
        return out;
      }

      if (response.data is String) {
        final out = Map<String, dynamic>.from(json.decode(response.data as String) as Map);
        out['status_code'] = response.statusCode;
        return out;
      }

      return {
        'status': 'error',
        'message': 'Unexpected response',
        'status_code': response.statusCode,
      };
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data is Map
            ? (e.response?.data['message'] ?? 'Network error')
            : e.message ?? 'Network error',
        'status_code': e.response?.statusCode,
        'data': e.response?.data,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'status_code': null,
      };
    }
  }
}

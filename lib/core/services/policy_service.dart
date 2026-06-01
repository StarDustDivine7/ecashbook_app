import 'package:dio/dio.dart';
import 'package:ecashbook_app/core/config/api_config.dart' show ApiConfig;
import '../network/api_client.dart';
import 'auth_service.dart';

class PolicyService {
  // static const String _updateReadStatusUrl =
  //     'https://test.ecashbook.in/api/users/policies/update-policy-read-status';

  static Future<Map<String, dynamic>> getPolicyList({
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
        ApiConfig.policyList,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final success =
            (map['status']?.toString().toLowerCase() == 'success') ||
                (map['success'] == true);
        return {
          'success': success,
          'message': map['message']?.toString() ?? (success ? 'OK' : 'Failed'),
          'employee_info': map['employee_info'] is Map
              ? Map<String, dynamic>.from(map['employee_info'])
              : <String, dynamic>{},
          'data': map['data'] is List
              ? List<Map<String, dynamic>>.from(map['data'] as List)
              : <Map<String, dynamic>>[],
        };
      }

      return {
        'success': false,
        'message': 'Unexpected response',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data is Map && (e.response!.data['message'] != null)
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

  static Future<Map<String, dynamic>> getPolicyListForCurrentUser() async {
    final user = await AuthService.getSavedUser();
    final secure = await AuthService.getSecure();
    if (user == null || secure == null) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }
    return getPolicyList(employeeId: user.employeeId, secure: secure);
  }

  static Future<Map<String, dynamic>> updatePolicyReadStatus({
    required String employeeId,
    required String secure,
    required String type, // 'terms_and_conditions' or 'privacy_policy'
    required bool status,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final body = {
        'employee_id': employeeId,
        'secure': secure,
        'type': type,
        'status': status,
      };

      final response = await ApiClient.dio.post(
        ApiConfig.updatePolicyReadStatus,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final success =
            (map['status']?.toString().toLowerCase() == 'success') ||
                (map['success'] == true);
        return {
          'success': success,
          'message': map['message']?.toString() ?? (success ? 'OK' : 'Failed'),
        };
      }

      return {
        'success': false,
        'message': 'Unexpected response',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data is Map && (e.response!.data['message'] != null)
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
}

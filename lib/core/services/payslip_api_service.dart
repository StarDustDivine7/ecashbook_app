import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

class PayslipApiService {
  /// POST https://testapp.ecashbook.in/api/users/payslips/payslip-details
  static Future<Map<String, dynamic>> fetchPayslipDetails({
    required String empId,
    required String financialYear,
    required String month, // 2-digit string: 01-12
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final body = {
        'employee_id': empId,
        'financial_year': financialYear,
        'month': int.parse(month),
        'secure': secure,
      };
      print(body);
      final response = await ApiClient.dio.post(
        ApiConfig.payslipDetails,
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

      return {'success': false, 'message': 'Unexpected response type', 'status_code': response.statusCode};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? (e.response?.data['message'] ?? 'Network error')
            : e.message ?? 'Network error',
        'status_code': e.response?.statusCode,
        'data': e.response?.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'status_code': null,
      };
    }
  }
}

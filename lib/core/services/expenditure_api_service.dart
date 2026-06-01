import 'dart:io';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

class ExpenditureApiService {
  static Future<Map<String, dynamic>> getClaimList({
    required String employeeId,
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final body = {
        'employee_id': employeeId,
        'secure': secure,
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.claimList,
        data: body,
        options: Options(headers: headers),
      );
      final data = resp.data;
      bool success = false;
      String? message;
      dynamic payload;
      if (data is Map) {
        final statusStr = data['status']?.toString().toLowerCase();
        success = data['success'] == true || statusStr == 'success';
        message = data['message']?.toString();
        payload = data['data'];
      }
      return {
        'success': success,
        'message': message ?? (success ? 'OK' : 'Failed'),
        'data': payload,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? (e.response?.data['message'] ?? 'Network error')
            : 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getClaimDetails({
    required String employeeId,
    required String claimId,
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final body = {
        'employee_id': employeeId,
        'claim_id': claimId,
        'secure': secure,
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.claimDetails,
        data: body,
        options: Options(headers: headers),
      );
      final data = resp.data;
      bool success = false;
      String? message;
      dynamic payload;
      if (data is Map) {
        final statusStr = data['status']?.toString().toLowerCase();
        success = data['success'] == true || statusStr == 'success';
        message = data['message']?.toString();
        payload = data['data'];
      }
      return {
        'success': success,
        'message': message ?? (success ? 'OK' : 'Failed'),
        'data': payload,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? (e.response?.data['message'] ?? 'Network error')
            : 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitClaim({
    required String employeeId,
    required String date,
    required String secure,
    required String category,
    required String claimAmount,
    required String details,
    required String paymentMethod,
    File? receipt,
    String? comments,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final form = FormData.fromMap({
        'employee_id': employeeId,
        'date': date,
        'secure': secure,
        'category': category,
        'claim_amount': claimAmount,
        'details': details,
        'payment_method': paymentMethod,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
        if (receipt != null)
          'receipt': await MultipartFile.fromFile(
            receipt.path,
            filename: receipt.path.split('/').last,
          ),
      });
      final resp = await ApiClient.dio.post(
        ApiConfig.submitClaim,
        data: form,
        options: Options(
          headers: {
            ...headers,
            // Override content type for multipart
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      final data = resp.data;
      bool success = false;
      String? message;
      dynamic payload;
      if (data is Map) {
        final statusStr = data['status']?.toString().toLowerCase();
        success = data['success'] == true || statusStr == 'success';
        message = data['message']?.toString();
        payload = data['data'];
      }
      return {
        'success': success,
        'message': message ?? (success ? 'OK' : 'Failed'),
        'data': payload,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? (e.response?.data['message'] ?? 'Network error')
            : 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

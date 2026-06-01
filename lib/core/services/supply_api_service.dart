import 'dart:io';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

class SupplyApiService {
  static Future<Map<String, dynamic>> getSupplyList({
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
        ApiConfig.supplyList,
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
        'message': e.response?.data is Map ? (e.response?.data['message'] ?? 'Network error') : 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSupplyDetails({
    required String employeeId,
    required String requisitionId,
    required String secure,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final body = {
        'employee_id': employeeId,
        'requisition_id': requisitionId,
        'secure': secure,
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.supplyDetails,
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
        'message': e.response?.data is Map ? (e.response?.data['message'] ?? 'Network error') : 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitSupply({
    required String employeeId,
    required String date,
    required String category,
    required String details,
    required String quantity,
    required String amount,
    required String priority,
    required String returnExchange,
    required String secure,
    File? attachment,
    String? comments,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final form = FormData.fromMap({
        'employee_id': employeeId,
        'date': date,
        'category': category,
        'details': details,
        'quantity': quantity,
        'amount': amount,
        'priority': priority,
        'return_exchange': returnExchange,
        'secure': secure,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
        if (attachment != null)
          'attachment': await MultipartFile.fromFile(
            attachment.path,
            filename: attachment.path.split('/').last,
          ),
      });
      final resp = await ApiClient.dio.post(
        ApiConfig.submitSupply,
        data: form,
        options: Options(headers: {
          ...headers,
          'Content-Type': 'multipart/form-data',
        }),
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
        'message': e.response?.data is Map ? (e.response?.data['message'] ?? 'Network error') : 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

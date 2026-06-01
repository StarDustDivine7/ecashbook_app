import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';
import 'auth_service.dart';

class LeaveApiService {
  /// Get list of leaves
  /// POST https://testapp.ecashbook.in/api/users/employee/list-of-leave
  static Future<Map<String, dynamic>> getLeaveList({
    required String empId,
    required String secure,
  }) async {
    try {
      print('\n🌐 ========== LEAVE LIST API ==========');
      print('📍 Endpoint: ${ApiConfig.listOfLeave}');
      
      final headers = await AuthService.getAuthHeaders();
      print('📋 Headers: $headers');
      
      final requestBody = {
        'empId': empId,
        'secure': secure,
      };
      
      print('📤 Request Body:');
      print('   {');
      print('     "empId": "$empId"');
      print('     "secure": "${secure.substring(0, 20)}..."');
      print('   }');
      
      print('⏳ Sending request...');
      
      final response = await ApiClient.dio.post(
        ApiConfig.listOfLeave,
        data: requestBody,
        options: Options(headers: headers),
      );

      print('✅ Response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${response.data}');

      if (response.data['success'] == true) {
        print('✅ Leave list fetched successfully!');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Leave list fetched successfully',
          'data': response.data['data'],
        };
      } else {
        print('⚠️ Failed to fetch leave list (success=false)');
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to fetch leave list',
        };
      }
    } catch (e) {
      print('❌ Error occurred:');
      if (e is DioException) {
        print('   Type: DioException');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Message: ${e.message}');
        
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Network error occurred',
        };
      }
      print('   Type: ${e.runtimeType}');
      print('   Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch leave list: $e',
      };
    } finally {
      print('========================================\n');
    }
  }

  /// Apply for leave
  /// POST https://testapp.ecashbook.in/api/users/employee/apply-leave
  static Future<Map<String, dynamic>> applyLeave({
    required String empId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String leaveType,
    required String secure,
  }) async {
    try {
      print('\n🌐 ========== LEAVE API SERVICE ==========');
      print('📍 Endpoint: ${ApiConfig.applyLeave}');
      
      final headers = await AuthService.getAuthHeaders();
      print('📋 Headers: $headers');
      
      final requestBody = {
        'empId': empId,
        'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
        'toDate': DateFormat('yyyy-MM-dd').format(toDate),
        'reason': reason,
        'leaveType': leaveType,
        'secure': secure,
      };
      
      print('📤 Request Body:');
      print('   {');
      requestBody.forEach((key, value) {
        if (key == 'secure') {
          print('     "$key": "${value.toString().substring(0, 20)}..."');
        } else {
          print('     "$key": "$value"');
        }
      });
      print('   }');
      
      print('⏳ Sending request...');
      
      final response = await ApiClient.dio.post(
        ApiConfig.applyLeave,
        data: requestBody,
        options: Options(headers: headers),
      );

      print('✅ Response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${response.data}');

      if (response.data['success'] == true) {
        print('✅ Leave application successful!');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Leave request submitted successfully',
          'data': response.data['data'],
        };
      } else {
        print('⚠️ Leave application failed (success=false)');
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to submit leave request',
        };
      }
    } catch (e) {
      print('❌ Error occurred:');
      if (e is DioException) {
        print('   Type: DioException');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Message: ${e.message}');
        
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        // Handle 422 Validation Error
        if (statusCode == 422 && responseData is Map) {
          final errorCode = responseData['error_code']?.toString();
          final message = responseData['message']?.toString();
          
          // Provide user-friendly message for overlapping leave
          if (errorCode == 'LEAVE_OVERLAP') {
            return {
              'success': false,
              'message': 'You have already applied for leave on the selected dates. Please choose different dates or cancel your previous leave request.',
              'error_code': errorCode,
            };
          }
          
          // Return the API message for other validation errors
          return {
            'success': false,
            'message': message ?? 'Validation error occurred',
            'error_code': errorCode,
          };
        }
        
        // Handle other errors
        return {
          'success': false,
          'message': responseData?['message'] ?? 'Network error occurred',
        };
      }
      print('   Type: ${e.runtimeType}');
      print('   Error: $e');
      return {
        'success': false,
        'message': 'Failed to submit leave request: $e',
      };
    } finally {
      print('========================================\n');
    }
  }

  /// Get leave details
  /// POST https://testapp.ecashbook.in/api/users/employee/leave-details
  static Future<Map<String, dynamic>> getLeaveDetails({
    required String empId,
    required String leaveId,
    required String secure,
  }) async {
    try {
      print('\n🌐 ========== LEAVE DETAILS API ==========');
      print('📍 Endpoint: ${ApiConfig.leaveDetails}');

      final headers = await AuthService.getAuthHeaders();
      print('📋 Headers: $headers');

      final requestBody = {
        'empId': empId,
        'leaveId': leaveId,
        'secure': secure,
      };

      print('📤 Request Body:');
      print('   {');
      print('     "empId": "$empId"');
      print('     "leaveId": "$leaveId"');
      print('     "secure": "${secure.substring(0, 20)}..."');
      print('   }');

      print('⏳ Sending request...');

      final response = await ApiClient.dio.post(
        ApiConfig.leaveDetails,
        data: requestBody,
        options: Options(headers: headers),
      );

      print('✅ Response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${response.data}');

      if (response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Leave details fetched successfully',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to fetch leave details',
        };
      }
    } catch (e) {
      print('❌ Error occurred:');
      if (e is DioException) {
        print('   Type: DioException');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Message: ${e.message}');
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Network error occurred',
        };
      }
      print('   Type: ${e.runtimeType}');
      print('   Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch leave details: $e',
      };
    } finally {
      print('========================================\n');
    }
  }
}

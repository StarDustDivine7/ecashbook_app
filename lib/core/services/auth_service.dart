import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../models/login_response.dart';
import '../models/employee_details.dart';

// Results

class PunchInResult {
  final bool success;
  final String message;
  final String? errorCode;

  PunchInResult({required this.success, required this.message, this.errorCode});

  factory PunchInResult.fromJson(Map json) => PunchInResult(
        success: json['success'] == true,
        message: (json['message'] ?? '').toString(),
        errorCode: json['error_code']?.toString(),
      );
}

class LunchInResult {
  final bool success;
  final String message;

  LunchInResult({required this.success, required this.message});

  factory LunchInResult.fromJson(Map json) => LunchInResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString());
}

class LunchOutResult {
  final bool success;
  final String message;

  LunchOutResult({required this.success, required this.message});

  factory LunchOutResult.fromJson(Map json) => LunchOutResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString());
}

class BreakResult {
  final bool success;
  final String message;

  BreakResult({required this.success, required this.message});

  factory BreakResult.fromJson(Map json) => BreakResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString());
}

class PunchOutResult {
  final bool success;
  final String message;
  final Map? data;

  PunchOutResult({required this.success, required this.message, this.data});

  factory PunchOutResult.fromJson(Map json) => PunchOutResult(
        success: json['success'] == true,
        message: (json['message'] ?? '').toString(),
        data: (json['data'] is Map) ? Map.from(json['data'] as Map) : null,
      );
}

class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final String? tokenType;
  final String? secure;
  final User? user;

  AuthResult(
      {required this.success,
      this.message,
      this.token,
      this.tokenType,
      this.secure,
      this.user});
}

class LogoutResult {
  final bool success;
  final String message;
  final String? errorCode;
  final bool isUnauthorized;

  LogoutResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.isUnauthorized = false,
  });

  factory LogoutResult.fromJson(Map json) => LogoutResult(
        success: json['success'] == true,
        message: (json['message'] ?? '').toString(),
        errorCode: json['error_code']?.toString(),
      );

  factory LogoutResult.unauthorized() => LogoutResult(
        success: false,
        message: 'Unauthorized access. Invalid or expired token.',
        errorCode: 'TOKEN_MISMATCH',
        isUnauthorized: true,
      );
}

class AuthService {
  // Keys
  static const String _kToken = 'auth_token';
  static const String _kTokenType = 'token_type';
  static const String _kSecure = 'secure_hash';
  static const String _kUser = 'user_data';
  static const String _kLastAuth = 'last_auth_time';
  static const String _kDeviceToken = 'device_token';

  // Storage
  static Future<void> _saveAuthToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
  }

  static Future<void> _saveTokenType(String type) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTokenType, type);
  }

  static Future<void> _saveSecure(String secure) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSecure, secure);
  }

  static Future<void> _saveUserData(User user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  static Future<String?> getAuthToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  static Future<String?> getTokenType() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kTokenType);
  }

  static Future<String?> getSecure() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kSecure);
  }

  static Future<User?> getSavedUser() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kUser);
    if (raw == null) return null;
    try {
      return User.fromJson(Map.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAuthSession() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastAuth, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearAuthSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLastAuth);
    await p.remove(_kToken);
    await p.remove(_kTokenType);
    await p.remove(_kSecure);
    await p.remove(_kUser);
  }

  static Future<void> clearAllAppData() async {
    final p = await SharedPreferences.getInstance();
    // Clear auth data
    await p.remove(_kLastAuth);
    await p.remove(_kToken);
    await p.remove(_kTokenType);
    await p.remove(_kSecure);
    await p.remove(_kUser);
    await p.remove(_kDeviceToken);

    // Clear app state
    await p.remove('user_logged_in');
    await p.remove('app_was_backgrounded');
    await p.remove('app_paused_time');
    await p.remove('pin_attempt_count');
    await p.remove('last_app_close_time');

    // Keep these for app functionality
    // - is_first_time (for onboarding)
    // - onboarding_completed
    // - permissions_granted
    // - lock_setup_completed
    // - has_ever_logged_in
    // - app_passcode_hash (PIN)
  }

  static Future<bool> isSessionActive(
      {Duration timeout = const Duration(minutes: 120)}) async {
    final p = await SharedPreferences.getInstance();
    final ts = p.getInt(_kLastAuth) ?? 0;
    return DateTime.now().millisecondsSinceEpoch - ts < timeout.inMilliseconds;
  }

  // Optionally store a device token if fetched elsewhere
  static Future<void> saveDeviceToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDeviceToken, token);
  }

  static Future<String?> getDeviceToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kDeviceToken);
  }

  // Location
  static Future<Position?> getCurrentLocation() async {
    try {
      if (!await Permission.location.request().isGranted) return null;
      final LocationSettings settings = Platform.isAndroid
          ? AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
          : AppleSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } catch (_) {
      return null;
    }
  }

  static String formatLocation(Position p) =>
      'Lat: ${p.latitude.toStringAsFixed(6)}, Lng: ${p.longitude.toStringAsFixed(6)}';

  // HTTP helpers
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAuthToken();
    final type = await getTokenType() ?? 'Bearer';
    final Map<String, String> h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (token != null && token.isNotEmpty) h['Authorization'] = '$type $token';
    return h;
  }

  // Public method to get auth headers
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _authHeaders();
  }

  static String _handleNetworkError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Network timeout';
    }
    final status = e.response?.statusCode ?? 0;
    if (status == 401) return 'Unauthorized';
    try {
      final data = e.response?.data;
      if (data is Map && data['message'] != null)
        return data['message'].toString();
    } catch (_) {}
    return 'Network error';
  }

  // Check if response indicates unauthorized access
  static bool isUnauthorizedResponse(dynamic responseData, int? statusCode) {
    if (statusCode == 401) return true;

    if (responseData is Map) {
      final success = responseData['success'];
      final errorCode = responseData['error_code']?.toString();
      final message = responseData['message']?.toString() ?? '';

      return success == false &&
          (errorCode == 'TOKEN_MISMATCH' ||
              message.toLowerCase().contains('unauthorized') ||
              message.toLowerCase().contains('invalid') &&
                  message.toLowerCase().contains('token') ||
              message.toLowerCase().contains('expired') &&
                  message.toLowerCase().contains('token'));
    }

    return false;
  }

  // Handle unauthorized response by clearing data and returning appropriate result
  static Future<void> handleUnauthorizedResponse() async {
    // debugPrint('🔒 Handling unauthorized response - clearing app data');
    await clearAllAppData();
  }

  // Auth
  static Future<AuthResult> loginWithAPI(String email, String password) async {
    try {
      // Resolve device token; if not saved, use a placeholder to match API contract
      final savedDeviceToken = await getDeviceToken();
      final deviceToken = (savedDeviceToken == null || savedDeviceToken.isEmpty)
          ? 'Fetch_Device_phone_token'
          : savedDeviceToken;

      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      final body = {
        'email': email,
        'password': password,
        'device_token': deviceToken,
        'device_type': deviceType,
      };

      final resp = await ApiClient.dio.post(
        ApiConfig.login,
        data: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);

        final login = LoginResponse.fromJson(map);
        if (!login.success) {
          return AuthResult(success: false, message: login.message);
        }

        await _saveAuthToken(login.data.token);
        await _saveTokenType(login.data.tokenType);
        await _saveSecure(login.data.secure);
        await _saveUserData(login.data.user);
        await saveAuthSession();

        return AuthResult(
          success: true,
          token: login.data.token,
          tokenType: login.data.tokenType,
          secure: login.data.secure,
          user: login.data.user,
        );
      }

      return AuthResult(success: false, message: 'Login failed');
    } on DioException catch (e) {
      return AuthResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return AuthResult(success: false, message: 'Login failed');
    }
  }

  // Logout API
  static Future<LogoutResult> logoutWithAPI() async {
    try {
      final headers = await _authHeaders();
      final user = await getSavedUser();
      final secure = await getSecure();

      if (user == null || secure == null) {
        // No user data, treat as successful logout
        await clearAllAppData();
        return LogoutResult(success: true, message: 'Logged out successfully');
      }

      final body = {
        'empId': user.employeeId,
        'secure': secure,
      };

      final resp = await ApiClient.dio.post(
        ApiConfig.logout,
        data: jsonEncode(body),
        options: Options(
          headers: headers,
          validateStatus: (status) =>
              status != null && status < 500, // Accept all non-server errors
        ),
      );

      // Handle 401 Unauthorized specifically
      if (resp.statusCode == 401) {
        await clearAllAppData();
        return LogoutResult.unauthorized();
      }

      final Map<String, dynamic> map = resp.data is Map
          ? Map<String, dynamic>.from(resp.data as Map)
          : Map<String, dynamic>.from(json.decode(resp.data as String) as Map);

      final result = LogoutResult.fromJson(map);

      // Clear app data regardless of API response for logout
      await clearAllAppData();

      return result;
    } on DioException catch (e) {
      // Handle network errors
      if (e.response?.statusCode == 401) {
        await clearAllAppData();
        return LogoutResult.unauthorized();
      }

      // For other errors, still clear data and return error
      await clearAllAppData();
      return LogoutResult(
        success: false,
        message: _handleNetworkError(e),
      );
    } catch (e) {
      // For any other errors, clear data and return generic error
      await clearAllAppData();
      return LogoutResult(
        success: false,
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  // Employee details
  static Future<EmployeeDetailsResponse> fetchEmployeeDetails({
    required String empId,
    required String todayDate,
    required String secure,
  }) async {
    final headers = await _authHeaders();
    final body = {'empId': empId, 'today_date': todayDate, 'secure': secure};
    final resp = await ApiClient.dio.post(
      ApiConfig.employeeDetails,
      data: jsonEncode(body),
      options: Options(headers: headers, validateStatus: (s) => true),
    );
    if (resp.statusCode == 401) {
      throw Exception('401 Unauthorized - Token/session expired or invalid.');
    }
    final Map<String, dynamic> map = resp.data is Map
        ? Map<String, dynamic>.from(resp.data as Map)
        : Map<String, dynamic>.from(json.decode(resp.data as String) as Map);
    return EmployeeDetailsResponse.fromJson(map);
  }

  // Punch In
  static Future<PunchInResult> punchIn({
    required String todayDate,
    required String punchInTime,
    required String empId,
    required String secure,
    required double punchInLat,
    required double punchInLong,
    required String workLocationStatus,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'todayDate': todayDate,
        'punchInTime': punchInTime,
        'empId': empId,
        'secure': secure,
        'punchInLat': punchInLat,
        'punchInLong': punchInLong,
        'work_location_status': workLocationStatus,
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.punchIn,
        data: jsonEncode(body),
        options: Options(headers: headers, validateStatus: (c) => true),
      );
      if (resp.statusCode == 409) {
        final Map<String, dynamic> m = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return PunchInResult(
          success: false,
          message: (m['message'] ?? 'Already punched in for today.').toString(),
          errorCode: (m['error_code'] ?? 'ALREADY_PUNCHED_IN').toString(),
        );
      }
      try {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return PunchInResult.fromJson(map);
      } on FormatException {
        return PunchInResult(
          success: false,
          message: 'Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      return PunchInResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return PunchInResult(success: false, message: 'Punch in failed');
    }
  }

  // Lunch In
  static Future<LunchInResult> lunchIn({
    required String todayDate,
    required String lunchInTime,
    required String empId,
    required String secure,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'todayDate': todayDate,
        'lunchInTime': lunchInTime,
        'empId': empId,
        'secure': secure
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.lunchIn,
        data: jsonEncode(body),
        options: Options(headers: headers, validateStatus: (c) => true),
      );
      try {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return LunchInResult.fromJson(map);
      } on FormatException {
        return LunchInResult(
          success: false,
          message: 'Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      return LunchInResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return LunchInResult(success: false, message: 'Lunch in failed');
    }
  }

  // Lunch Out
  static Future<LunchOutResult> lunchOut({
    required String todayDate,
    required String lunchOutTime,
    required String empId,
    required String secure,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'todayDate': todayDate,
        'lunchOutTime': lunchOutTime,
        'empId': empId,
        'secure': secure
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.lunchOut,
        data: jsonEncode(body),
        options: Options(headers: headers, validateStatus: (c) => true),
      );
      try {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return LunchOutResult.fromJson(map);
      } on FormatException {
        return LunchOutResult(
          success: false,
          message: 'Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      return LunchOutResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return LunchOutResult(success: false, message: 'Lunch out failed');
    }
  }

  // Break In
  static Future<BreakResult> breakIn({
    required String breakDate,
    required String breakInTime,
    required String empId,
    required String secure,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'break_date': breakDate,
        'break_in': breakInTime,
        'empId': empId,
        'secure': secure
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.breakIn,
        data: jsonEncode(body),
        options: Options(headers: headers, validateStatus: (c) => true),
      );
      try {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return BreakResult.fromJson(map);
      } on FormatException {
        return BreakResult(
          success: false,
          message: 'Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      return BreakResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return BreakResult(success: false, message: 'Break start failed');
    }
  }

  // Break Out
  static Future<BreakResult> breakOut({
    required String breakDate,
    required String breakOutTime,
    required String empId,
    required String secure,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'break_date': breakDate,
        'breakOutTime': breakOutTime,
        'empId': empId,
        'secure': secure
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.breakOut,
        data: jsonEncode(body),
        options: Options(headers: headers, validateStatus: (c) => true),
      );
      try {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return BreakResult.fromJson(map);
      } on FormatException {
        return BreakResult(
          success: false,
          message: 'Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      return BreakResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return BreakResult(success: false, message: 'Break end failed');
    }
  }

  // Punch Out
  static Future<PunchOutResult> punchOut({
    required String todayDate,
    required String punchOutTime,
    required String empId,
    required String secure,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'todayDate': todayDate,
        'punchOutTime': punchOutTime,
        'empId': empId,
        'secure': secure,
      };
      final resp = await ApiClient.dio.post(
        ApiConfig.punchOut,
        data: jsonEncode(body),
        options: Options(headers: headers, validateStatus: (c) => true),
      );
      print(resp.data);
      try {
        final Map<String, dynamic> map = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : Map<String, dynamic>.from(
                json.decode(resp.data as String) as Map);
        return PunchOutResult.fromJson(map);
      } on FormatException {
        return PunchOutResult(
          success: false,
          message: 'Invalid response from server.',
          data: null,
        );
      }
    } on DioException catch (e) {
      return PunchOutResult(success: false, message: _handleNetworkError(e));
    } catch (_) {
      return PunchOutResult(success: false, message: 'Punch out failed');
    }
  }
}

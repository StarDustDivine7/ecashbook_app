// File: lib/core/constants.dart

import 'package:flutter/material.dart';

// App Colors
class AppColors {
  static const primary    = Color(0xFF422F90); // Your brand purple
  static const accent     = Color(0xFFFFC107); // Optional accent (e.g., icons, warnings)
  static const background = Colors.white; // Pure white background
  static const surface    = Colors.white; // Cards, modals

  static const error      = Color(0xFFE53E3E); // For error highlight
  static const success    = Color(0xFF38A169); // For success highlight
  static const info       = Color(0xFF3182CE); // For info highlight

  static const border     = Color(0xFFE5E7EB); // subtle gray border
  static const text       = Color(0xFF222222); // black text
  static const textGray   = Color(0xFF444444); // slightly softer black
  static const subtitle   = Color(0xFF757575); // gray for subtext
  static const icon       = primary;           // consistent icon color
}

// API Configuration
class ApiConstants {
  // Base URLs (Change according to your backend)
  static const String baseUrl = 'https://your-api-domain.com/api';
  static const String authUrl = '$baseUrl/auth';
  static const String employeeUrl = '$baseUrl/employee';

  // Auth Endpoints
  static const String loginEndpoint = '$authUrl/login';
  static const String logoutEndpoint = '$authUrl/logout';
  static const String refreshTokenEndpoint = '$authUrl/refresh';
  static const String forgotPasswordEndpoint = '$authUrl/forgot-password';

  // Employee Endpoints
  static const String profileEndpoint = '$employeeUrl/profile';
  static const String attendanceEndpoint = '$employeeUrl/attendance';
  static const String checkInEndpoint = '$employeeUrl/attendance/check-in';
  static const String checkOutEndpoint = '$employeeUrl/attendance/check-out';

  // Leave Management
  static const String leaveEndpoint = '$employeeUrl/leave';
  static const String applyLeaveEndpoint = '$employeeUrl/leave/apply';
  static const String leaveHistoryEndpoint = '$employeeUrl/leave/history';

  // Payroll
  static const String payslipEndpoint = '$employeeUrl/payslip';
  static const String salaryEndpoint = '$employeeUrl/salary';

  // Tasks
  static const String tasksEndpoint = '$employeeUrl/tasks';
  static const String taskUpdateEndpoint = '$employeeUrl/tasks/update';

  // HR Letters
  static const String hrLettersEndpoint = '$employeeUrl/hr-letters';

  // File Upload
  static const String fileUploadEndpoint = '$baseUrl/upload';

  // Request timeout
  static const int requestTimeout = 30; // seconds
  static const int connectTimeout = 15; // seconds
}

// App Constants
class AppConstants {
  // App Info
  static const String appName = 'EcashBook';
  static const String appVersion = '1.0.0';
  static const String companyName = '360 Business & Services';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';

  static const String locationPermissionKey = 'location_permission';
  static const String lastCheckInKey = 'last_check_in';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Location Settings
  static const double locationAccuracyThreshold = 100.0; // meters
  static const int locationTimeoutSeconds = 30;

  // PIN Settings
  static const String pinReason = 'Please enter your PIN to access EcashBook';
  static const int maxPinAttempts = 5;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double iconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

// Employee Roles
enum EmployeeRole {
  admin('Admin'),
  manager('Manager'),
  employee('Employee'),
  intern('Intern');

  const EmployeeRole(this.displayName);
  final String displayName;
}

// Leave Types
enum LeaveType {
  casual('Casual Leave'),
  sick('Sick Leave'),
  annual('Annual Leave'),
  maternity('Maternity Leave'),
  paternity('Paternity Leave'),
  emergency('Emergency Leave');

  const LeaveType(this.displayName);
  final String displayName;
}

// Leave Status
enum LeaveStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  const LeaveStatus(this.displayName);
  final String displayName;

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return AppColors.accent;
      case LeaveStatus.approved:
        return AppColors.success;
      case LeaveStatus.rejected:
        return AppColors.error;
      case LeaveStatus.cancelled:
        return AppColors.subtitle;
    }
  }
}

// Task Status
enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  completed('Completed'),
  overdue('Overdue');

  const TaskStatus(this.displayName);
  final String displayName;

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return AppColors.subtitle;
      case TaskStatus.inProgress:
        return AppColors.info;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.overdue:
        return AppColors.error;
    }
  }
}

// Task Priority
enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  const TaskPriority(this.displayName);
  final String displayName;

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.accent;
      case TaskPriority.high:
        return AppColors.info;
      case TaskPriority.urgent:
        return AppColors.error;
    }
  }
}

// Attendance Status
enum AttendanceStatus {
  present('Present'),
  absent('Absent'),
  late('Late'),
  halfDay('Half Day'),
  leave('On Leave');

  const AttendanceStatus(this.displayName);
  final String displayName;

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.accent;
      case AttendanceStatus.halfDay:
        return AppColors.info;
      case AttendanceStatus.leave:
        return AppColors.subtitle;
    }
  }
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server error. Please try again later';
  static const String unauthorized = 'Session expired. Please login again';
  static const String invalidCredentials = 'Invalid email or password';
  static const String locationPermissionDenied = 'Location permission is required for attendance';
  static const String pinNotSet = 'PIN not set. Please set up your PIN';
  static const String pinFailed = 'Incorrect PIN. Please try again';
  static const String fileUploadFailed = 'Failed to upload file';
  static const String invalidFileFormat = 'Invalid file format';
  static const String fileTooLarge = 'File size exceeds limit';
  static const String cameraPermissionDenied = 'Camera permission is required';
  static const String storagePermissionDenied = 'Storage permission is required';
}

// Success Messages
class SuccessMessages {
  static const String loginSuccess = 'Welcome back!';
  static const String logoutSuccess = 'Logged out successfully';
  static const String attendanceMarked = 'Attendance marked successfully';
  static const String leaveApplied = 'Leave application submitted';
  static const String taskUpdated = 'Task updated successfully';
  static const String profileUpdated = 'Profile updated successfully';
  static const String passwordReset = 'Password reset link sent to your email';
  static const String fileUploaded = 'File uploaded successfully';
}

// Info Messages
class InfoMessages {
  static const String locationDetecting = 'Detecting your location...';
  static const String pinPrompt = 'Please enter your 4-digit PIN';
  static const String dataLoading = 'Loading data...';
  static const String syncingData = 'Syncing with server...';
  static const String noInternetConnection = 'Working in offline mode';
  static const String noDataAvailable = 'No data available';
  static const String selectFile = 'Please select a file';
  static const String takePhoto = 'Take a photo or choose from gallery';
}

// Asset Paths
class Assets {
  // Images
  static const String whiteLogo = 'assets/images/white-logo.png';
  static const String timeTracking = 'assets/images/time-tracking.png';
  static const String hrSuite = 'assets/images/hr-suite.png';
  static const String avatarDummy = 'assets/images/avatar-dummy.jpg';

  // Icons
  static const String appIcon = 'assets/icon/icon.png';
  static const String icon512 = 'assets/icon/icon_512.png';
  static const String iconForeground = 'assets/icon/icon_foreground.png';
  static const String iconBackground = 'assets/icon/icon_background.png';
}

// Date Formats
class DateFormats {
  static const String displayDate = 'MMM dd, yyyy';
  static const String displayDateTime = 'MMM dd, yyyy hh:mm a';
  static const String apiDate = 'yyyy-MM-dd';
  static const String apiDateTime = 'yyyy-MM-dd HH:mm:ss';
  static const String timeOnly = 'hh:mm a';
  static const String dayMonth = 'dd MMM';
}

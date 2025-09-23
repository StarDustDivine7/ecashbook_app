// lib/core/models/employee_details.dart
class EmployeeDetailsResponse {
  final bool success;
  final String message;
  final EmployeeDetailsData data;

  EmployeeDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory EmployeeDetailsResponse.fromJson(Map json) {
    return EmployeeDetailsResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: EmployeeDetailsData.fromJson(json['data'] as Map),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data.toJson(),
  };
}

class EmployeeDetailsData {
  final String date;
  final String name;
  final String status;
  final String employeeId;
  final String email;
  final String gender;
  final String? profileImg;
  final String departmentName;
  final String designationName;
  final String todayWorkLocation;
  final String todayWorkingStatus; // NEW (from API)
  final String attendanceStatus; // present | not_present | punch_out
  final String lunchStatus; // pending | ongoing | complete
  final String breakStatus; // not_break | ongoing
  final OfficeLocation? officeLocation;

  EmployeeDetailsData({
    required this.date,
    required this.name,
    required this.status,
    required this.employeeId,
    required this.email,
    required this.gender,
    required this.profileImg,
    required this.departmentName,
    required this.designationName,
    required this.todayWorkLocation,
    required this.todayWorkingStatus,
    required this.attendanceStatus,
    required this.lunchStatus,
    required this.breakStatus,
    required this.officeLocation,
  });

  factory EmployeeDetailsData.fromJson(Map json) {
    return EmployeeDetailsData(
      date: json['date']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      profileImg: json['profile_img']?.toString(),
      departmentName: json['department_name']?.toString() ?? '',
      designationName: json['designation_name']?.toString() ?? '',
      todayWorkLocation: json['today_work_location']?.toString() ?? '',
      todayWorkingStatus: json['todayWorkingStatus']?.toString() ?? '',
      attendanceStatus: json['attendance_status']?.toString() ?? '',
      lunchStatus: json['lunch_status']?.toString() ?? '',
      breakStatus: json['break_status']?.toString() ?? '',
      officeLocation: json['office_location'] == null
          ? null
          : OfficeLocation.fromJson(json['office_location'] as Map),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'name': name,
    'status': status,
    'employee_id': employeeId,
    'email': email,
    'gender': gender,
    'profile_img': profileImg,
    'department_name': departmentName,
    'designation_name': designationName,
    'today_work_location': todayWorkLocation,
    'todayWorkingStatus': todayWorkingStatus,
    'attendance_status': attendanceStatus,
    'lunch_status': lunchStatus,
    'break_status': breakStatus,
    'office_location': officeLocation?.toJson(),
  };
}

class OfficeLocation {
  final int id;
  final String locationName;
  final String locationType;
  final String latitude;
  final String longitude;
  final int radius;
  final String radiusUnit;

  OfficeLocation({
    required this.id,
    required this.locationName,
    required this.locationType,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.radiusUnit,
  });

  factory OfficeLocation.fromJson(Map json) {
    return OfficeLocation(
      id: (json['id'] ?? 0) as int,
      locationName: json['location_name']?.toString() ?? '',
      locationType: json['location_type']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      radius: (json['radius'] ?? 0) as int,
      radiusUnit: json['radius_unit']?.toString() ?? 'meters',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'location_name': locationName,
    'location_type': locationType,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'radius_unit': radiusUnit,
  };
}

class DailyActivityResponse {
  final bool success;
  final String message;
  final DailyActivityData data;

  DailyActivityResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DailyActivityResponse.fromJson(Map<String, dynamic> json) {
    return DailyActivityResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: DailyActivityData.fromJson(json['data'] ?? {}),
    );
  }
}

class DailyActivityData {
  final String date;
  final String dayName;
  final String status;
  final String statusColor;
  final String statusIcon;
  final String? inTime;
  final String? outTime;
  final String? workingHours;
  final bool isLate;
  final String? lateBy;
  final String? reason;
  final String? leaveType;
  final String? leaveReason;
  final String? holidayName;
  final String openingTime;
  final String closingTime;
  final String? lunchIn;
  final String? lunchOut;
  final String lunchStatus;
  final String? totalLunchTime;
  final String workLocationStatus;
  final BreakData breaks;
  final List<TaskHistory> taskHistory;

  DailyActivityData({
    required this.date,
    required this.dayName,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    this.inTime,
    this.outTime,
    this.workingHours,
    required this.isLate,
    this.lateBy,
    this.reason,
    this.leaveType,
    this.leaveReason,
    this.holidayName,
    required this.openingTime,
    required this.closingTime,
    this.lunchIn,
    this.lunchOut,
    required this.lunchStatus,
    this.totalLunchTime,
    required this.workLocationStatus,
    required this.breaks,
    required this.taskHistory,
  });

  factory DailyActivityData.fromJson(Map<String, dynamic> json) {
    return DailyActivityData(
      date: json['date'] ?? '',
      dayName: json['dayName'] ?? '',
      status: json['status'] ?? '',
      statusColor: json['statusColor'] ?? '',
      statusIcon: json['statusIcon'] ?? '',
      inTime: json['inTime'],
      outTime: json['outTime'],
      workingHours: json['workingHours'],
      isLate: json['isLate'] ?? false,
      lateBy: json['lateBy'],
      reason: json['reason'],
      leaveType: json['leaveType'],
      leaveReason: json['leaveReason'],
      holidayName: json['holidayName'],
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      lunchIn: json['lunch_in'],
      lunchOut: json['lunch_out'],
      lunchStatus: json['lunch_status'] ?? '',
      totalLunchTime: json['total_lunch_time'],
      workLocationStatus: json['work_location_status'] ?? '',
      breaks: BreakData.fromJson(json['breaks'] ?? {}),
      taskHistory: (json['task_history'] as List? ?? [])
          .map((e) => TaskHistory.fromJson(e))
          .toList(),
    );
  }
}

class BreakData {
  final List<BreakEntry> entries;
  final String totalBreakTime;

  BreakData({
    required this.entries,
    required this.totalBreakTime,
  });

  factory BreakData.fromJson(Map<String, dynamic> json) {
    return BreakData(
      entries: (json['entries'] as List? ?? [])
          .map((e) => BreakEntry.fromJson(e))
          .toList(),
      totalBreakTime: json['total_break_time'] ?? '00:00',
    );
  }
}

class BreakEntry {
  final String? breakIn;
  final String? breakOut;
  final String? duration;

  BreakEntry({
    this.breakIn,
    this.breakOut,
    this.duration,
  });

  factory BreakEntry.fromJson(Map<String, dynamic> json) {
    return BreakEntry(
      breakIn: json['break_in'],
      breakOut: json['break_out'],
      duration: json['duration'],
    );
  }
}

class TaskHistory {
  final String? taskId;
  final String? taskName;
  final String? status;
  final String? startTime;
  final String? endTime;
  final String? duration;

  TaskHistory({
    this.taskId,
    this.taskName,
    this.status,
    this.startTime,
    this.endTime,
    this.duration,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    return TaskHistory(
      taskId: json['task_id'],
      taskName: json['task_name'],
      status: json['status'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      duration: json['duration'],
    );
  }
}
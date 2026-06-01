import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enhanced Dashboard Business Logic
class DashboardAuthService {
  static const String _punchDataKey = 'punch_data';
  static const String _lastResetKey = 'last_reset_date';

  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> checkAndPerformReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReset = prefs.getString(_lastResetKey);
      final today = _getTodayKey();
      final now = DateTime.now();

      if (lastReset != today && now.hour >= 1) {
        await prefs.remove(_punchDataKey);
        await prefs.setString(_lastResetKey, today);
      }
    } catch (e) {
      debugPrint('❌ Reset error: ${e.toString()}');
    }
  }

  static Future<PunchData> loadTodayPunchData() async {
    await checkAndPerformReset();
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_punchDataKey);
      if (dataString != null) {
        final json = jsonDecode(dataString);
        return PunchData.fromJson(json);
      }
    } catch (e) {
      debugPrint('❌ Load data error: ${e.toString()}');
    }
    return PunchData();
  }

  static Future<void> savePunchData(PunchData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(data.toJson());
      await prefs.setString(_punchDataKey, json);
    } catch (e) {
      debugPrint('❌ Save error: ${e.toString()}');
    }
  }

  static Duration calculateWorkingHours(PunchData data) {
    if (data.punchInTime == null) return Duration.zero;
    final end = data.punchOutTime ?? DateTime.now();
    Duration duration = end.difference(data.punchInTime!);
    duration = duration - data.totalBreakTime - data.totalTiffinTime;
    return duration.isNegative ? Duration.zero : duration;
  }
}

class PunchData {
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final bool isPunchedIn;
  final bool canPunchOut;
  final DateTime? currentBreakStartTime;
  final Duration totalBreakTime;
  final bool isOnBreak;
  final DateTime? currentTiffinStartTime;
  final Duration totalTiffinTime;
  final bool isOnTiffin;
  final List<ActivityLog> activities;

  PunchData({
    this.punchInTime,
    this.punchOutTime,
    this.isPunchedIn = false,
    this.canPunchOut = false,
    this.currentBreakStartTime,
    this.totalBreakTime = Duration.zero,
    this.isOnBreak = false,
    this.currentTiffinStartTime,
    this.totalTiffinTime = Duration.zero,
    this.isOnTiffin = false,
    this.activities = const [],
  });

  PunchData copyWith({
    DateTime? punchInTime,
    DateTime? punchOutTime,
    bool? isPunchedIn,
    bool? canPunchOut,
    DateTime? currentBreakStartTime,
    Duration? totalBreakTime,
    bool? isOnBreak,
    DateTime? currentTiffinStartTime,
    Duration? totalTiffinTime,
    bool? isOnTiffin,
    List<ActivityLog>? activities,
  }) {
    return PunchData(
      punchInTime: punchInTime ?? this.punchInTime,
      punchOutTime: punchOutTime ?? this.punchOutTime,
      isPunchedIn: isPunchedIn ?? this.isPunchedIn,
      canPunchOut: canPunchOut ?? this.canPunchOut,
      currentBreakStartTime: currentBreakStartTime ?? this.currentBreakStartTime,
      totalBreakTime: totalBreakTime ?? this.totalBreakTime,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      currentTiffinStartTime: currentTiffinStartTime ?? this.currentTiffinStartTime,
      totalTiffinTime: totalTiffinTime ?? this.totalTiffinTime,
      isOnTiffin: isOnTiffin ?? this.isOnTiffin,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'punchInTime': punchInTime?.millisecondsSinceEpoch,
      'punchOutTime': punchOutTime?.millisecondsSinceEpoch,
      'isPunchedIn': isPunchedIn,
      'canPunchOut': canPunchOut,
      'currentBreakStartTime': currentBreakStartTime?.millisecondsSinceEpoch,
      'totalBreakTime': totalBreakTime.inMilliseconds,
      'isOnBreak': isOnBreak,
      'currentTiffinStartTime': currentTiffinStartTime?.millisecondsSinceEpoch,
      'totalTiffinTime': totalTiffinTime.inMilliseconds,
      'isOnTiffin': isOnTiffin,
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }

  factory PunchData.fromJson(Map<String, dynamic> json) {
    return PunchData(
      punchInTime: json['punchInTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['punchInTime']),
      punchOutTime: json['punchOutTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['punchOutTime']),
      isPunchedIn: json['isPunchedIn'] ?? false,
      canPunchOut: json['canPunchOut'] ?? false,
      currentBreakStartTime: json['currentBreakStartTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['currentBreakStartTime']),
      totalBreakTime: json['totalBreakTime'] == null ? Duration.zero : Duration(milliseconds: json['totalBreakTime']),
      isOnBreak: json['isOnBreak'] ?? false,
      currentTiffinStartTime: json['currentTiffinStartTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['currentTiffinStartTime']),
      totalTiffinTime: json['totalTiffinTime'] == null ? Duration.zero : Duration(milliseconds: json['totalTiffinTime']),
      isOnTiffin: json['isOnTiffin'] ?? false,
      activities: (json['activities'] as List?)?.map((e) => ActivityLog.fromJson(e)).toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'PunchData(punchedIn: $isPunchedIn, punchIn: $punchInTime, punchOut: $punchOutTime, breakMinutes: ${totalBreakTime.inMinutes}, tiffinMinutes: ${totalTiffinTime.inMinutes})';
  }
}

class ActivityLog {
  final String action;
  final DateTime time;
  final String? details;

  ActivityLog({required this.action, required this.time, this.details});

  Map<String, dynamic> toJson() => {
    'action': action,
    'time': time.millisecondsSinceEpoch,
    'details': details,
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      action: json['action'],
      time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      details: json['details'],
    );
  }
}

class EnhancedDashboardNotifier extends StateNotifier<PunchData> {
  EnhancedDashboardNotifier(): super(PunchData()) {
    _loadTodayData();
  }

  void _loadTodayData() async {
    final data = await DashboardAuthService.loadTodayPunchData();
    if (mounted) {
      state = data;
    }
  }

  void _addActivity(String action, {String? details}) {
    final log = ActivityLog(action: action, time: DateTime.now(), details: details);
    state = state.copyWith(activities: [...state.activities, log]);
  }

  Future<void> togglePunchInOut() async {
    final now = DateTime.now();

    if (!state.isPunchedIn) {
      if (state.punchInTime != null) {
        return;
      }
      _addActivity('Punched In');
      state = state.copyWith(punchInTime: now, isPunchedIn: true, canPunchOut: true);
    } else {
      if (state.punchOutTime != null) {
        return;
      }
      if (state.punchInTime == null) {
        return;
      }
      if (state.isOnBreak) await _endCurrentBreak();
      if (state.isOnTiffin) await _endCurrentTiffin();
      _addActivity('Punched Out');
      state = state.copyWith(punchOutTime: now, isPunchedIn: false, canPunchOut: false);
    }
    await DashboardAuthService.savePunchData(state);
  }

  Future<void> toggleBreak() async {
    if (!state.isPunchedIn || state.punchOutTime != null) {
      return;
    }
    if (state.isOnTiffin && !state.isOnBreak) {
      return;
    }
    if (!state.isOnBreak) {
      await _startBreak();
    } else {
      await _endCurrentBreak();
    }
    await DashboardAuthService.savePunchData(state);
  }

  Future<void> _startBreak() async {
    final now = DateTime.now();
    _addActivity('Break Started');
    state = state.copyWith(currentBreakStartTime: now, isOnBreak: true);
  }

  Future<void> _endCurrentBreak() async {
    if (state.currentBreakStartTime == null) return;
    final now = DateTime.now();
    final duration = now.difference(state.currentBreakStartTime!);
    _addActivity('Break Ended', details: '${duration.inMinutes} minutes');
    state = state.copyWith(
      totalBreakTime: state.totalBreakTime + duration,
      currentBreakStartTime: null,
      isOnBreak: false,
    );
  }

  Future<void> toggleTiffin() async {
    if (!state.isPunchedIn || state.punchOutTime != null) {
      return;
    }
    if (state.isOnBreak && !state.isOnTiffin) {
      return;
    }
    if (!state.isOnTiffin) {
      await _startTiffin();
    } else {
      await _endCurrentTiffin();
    }
    await DashboardAuthService.savePunchData(state);
  }

  Future<void> _startTiffin() async {
    final now = DateTime.now();
    _addActivity('Tiffin Started');
    state = state.copyWith(currentTiffinStartTime: now, isOnTiffin: true);
  }

  Future<void> _endCurrentTiffin() async {
    if (state.currentTiffinStartTime == null) return;
    final now = DateTime.now();
    final duration = now.difference(state.currentTiffinStartTime!);
    _addActivity('Tiffin Ended', details: '${duration.inMinutes} minutes');
    state = state.copyWith(
      totalTiffinTime: state.totalTiffinTime + duration,
      currentTiffinStartTime: null,
      isOnTiffin: false,
    );
  }
}

final enhancedDashboardProvider = StateNotifierProvider<EnhancedDashboardNotifier, PunchData>((ref) {
  return EnhancedDashboardNotifier();
});

// lib/core/models/task_models.dart
class TaskListResponse {
  final bool success;
  final String message;
  final TaskListData data;

  TaskListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TaskListResponse.fromJson(Map json) {
    return TaskListResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: TaskListData.fromJson(json['data'] as Map),
    );
  }
}

class TaskListData {
  final TaskOverview overview;
  final List<TaskListItem> taskList;

  TaskListData({
    required this.overview,
    required this.taskList,
  });

  factory TaskListData.fromJson(Map json) {
    return TaskListData(
      overview: TaskOverview.fromJson(json['taskOverView'] as Map),
      taskList: (json['taskList'] as List)
          .map((item) => TaskListItem.fromJson(item as Map))
          .toList(),
    );
  }
}

class TaskOverview {
  final int totalDueTask;
  final int totalOngoingTask;
  final int completeTask;
  final int totalOverdueTask;

  TaskOverview({
    required this.totalDueTask,
    required this.totalOngoingTask,
    required this.completeTask,
    required this.totalOverdueTask,
  });

  factory TaskOverview.fromJson(Map json) {
    return TaskOverview(
      totalDueTask: (json['totalDueTask'] ?? 0) as int,
      totalOngoingTask: (json['totalOngoingTask'] ?? 0) as int,
      completeTask: (json['completeTask'] ?? 0) as int,
      totalOverdueTask: (json['totalOverdueTask'] ?? 0) as int,
    );
  }
}

class TaskListItem {
  final int id;
  final String title;
  final String priority;
  final String description;
  final String status;
  final DateTime dueDate;
  final String addedByName;
  final String? completedDate;
  final bool isOverdue;
  final int overdueDays;

  TaskListItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.description,
    required this.status,
    required this.dueDate,
    required this.addedByName,
    this.completedDate,
    required this.isOverdue,
    required this.overdueDays,
  });

  factory TaskListItem.fromJson(Map json) {
    final now = DateTime.now();
    final dueDate = DateTime.parse(json['due_date'].toString());
    final isOverdue = dueDate.isBefore(now);
    final overdueDays = isOverdue ? now.difference(dueDate).inDays.abs() : 0;

    return TaskListItem(
      id: (json['id'] ?? 0) as int,
      title: json['title']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      dueDate: dueDate,
      addedByName: json['added_by_name']?.toString() ?? '',
      completedDate: json['completed_date']?.toString(),
      isOverdue: isOverdue,
      overdueDays: overdueDays,
    );
  }
}

class TaskDetailsResponse {
  final bool success;
  final String message;
  final TaskDetailsData data;

  TaskDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TaskDetailsResponse.fromJson(Map json) {
    return TaskDetailsResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: TaskDetailsData.fromJson(json['data'] as Map),
    );
  }
}

class TaskDetailsData {
  final int id;
  final String title;
  final String priority;
  final String description;
  final String status;
  final DateTime dueDate;
  final String addedByName;
  final String? completedDate;
  final bool isCompleted;
  final bool dueByNow;
  final bool isOverdue;
  final int overdueDays;

  TaskDetailsData({
    required this.id,
    required this.title,
    required this.priority,
    required this.description,
    required this.status,
    required this.dueDate,
    required this.addedByName,
    this.completedDate,
    required this.isCompleted,
    required this.dueByNow,
    required this.isOverdue,
    required this.overdueDays,
  });

  factory TaskDetailsData.fromJson(Map json) {
    return TaskDetailsData(
      id: (json['id'] ?? 0) as int,
      title: json['title']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dueDate: DateTime.parse(json['due_date'].toString()),
      addedByName: json['added_by_name']?.toString() ?? '',
      completedDate: json['completed_date']?.toString(),
      isCompleted: json['is_completed'] ?? false,
      dueByNow: json['due_by_now'] ?? false,
      isOverdue: json['is_overdue_2d'] ?? false, // Assuming 'is_overdue_2d' is the correct key
      overdueDays: (json['overdue_days'] ?? 0) as int,
    );
  }
}
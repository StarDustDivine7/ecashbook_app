import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskStatus {
  due,
  ongoing,
  complete
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.due:
        return 'Due';
      case TaskStatus.ongoing:
        return 'Ongoing';
      case TaskStatus.complete:
        return 'Complete';
    }
  }

  String get colorCode {
    switch (this) {
      case TaskStatus.due:
        return '#EF4444'; // Red
      case TaskStatus.ongoing:
        return '#F59E0B'; // Orange
      case TaskStatus.complete:
        return '#10B981'; // Green
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime assignDate;
  final String assignedBy;
  final DateTime deadline;
  TaskStatus status;
  final String priority;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignDate,
    required this.assignedBy,
    required this.deadline,
    this.status = TaskStatus.due,
    this.priority = 'Medium',
  });

  // Calculate days remaining until deadline
  int get daysRemaining {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference;
  }

  // Check if task is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(deadline) && status != TaskStatus.complete;
  }

  // Copy method for status updates
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? assignDate,
    String? assignedBy,
    DateTime? deadline,
    TaskStatus? status,
    String? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignDate: assignDate ?? this.assignDate,
      assignedBy: assignedBy ?? this.assignedBy,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }
}

enum SortBy { deadline, status, priority }
enum FilterBy { all, due, ongoing, complete, overdue }

class TaskService extends StateNotifier<List<Task>> {
  TaskService() : super([]) {
    _loadInitialTasks();
  }

  // Load initial sample tasks
  void _loadInitialTasks() {
    final sampleTasks = [
      Task(
        id: '1',
        title: 'Complete Mobile App UI Design',
        description: 'Design the complete user interface for the mobile application including all screens, components, and user flows. Ensure consistency with brand guidelines and accessibility standards.',
        assignDate: DateTime.now().subtract(const Duration(days: 3)),
        assignedBy: 'Project Manager',
        deadline: DateTime.now().add(const Duration(days: 2)),
        status: TaskStatus.due,
        priority: 'High',
      ),
      Task(
        id: '2',
        title: 'Database Schema Optimization',
        description: 'Review and optimize the database schema for better performance. Implement indexing strategies and query optimization.',
        assignDate: DateTime.now().subtract(const Duration(days: 5)),
        assignedBy: 'Technical Lead',
        deadline: DateTime.now().add(const Duration(days: 7)),
        status: TaskStatus.ongoing,
        priority: 'Medium',
      ),
      Task(
        id: '3',
        title: 'Write Unit Tests',
        description: 'Create comprehensive unit tests for the authentication module and user management features.',
        assignDate: DateTime.now().subtract(const Duration(days: 1)),
        assignedBy: 'Senior Developer',
        deadline: DateTime.now().add(const Duration(days: 5)),
        status: TaskStatus.due,
        priority: 'High',
      ),
      Task(
        id: '4',
        title: 'API Documentation Update',
        description: 'Update the API documentation with new endpoints and response formats. Include examples and error codes.',
        assignDate: DateTime.now().subtract(const Duration(days: 7)),
        assignedBy: 'Team Lead',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.due,
        priority: 'Low',
      ),
      Task(
        id: '5',
        title: 'Security Audit Report',
        description: 'Complete security audit and prepare detailed report with findings and recommendations.',
        assignDate: DateTime.now().subtract(const Duration(days: 10)),
        assignedBy: 'Security Team',
        deadline: DateTime.now().add(const Duration(days: 15)),
        status: TaskStatus.complete,
        priority: 'High',
      ),
    ];

    state = sampleTasks;
    _sortTasksByDeadline();
  }

  // Sort tasks by deadline (soonest first)
  void _sortTasksByDeadline() {
    final List<Task> sortedTasks = [...state];
    sortedTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    state = sortedTasks;
  }

  // Get filtered and sorted tasks
  List<Task> getFilteredTasks({
    FilterBy filter = FilterBy.all,
    SortBy sortBy = SortBy.deadline,
    bool includeCompleted = false,
  }) {
    List<Task> filteredTasks = [...state];

    // Apply status filter
    switch (filter) {
      case FilterBy.due:
        filteredTasks = filteredTasks.where((task) => task.status == TaskStatus.due).toList();
        break;
      case FilterBy.ongoing:
        filteredTasks = filteredTasks.where((task) => task.status == TaskStatus.ongoing).toList();
        break;
      case FilterBy.complete:
        filteredTasks = filteredTasks.where((task) => task.status == TaskStatus.complete).toList();
        break;
      case FilterBy.overdue:
        filteredTasks = filteredTasks.where((task) => task.isOverdue).toList();
        break;
      case FilterBy.all:
        if (!includeCompleted) {
          filteredTasks = filteredTasks.where((task) => task.status != TaskStatus.complete).toList();
        }
        break;
    }

    // Apply sorting
    switch (sortBy) {
      case SortBy.deadline:
        filteredTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case SortBy.status:
        filteredTasks.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case SortBy.priority:
        final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        filteredTasks.sort((a, b) {
          final aOrder = priorityOrder[a.priority] ?? 3;
          final bOrder = priorityOrder[b.priority] ?? 3;
          return aOrder.compareTo(bOrder);
        });
        break;
    }

    return filteredTasks;
  }

  // Get task by ID
  Task? getTaskById(String taskId) {
    try {
      return state.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Update task status
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final updatedTask = state[taskIndex].copyWith(status: newStatus);
      final List<Task> updatedTasks = [...state];
      updatedTasks[taskIndex] = updatedTask;
      state = updatedTasks;
      _sortTasksByDeadline();
    }
  }

  // Add new task
  void addTask(Task task) {
    state = [...state, task];
    _sortTasksByDeadline();
  }

  // Remove task
  void removeTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
  }

  // Get task statistics
  Map<String, int> getTaskStatistics() {
    final totalTasks = state.length;
    final dueTasks = state.where((task) => task.status == TaskStatus.due).length;
    final ongoingTasks = state.where((task) => task.status == TaskStatus.ongoing).length;
    final completedTasks = state.where((task) => task.status == TaskStatus.complete).length;
    final overdueTasks = state.where((task) => task.isOverdue).length;

    return {
      'total': totalTasks,
      'due': dueTasks,
      'ongoing': ongoingTasks,
      'completed': completedTasks,
      'overdue': overdueTasks,
    };
  }

  // Get tasks due in next N days
  List<Task> getTasksDueIn(int days) {
    final cutoffDate = DateTime.now().add(Duration(days: days));
    return state.where((task) {
      return task.deadline.isBefore(cutoffDate) &&
          task.status != TaskStatus.complete &&
          !task.deadline.isBefore(DateTime.now());
    }).toList();
  }

  // Mark task as completed
  void completeTask(String taskId) {
    updateTaskStatus(taskId, TaskStatus.complete);
  }

  // Start working on task
  void startTask(String taskId) {
    updateTaskStatus(taskId, TaskStatus.ongoing);
  }

  // Reopen completed task
  void reopenTask(String taskId) {
    updateTaskStatus(taskId, TaskStatus.due);
  }
}

// Provider for TaskService
final taskServiceProvider = StateNotifierProvider<TaskService, List<Task>>((ref) {
  return TaskService();
});

// Additional providers for convenience
final filteredTasksProvider = Provider.family<List<Task>, Map<String, dynamic>>((ref, params) {
  final taskService = ref.read(taskServiceProvider.notifier);

  final FilterBy filter = params['filter'] ?? FilterBy.all;
  final SortBy sortBy = params['sortBy'] ?? SortBy.deadline;
  final bool includeCompleted = params['includeCompleted'] ?? false;

  return taskService.getFilteredTasks(
    filter: filter,
    sortBy: sortBy,
    includeCompleted: includeCompleted,
  );
});

final taskStatisticsProvider = Provider<Map<String, int>>((ref) {
  final taskService = ref.read(taskServiceProvider.notifier);
  return taskService.getTaskStatistics();
});

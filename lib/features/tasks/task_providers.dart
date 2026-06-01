import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_models.dart';
import '../../core/services/task_api_service.dart';
import '../../core/api/api_client.dart';

// Task API Service Provider
final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  return TaskApiService(ApiClient.dio);
});

// Task List State
class TaskListState {
  final List<TaskListItem> tasks;
  final TaskOverview? overview;
  final bool loading;
  final String? error;

  TaskListState({
    this.tasks = const [],
    this.overview,
    this.loading = false,
    this.error,
  });

  TaskListState copyWith({
    List<TaskListItem>? tasks,
    TaskOverview? overview,
    bool? loading,
    String? error,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      overview: overview ?? this.overview,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// Task List Notifier
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskApiService _apiService;

  TaskListNotifier(this._apiService) : super(TaskListState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final response = await _apiService.fetchTaskList();
      if (response.success) {
        state = state.copyWith(
          tasks: response.data.taskList,
          overview: response.data.overview,
          loading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadCompletedTasks() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final response = await _apiService.fetchCompletedTasks();
      if (response.success) {
        state = state.copyWith(
          tasks: response.data.taskList,
          overview: response.data.overview,
          loading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future <void> refresh() async {
    await load();
  }
}

// Task List Provider
final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final apiService = ref.watch(taskApiServiceProvider);
  return TaskListNotifier(apiService);
});

// Task Details Provider
final taskDetailsProvider = FutureProvider.family<TaskDetailsData, String>((ref, taskId) async {
  final apiService = ref.watch(taskApiServiceProvider);
  final response = await apiService.fetchTaskDetails(taskId);
  if (!response.success) {
    throw Exception(response.message);
  }
  return response.data;
});

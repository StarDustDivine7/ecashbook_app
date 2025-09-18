import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_service.dart';
import 'task_view.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  FilterBy _currentFilter = FilterBy.all;
  SortBy _currentSort = SortBy.deadline;
  bool _includeCompleted = false;

  // Premium Design Colors
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  // ✅ ADDED: Scaffold back
  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(filteredTasksProvider({
      'filter': _currentFilter,
      'sortBy': _currentSort,
      'includeCompleted': _includeCompleted,
    }));

    final statistics = ref.watch(taskStatisticsProvider);

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Column(
        children: [
          // Header with Statistics
          _buildHeaderCard(statistics),

          // Filter and Sort Options
          _buildFilterSortBar(),

          // Tasks List
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, int> stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPurple, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Track your daily progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ ADD: Quick action button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () {
                    // Add new task functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add new task feature coming soon!'),
                        backgroundColor: _primaryPurple,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('${stats['due']}', 'Due', _errorRed),
              const SizedBox(width: 8),
              _buildStatChip('${stats['ongoing']}', 'Ongoing', _accentOrange),
              const SizedBox(width: 8),
              _buildStatChip('${stats['completed']}', 'Done', _accentGreen),
              if (stats['overdue']! > 0) ...[
                const SizedBox(width: 8),
                _buildStatChip('${stats['overdue']}', 'Overdue', Colors.red),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Filter Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<FilterBy>(
                value: _currentFilter,
                underline: const SizedBox(),
                isExpanded: true,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _primaryPurple,
                  size: 18,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
                items: FilterBy.values.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Row(
                      children: [
                        Icon(
                          _getFilterIcon(filter),
                          size: 16,
                          color: _getFilterColor(filter),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getFilterName(filter),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentFilter = value;
                      _includeCompleted = value == FilterBy.complete;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<SortBy>(
                value: _currentSort,
                underline: const SizedBox(),
                isExpanded: true,
                icon: Icon(
                  Icons.sort_rounded,
                  color: _primaryPurple,
                  size: 18,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
                items: SortBy.values.map((sort) {
                  return DropdownMenuItem(
                    value: sort,
                    child: Row(
                      children: [
                        Icon(
                          _getSortIcon(sort),
                          size: 16,
                          color: _primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSortName(sort),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentSort = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final statusColor = _getStatusColor(task.status);
    final isOverdue = task.isOverdue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? _errorRed.withValues(alpha: 0.3) : _borderColor,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskViewPage(taskId: task.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced Status Indicator
                Container(
                  width: 6,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),

                // Task Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Priority
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ✅ FIXED: Remove TaskPriority reference
                          // if (task.priority == TaskPriority.high)
                          //   Container(
                          //     padding: const EdgeInsets.all(4),
                          //     decoration: BoxDecoration(
                          //       color: _errorRed.withValues(alpha: 0.1),
                          //       borderRadius: BorderRadius.circular(4),
                          //     ),
                          //     child: Icon(
                          //       Icons.priority_high_rounded,
                          //       color: _errorRed,
                          //       size: 14,
                          //     ),
                          //   ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textLight,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Meta information
                      Row(
                        children: [
                          // Assigned by
                          Icon(
                            Icons.person_outline_rounded,
                            color: _textLight,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.assignedBy,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),

                          // Deadline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? _errorRed.withValues(alpha: 0.1)
                                  : _textLight.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOverdue
                                      ? Icons.error_outline_rounded
                                      : Icons.schedule_rounded,
                                  color: isOverdue ? _errorRed : _textLight,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDeadlineText(task),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOverdue ? _errorRed : _textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Enhanced Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.1),
                        statusColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(task.status),
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                color: _textLight,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 14,
                color: _textLight.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentFilter = FilterBy.all;
                  _includeCompleted = false;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ENHANCED: Helper methods with icons and colors
  IconData _getFilterIcon(FilterBy filter) {
    switch (filter) {
      case FilterBy.all:
        return Icons.list_rounded;
      case FilterBy.due:
        return Icons.schedule_rounded;
      case FilterBy.ongoing:
        return Icons.play_circle_outline_rounded;
      case FilterBy.complete:
        return Icons.check_circle_outline_rounded;
      case FilterBy.overdue:
        return Icons.error_outline_rounded;
    }
  }

  Color _getFilterColor(FilterBy filter) {
    switch (filter) {
      case FilterBy.all:
        return _textLight;
      case FilterBy.due:
        return _accentOrange;
      case FilterBy.ongoing:
        return _accentOrange;
      case FilterBy.complete:
        return _accentGreen;
      case FilterBy.overdue:
        return _errorRed;
    }
  }

  IconData _getSortIcon(SortBy sort) {
    switch (sort) {
      case SortBy.deadline:
        return Icons.event_rounded;
      case SortBy.status:
        return Icons.flag_rounded;
      case SortBy.priority:
        return Icons.priority_high_rounded;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.due:
        return Icons.schedule_rounded;
      case TaskStatus.ongoing:
        return Icons.play_circle_filled_rounded;
      case TaskStatus.complete:
        return Icons.check_circle_rounded;
    }
  }

  String _getFilterName(FilterBy filter) {
    switch (filter) {
      case FilterBy.all:
        return 'All Tasks';
      case FilterBy.due:
        return 'Due Tasks';
      case FilterBy.ongoing:
        return 'Ongoing';
      case FilterBy.complete:
        return 'Completed';
      case FilterBy.overdue:
        return 'Overdue';
    }
  }

  String _getSortName(SortBy sort) {
    switch (sort) {
      case SortBy.deadline:
        return 'By Deadline';
      case SortBy.status:
        return 'By Status';
      case SortBy.priority:
        return 'By Priority';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.due:
        return _errorRed;
      case TaskStatus.ongoing:
        return _accentOrange;
      case TaskStatus.complete:
        return _accentGreen;
    }
  }

  String _getDeadlineText(Task task) {
    if (task.isOverdue) {
      return '${task.daysRemaining.abs()}d overdue';
    } else if (task.daysRemaining == 0) {
      return 'Due today';
    } else if (task.daysRemaining == 1) {
      return 'Tomorrow';
    } else {
      return '${task.daysRemaining}d left';
    }
  }

  String _getEmptyStateMessage() {
    switch (_currentFilter) {
      case FilterBy.all:
        return 'No tasks available at the moment';
      case FilterBy.due:
        return 'No due tasks found';
      case FilterBy.ongoing:
        return 'No ongoing tasks found';
      case FilterBy.complete:
        return 'No completed tasks found';
      case FilterBy.overdue:
        return 'Great! No overdue tasks';
    }
  }
}

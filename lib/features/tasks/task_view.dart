import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_models.dart';
import 'task_providers.dart';

class TaskViewPage extends ConsumerStatefulWidget {
  final String taskId;
  final bool isReadOnly;
  const TaskViewPage({super.key, required this.taskId, this.isReadOnly = false});

  // Premium Design Colors
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  ConsumerState<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends ConsumerState<TaskViewPage> {
  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(taskDetailsProvider(widget.taskId));
    return Scaffold(
      backgroundColor: TaskViewPage._surfaceColor,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text('Task Details',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: TaskViewPage._primaryPurple,
        surfaceTintColor: Colors.transparent,
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
        data: (task) => _buildBody(task),
      ),
    );
  }

  Widget _buildBody(TaskDetailsData task) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(taskDetailsProvider(widget.taskId));
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          _buildTaskHeaderCard(task),
          _buildTaskDetailsCard(task),
          _buildStatusDisplayCard(task),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  // ——— HEADER CARD (Gradient status chip + overdue badge) ———
  Widget _buildTaskHeaderCard(TaskDetailsData task) {
    final Color statusColor = _getStatusColor(task.status);
    final bool isOverdue = task.isOverdue;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TaskViewPage._cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isOverdue
                ? TaskViewPage._errorRed.withValues(alpha: 0.3)
                : TaskViewPage._borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text(_statusDisplay(task.status),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ]),
          ),
          const Spacer(),
          if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: TaskViewPage._errorRed,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: TaskViewPage._errorRed.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]),
              child: const Text('OVERDUE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ),
        ]),
        const SizedBox(height: 20),
        Text(task.title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TaskViewPage._textDark,
                height: 1.2)),
        const SizedBox(height: 12),
        Text(task.description,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: TaskViewPage._textDark,
                height: 1.5)),
      ]),
    );
  }

  // —— Filters row (matches Task List page style) ——
  // Widget _buildFiltersRow() {
  //   return Row(children: [
  //     _buildFilterChip(Icons.view_list_rounded, 'All Tasks'),
  //     const SizedBox(width: 12),
  //     _buildFilterChip(Icons.event_rounded, 'By Deadline'),
  //     const Spacer(),
  //     _buildIconChip(Icons.tune_rounded),
  //   ]);
  // }

  Widget _buildFilterChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TaskViewPage._cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TaskViewPage._borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: TaskViewPage._textLight),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: TaskViewPage._textDark, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildIconChip(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TaskViewPage._cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TaskViewPage._borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, size: 18, color: TaskViewPage._textLight),
    );
  }

  // ——— DETAILS CARD ———
  Widget _buildTaskDetailsCard(TaskDetailsData task) {
    final remainingDays = _daysRemaining(task.dueDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TaskViewPage._cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TaskViewPage._borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: TaskViewPage._primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.info_outline_rounded,
                  color: TaskViewPage._primaryPurple, size: 20)),
          const SizedBox(width: 12),
          const Text('Task Information',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TaskViewPage._textDark)),
        ]),
        const SizedBox(height: 20),
        _buildDetailRow(
            'Assigned By', task.addedByName, Icons.person_outline_rounded),
        _buildDetailRow(
            'Due Date', _formatDate(task.dueDate), Icons.event_rounded,
            isDeadline: true, task: task),
        _buildDetailRow('Days Remaining', remainingDays, Icons.schedule_rounded,
            isDeadline: task.isOverdue),
      ]),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {bool isDeadline = false, TaskDetailsData? task}) {
    Color textColor = TaskViewPage._textDark;
    Color valueColor = TaskViewPage._textLight;
    if (isDeadline && (task?.isOverdue == true)) {
      textColor = TaskViewPage._errorRed;
      valueColor = TaskViewPage._errorRed;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: textColor, size: 16)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ])),
      ]),
    );
  }

  // ——— STATUS DROPDOWN (interactive; updates API) ———
  // ——— STATUS DROPDOWN (interactive; updates API) ———
  Widget _buildStatusDisplayCard(TaskDetailsData task) {
    final Color statusColor = _getStatusColor(task.status);
    final items = const ['Pending', 'In Progress', 'Completed'];
    String current = _statusDisplay(task.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TaskViewPage._cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TaskViewPage._borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.update_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Task Status',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TaskViewPage._textDark)),
          ]),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.1),
                  statusColor.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                    color: statusColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: statusColor, size: 26),
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                items: items
                    .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Row(children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getStatusColor(s),
                                      _getStatusColor(s).withValues(alpha: 0.8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_statusIcon(s),
                                    color: Colors.white, size: 18)),
                            const SizedBox(width: 12),
                            Text(s,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(s))),
                          ]),
                        ))
                    .toList(),
                onChanged: widget.isReadOnly
                    ? null
                    : (val) async {
                        if (val == null || val == current) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          // Completed requires completedDate param
                          String? completed;
                          if (val.toLowerCase() == 'completed') {
                            final now = DateTime.now();
                            completed =
                                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
                                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
                          }

                          final api = ref.read(taskApiServiceProvider);
                          final ok = await api.updateTaskStatus(
                              taskId: widget.taskId,
                              status: val,
                              completedDate: completed);
                          if (ok) {
                            messenger.showSnackBar(
                                const SnackBar(content: Text('Task status updated')));
                            ref.invalidate(taskDetailsProvider(widget.taskId));
                            setState(() {});
                          } else {
                            messenger.showSnackBar(
                                const SnackBar(content: Text('Update failed')));
                          }
                        } catch (e) {
                          messenger.showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')));
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TaskViewPage._cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: TaskViewPage._textDark),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: valueColor ?? TaskViewPage._textLight,
            fontWeight:
                valueColor != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskViewPage._errorRed;
      case 'in progress':
        return TaskViewPage._accentOrange;
      case 'completed':
        return TaskViewPage._accentGreen;
      default:
        return TaskViewPage._textLight;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return TaskViewPage._errorRed;
      case 'medium':
        return TaskViewPage._accentOrange;
      case 'low':
        return TaskViewPage._accentGreen;
      default:
        return TaskViewPage._textLight;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _statusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_rounded;
      case 'in progress':
        return Icons.play_circle_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _daysRemaining(DateTime due) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final diff = due.difference(base).inDays;
    if (diff < 0) return '${diff.abs()} days overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_models.dart';
import 'task_view.dart';
import '../../shared/main_layout.dart';
import 'task_providers.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  @override
  void initState() {
    super.initState();
    // This is the correct way to call an async function in initState.
    // It delays the execution until after the first frame has been rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).load();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _cardWhite,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(taskListProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(taskState.overview),
              const SizedBox(height: 16),
              _buildFiltersRow(),
              const SizedBox(height: 20),
              taskState.loading
                  ? const Center(child: CircularProgressIndicator())
                  : taskState.error != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: _errorRed),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      taskState.error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(taskListProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
                  : taskState.tasks.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt, size: 48, color: _textLight),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have no tasks assigned at the moment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: taskState.tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = taskState.tasks[index];
                  return _buildTaskCard(context, task);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(TaskOverview? overview) {
    if (overview == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryPurple, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle_outline, color: Colors.white)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Task Overview', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Track your daily progress', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ])),
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _buildOverviewPill('${overview.totalDueTask}', 'Due', Colors.white, _errorRed.withOpacity(0.25)),
          const SizedBox(width: 10),
          _buildOverviewPill('${overview.totalOngoingTask}', 'Ongoing', Colors.white, _accentOrange.withOpacity(0.25)),
          const SizedBox(width: 10),
          _buildOverviewPill('${overview.completeTask}', 'Done', Colors.white, _accentGreen.withOpacity(0.25)),
          const SizedBox(width: 10),
          _buildOverviewPill('${overview.totalOverdueTask}', 'Overdue', Colors.white, Colors.white.withOpacity(0.15)),
        ]),
      ]),
    );
  }

  Widget _buildOverviewRow(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _textDark,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewPill(String count, String label, Color textColor, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(count, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: textColor.withOpacity(0.95), fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(children: [
      _buildFilterChip(Icons.view_list_rounded, 'All Tasks'),
      const SizedBox(width: 12),
      _buildFilterChip(Icons.event_rounded, 'By Deadline'),
      const Spacer(),
      _buildIconChip(Icons.tune_rounded),
    ]);
  }

  Widget _buildFilterChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [Icon(icon, size: 18, color: _textLight), const SizedBox(width: 8), Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildIconChip(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, size: 18, color: _textLight),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskListItem task) {
    Color statusColor = _getStatusColor(task.status);
    Color priorityColor = _getPriorityColor(task.priority);

    final DateTime now = DateTime.now();
    final int diffDays = task.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MainLayout(initialIndex: 9, taskId: task.id.toString()),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(children: [
                    Container(width: 4, height: 24, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark))),
                  ]),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 16, color: _textLight),
              const SizedBox(width: 6),
              Expanded(child: Text(task.addedByName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Icon(Icons.schedule, size: 16, color: _textLight),
              const SizedBox(width: 6),
              Text(_dueLabel(diffDays), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: task.isOverdue ? _errorRed : _accentOrange)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (task.isOverdue ? _errorRed : _accentOrange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(task.isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded, size: 12, color: task.isOverdue ? _errorRed : _accentOrange), const SizedBox(width: 4), Text('Due', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: task.isOverdue ? _errorRed : _accentOrange))])),
            ]),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _errorRed;
      case 'ongoing':
        return _accentOrange;
      case 'complete':
        return _accentGreen;
      default:
        return _textLight;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return _errorRed;
      case 'medium':
        return _accentOrange;
      case 'low':
        return _accentGreen;
      default:
        return _textLight;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _dueLabel(int diffDays) {
    if (diffDays < 0) return '${diffDays.abs()}d overdue';
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    return '${diffDays}d left';
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const double _dayWidth = 62;

  late final DateTime _today;
  late final List<DateTime> _days;
  late DateTime _selected;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _today = DateTime(n.year, n.month, n.day);
    _selected = _today;
    _days = List.generate(45, (i) => DateTime(_today.year, _today.month, _today.day + i - 7));
    _scroll = ScrollController(initialScrollOffset: 5 * _dayWidth);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final tasks = state.allTasks.where((t) => _same(t.dueDate, _selected)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TaskFormScreen(initialDate: _selected))),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(DateFormat('MMMM yyyy').format(_selected),
                      style: text.titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ),
              SizedBox(
                height: 78,
                child: ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _days.length,
                  itemBuilder: (context, i) {
                    final d = _days[i];
                    final selected = _same(d, _selected);
                    final hasTasks =
                        state.allTasks.any((t) => _same(t.dueDate, d));
                    return GestureDetector(
                      onTap: () => setState(() => _selected = d),
                      child: Container(
                        width: _dayWidth - 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.blue
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${d.day}',
                                style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : null)),
                            const SizedBox(height: 2),
                            Text(DateFormat('EEE').format(d),
                                style: text.bodySmall?.copyWith(
                                    color: selected
                                        ? Colors.white70
                                        : scheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasTasks
                                    ? (selected ? Colors.white : AppColors.teal)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available,
                                size: 52,
                                color: scheme.onSurfaceVariant.withAlpha(140)),
                            const SizedBox(height: 10),
                            Text('No tasks on this day',
                                style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _TimelineRow(
                          task: tasks[i],
                          isLast: i == tasks.length - 1,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => TaskFormScreen(task: tasks[i])),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Task task;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRow({
    required this.task,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = AppColors.category(task.category);
    final time = DateFormat('h:mm a').format(task.dueDate).toLowerCase();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(time,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 1.5, color: scheme.onSurfaceVariant.withAlpha(50)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 4, color: color),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.category.toUpperCase(),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(
                                  task.title,
                                  style: text.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? scheme.onSurfaceVariant
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  task.isCompleted
                                      ? 'Completed'
                                      : (task.isRepeating
                                          ? '$time  ·  ${task.repeatLabel}'
                                          : 'Due $time'),
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

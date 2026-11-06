import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

enum TaskMenuAction { edit, delete }

/// "Today", "Tomorrow", "Yesterday" or "Sat, 8 Nov".
String dayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return DateFormat('EEE, d MMM').format(d);
}

/// Round tick box (filled blue when done).
class RoundCheck extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  final Color color;

  const RoundCheck({
    super.key,
    required this.value,
    required this.onTap,
    this.color = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? color : Colors.transparent,
            border: Border.all(
                color: value ? color : muted.withAlpha(150), width: 2),
          ),
          child: value
              ? const Icon(Icons.check, size: 15, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final ValueChanged<TaskMenuAction> onMenu;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final overdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    final catColor = AppColors.category(task.category);
    final muted = scheme.onSurfaceVariant;
    final timeColor = overdue ? scheme.error : muted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
          child: Row(
            children: [
              RoundCheck(value: task.isCompleted, onTap: onToggle, color: catColor),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration:
                              task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? muted : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 2,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.schedule, size: 13, color: timeColor),
                            const SizedBox(width: 4),
                            Text(
                              '${dayLabel(task.dueDate)}, ${DateFormat('h:mm a').format(task.dueDate)}',
                              style: text.bodySmall?.copyWith(color: timeColor),
                            ),
                          ]),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: catColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(task.category,
                                style: text.bodySmall?.copyWith(color: muted)),
                          ]),
                          if (task.isRepeating)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.repeat, size: 13, color: muted),
                              const SizedBox(width: 4),
                              Text(task.repeatLabel.replaceFirst('Weekly: ', ''),
                                  style: text.bodySmall?.copyWith(color: muted)),
                            ]),
                        ],
                      ),
                      if (task.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: task.progress,
                                  minHeight: 5,
                                  color: catColor,
                                  backgroundColor: catColor.withAlpha(45),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${task.doneSubtasks}/${task.subtasks.length}  ·  ${(task.progress * 100).round()}%',
                              style: text.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<TaskMenuAction>(
                tooltip: 'More',
                icon: Icon(Icons.more_vert, color: muted, size: 20),
                onSelected: onMenu,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: TaskMenuAction.edit,
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                  PopupMenuItem(
                      value: TaskMenuAction.delete,
                      child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

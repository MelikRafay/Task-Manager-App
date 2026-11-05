import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

enum TaskMenuAction { edit, delete }

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
    final fmt = DateFormat('EEE, d MMM  •  h:mm a');

    Widget meta(IconData icon, String label, {Color? color}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label,
                style: text.bodySmall?.copyWith(color: color ?? scheme.onSurfaceVariant)),
          ],
        );

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withAlpha(110),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                shape: const CircleBorder(),
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: text.titleMedium?.copyWith(
                          decoration:
                              task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      if (task.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          meta(Icons.schedule, fmt.format(task.dueDate),
                              color: overdue ? scheme.error : null),
                          meta(Icons.label_outline, task.category),
                          if (task.isRepeating)
                            meta(Icons.repeat, task.repeatLabel),
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
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${task.doneSubtasks}/${task.subtasks.length}  ·  ${(task.progress * 100).round()}%',
                              style: text.bodySmall,
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

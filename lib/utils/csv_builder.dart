import 'package:intl/intl.dart';

import '../models/task.dart';

String csvEscape(String v) {
  if (v.contains(RegExp(r'[",\n\r]'))) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String buildCsv(List<Task> tasks) {
  final fmt = DateFormat('yyyy-MM-dd HH:mm');
  final rows = <List<String>>[
    [
      'ID',
      'Title',
      'Description',
      'Category',
      'Due',
      'Status',
      'Repeat',
      'Progress',
      'Subtasks',
    ],
    for (final t in tasks)
      [
        '${t.id ?? ''}',
        t.title,
        t.description,
        t.category,
        fmt.format(t.dueDate),
        t.isCompleted ? 'Completed' : 'Pending',
        t.repeatLabel,
        '${(t.progress * 100).round()}%',
        t.subtasks.map((s) => '[${s.done ? 'x' : ' '}] ${s.title}').join('; '),
      ],
  ];
  return rows.map((r) => r.map(csvEscape).join(',')).join('\r\n');
}

/// Plain-text version used for the email body.
String buildPlainText(List<Task> tasks) {
  final fmt = DateFormat('EEE d MMM yyyy, h:mm a');
  final b = StringBuffer('My tasks (${tasks.length})\n\n');
  for (final t in tasks) {
    b.writeln('${t.isCompleted ? '[x]' : '[ ]'} ${t.title}');
    b.writeln('    Due: ${fmt.format(t.dueDate)}  |  ${t.category}');
    if (t.isRepeating) b.writeln('    Repeat: ${t.repeatLabel}');
    if (t.description.isNotEmpty) b.writeln('    ${t.description}');
    for (final s in t.subtasks) {
      b.writeln('      - [${s.done ? 'x' : ' '}] ${s.title}');
    }
    b.writeln();
  }
  return b.toString();
}

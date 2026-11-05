import '../utils/constants.dart';

class SubTask {
  final int? id;
  final String title;
  final bool done;

  const SubTask({this.id, required this.title, this.done = false});

  SubTask copyWith({String? title, bool? done}) =>
      SubTask(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, Object?> toMap(int taskId) => {
        'task_id': taskId,
        'title': title,
        'is_done': done ? 1 : 0,
      };

  factory SubTask.fromMap(Map<String, Object?> m) => SubTask(
        id: m['id'] as int,
        title: m['title'] as String,
        done: (m['is_done'] as int) == 1,
      );
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate; // date + time
  final bool isCompleted;
  final DateTime? completedAt;
  final RepeatType repeatType;
  final Set<int> repeatDays; // 1 = Mon ... 7 = Sun (used by weekly)
  final String category;
  final List<SubTask> subtasks;
  final DateTime createdAt;

  const Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.repeatType = RepeatType.none,
    this.repeatDays = const {},
    this.category = 'General',
    this.subtasks = const [],
    required this.createdAt,
  });

  bool get isRepeating => repeatType != RepeatType.none;

  int get doneSubtasks => subtasks.where((s) => s.done).length;

  /// 0.0 - 1.0. Completed tasks are always 100 %.
  double get progress {
    if (isCompleted) return 1;
    if (subtasks.isEmpty) return 0;
    return doneSubtasks / subtasks.length;
  }

  String get repeatLabel {
    switch (repeatType) {
      case RepeatType.none:
        return 'Does not repeat';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        final days = repeatDays.toList()..sort();
        return 'Weekly: ${days.map((d) => kWeekdayShort[d - 1]).join(', ')}';
    }
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    RepeatType? repeatType,
    Set<int>? repeatDays,
    String? category,
    List<SubTask>? subtasks,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt:
            clearCompletedAt ? null : (completedAt ?? this.completedAt),
        repeatType: repeatType ?? this.repeatType,
        repeatDays: repeatDays ?? this.repeatDays,
        category: category ?? this.category,
        subtasks: subtasks ?? this.subtasks,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() {
    final days = repeatDays.toList()..sort();
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'repeat_type': repeatType.name,
      'repeat_days': days.join(','),
      'category': category,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, Object?> m, List<SubTask> subtasks) {
    final daysStr = (m['repeat_days'] as String?) ?? '';
    return Task(
      id: m['id'] as int,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      dueDate: DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
      isCompleted: (m['is_completed'] as int) == 1,
      completedAt: m['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
      repeatType: RepeatType.values.byName(m['repeat_type'] as String),
      repeatDays:
          daysStr.isEmpty ? <int>{} : daysStr.split(',').map(int.parse).toSet(),
      category: (m['category'] as String?) ?? 'General',
      subtasks: subtasks,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }
}

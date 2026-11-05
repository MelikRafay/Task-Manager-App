import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/repeat.dart';

/// Makes [AppState] available anywhere below it: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notifier = NotificationService.instance;

  List<Task> _tasks = [];
  ThemeMode themeMode = ThemeMode.system;
  String soundId = 'default';
  bool loading = true;
  String? error;

  Timer? _timer;
  final Set<String> _alerted = {};

  /// Called (web only) when a task becomes due while the app is open.
  void Function(Task task)? onReminder;

  // ------------------------------------------------------------------ init
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('theme');
      themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      );
      final sound = prefs.getString('sound');
      if (sound != null && kSoundOptions.containsKey(sound)) soundId = sound;
    } catch (_) {}

    try {
      await _notifier.init();
      _tasks = await _db.getTasks();
      await _rescheduleAll();
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();

    if (kIsWeb) {
      // Web has no background scheduling, so check for due tasks in-app.
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkDue());
      _checkDue();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------- queries
  List<Task> get allTasks => List.unmodifiable(_tasks);

  bool _matches(Task t, String? category) =>
      category == null || t.category == category;

  DateTime get _startOfToday {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _endOfToday {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + 1);
  }

  List<Task> overdueTasks([String? category]) => _tasks
      .where((t) =>
          !t.isCompleted &&
          t.dueDate.isBefore(_startOfToday) &&
          _matches(t, category))
      .toList();

  List<Task> todayTasks([String? category]) => _tasks
      .where((t) =>
          !t.isCompleted &&
          !t.dueDate.isBefore(_startOfToday) &&
          t.dueDate.isBefore(_endOfToday) &&
          _matches(t, category))
      .toList();

  List<Task> completedTasks([String? category]) {
    final list = _tasks.where((t) => t.isCompleted && _matches(t, category));
    return list.toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate));
  }

  List<Task> repeatedTasks([String? category]) => _tasks
      .where((t) => !t.isCompleted && t.isRepeating && _matches(t, category))
      .toList();

  /// Tasks finished today (including completions of repeating tasks).
  int get completedTodayCount => _tasks
      .where((t) =>
          t.isCompleted &&
          t.completedAt != null &&
          !t.completedAt!.isBefore(_startOfToday))
      .length;

  // --------------------------------------------------------------- actions
  Future<void> _reload() async {
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  Future<void> saveTask(Task t) async {
    int id;
    if (t.id == null) {
      id = await _db.insertTask(t);
    } else {
      await _db.updateTask(t);
      id = t.id!;
    }
    await _reload();
    final saved = _tasks.where((x) => x.id == id);
    if (saved.isNotEmpty) await _notifier.schedule(saved.first, soundId);
  }

  Future<void> deleteTask(Task t) async {
    if (t.id == null) return;
    await _notifier.cancel(t.id!);
    await _db.deleteTask(t.id!);
    await _reload();
  }

  /// Marks a task completed (moving it to "Completed") or restores it.
  ///
  /// Repeating tasks are special: a completed copy is written to history and
  /// the original is reset (subtasks unchecked) and moved to its next
  /// occurrence.
  Future<void> toggleComplete(Task t) async {
    final now = DateTime.now();

    if (!t.isCompleted && t.isRepeating) {
      await _db.insertTask(Task(
        title: t.title,
        description: t.description,
        dueDate: t.dueDate,
        isCompleted: true,
        completedAt: now,
        category: t.category,
        subtasks: t.subtasks
            .map((s) => SubTask(title: s.title, done: s.done))
            .toList(),
        createdAt: now,
      ));
      final next = t.copyWith(
        dueDate: nextOccurrence(t, now),
        subtasks: t.subtasks.map((s) => s.copyWith(done: false)).toList(),
      );
      await _db.updateTask(next);
    } else if (!t.isCompleted) {
      await _db.updateTask(t.copyWith(isCompleted: true, completedAt: now));
    } else {
      await _db
          .updateTask(t.copyWith(isCompleted: false, clearCompletedAt: true));
    }

    await _reload();
    if (t.id != null) {
      final cur = _tasks.where((x) => x.id == t.id);
      if (cur.isNotEmpty) await _notifier.schedule(cur.first, soundId);
    }
  }

  // -------------------------------------------------------------- settings
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', mode.name);
    } catch (_) {}
  }

  Future<void> setSound(String id) async {
    soundId = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sound', id);
    } catch (_) {}
    await _rescheduleAll();
  }

  Future<void> sendTestNotification() => _notifier.notifyNow(
        'Test notification',
        'This is how your task reminders will sound.',
        soundId,
      );

  Future<void> _rescheduleAll() async {
    for (final t in _tasks) {
      await _notifier.schedule(t, soundId);
    }
  }

  // ------------------------------------------------------ web reminder loop
  void _checkDue() {
    final now = DateTime.now();
    for (final t in _tasks) {
      if (t.isCompleted) continue;
      if (t.dueDate.isAfter(now)) continue;
      final key = '${t.id}_${t.dueDate.millisecondsSinceEpoch}';
      if (!_alerted.add(key)) continue;
      // Only alert for tasks that just became due, not old overdue ones.
      if (now.difference(t.dueDate) < const Duration(minutes: 5)) {
        _notifier.notifyNow(
          'Task due: ${t.title}',
          t.description.isEmpty ? t.category : t.description,
          soundId,
        );
        onReminder?.call(t);
      }
    }
  }
}

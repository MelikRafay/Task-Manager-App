import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/utils/constants.dart';
import 'package:task_manager/utils/csv_builder.dart';
import 'package:task_manager/utils/repeat.dart';

Task _task({
  required DateTime due,
  RepeatType repeat = RepeatType.none,
  Set<int> days = const {},
  List<SubTask> subs = const [],
  bool done = false,
  String title = 'Test',
}) =>
    Task(
      id: 1,
      title: title,
      dueDate: due,
      repeatType: repeat,
      repeatDays: days,
      subtasks: subs,
      isCompleted: done,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('repeat logic', () {
    test('daily task moves to tomorrow, same time', () {
      final t =
          _task(due: DateTime(2026, 11, 5, 9, 0), repeat: RepeatType.daily);
      expect(nextOccurrence(t, DateTime(2026, 11, 5, 10, 0)),
          DateTime(2026, 11, 6, 9, 0));
    });

    test('weekly task goes to next selected weekday', () {
      // 2 Nov 2026 is a Monday; Mon + Wed selected
      final t = _task(
          due: DateTime(2026, 11, 2, 9, 0),
          repeat: RepeatType.weekly,
          days: {1, 3});
      expect(nextOccurrence(t, DateTime(2026, 11, 2, 8, 0)),
          DateTime(2026, 11, 4, 9, 0));
    });

    test('overdue weekly task skips to a future date', () {
      final t = _task(
          due: DateTime(2026, 11, 2, 9, 0),
          repeat: RepeatType.weekly,
          days: {1, 3});
      // today is Thursday 5 Nov -> next Monday 9 Nov
      expect(nextOccurrence(t, DateTime(2026, 11, 5, 12, 0)),
          DateTime(2026, 11, 9, 9, 0));
    });

    test('alignToRepeat moves to first selected day', () {
      // Thursday 5 Nov, only Monday selected
      expect(alignToRepeat(DateTime(2026, 11, 5, 9, 0), {1}),
          DateTime(2026, 11, 9, 9, 0));
      // already on a selected day -> unchanged
      expect(alignToRepeat(DateTime(2026, 11, 5, 9, 0), {4}),
          DateTime(2026, 11, 5, 9, 0));
    });
  });

  group('progress', () {
    test('no subtasks -> 0 %, completed -> 100 %', () {
      expect(_task(due: DateTime(2026, 11, 5)).progress, 0);
      expect(_task(due: DateTime(2026, 11, 5), done: true).progress, 1);
    });

    test('progress is share of finished subtasks', () {
      final t = _task(due: DateTime(2026, 11, 5), subs: const [
        SubTask(title: 'a', done: true),
        SubTask(title: 'b'),
        SubTask(title: 'c', done: true),
        SubTask(title: 'd'),
      ]);
      expect(t.progress, 0.5);
    });
  });

  group('model <-> map', () {
    test('round trip keeps all fields', () {
      final t = Task(
        id: 7,
        title: 'Gym',
        description: 'Legs',
        dueDate: DateTime(2026, 11, 6, 18, 30),
        repeatType: RepeatType.weekly,
        repeatDays: const {1, 4},
        category: 'Health',
        createdAt: DateTime(2026, 11, 1),
      );
      final back = Task.fromMap(t.toMap(), const []);
      expect(back.title, 'Gym');
      expect(back.repeatType, RepeatType.weekly);
      expect(back.repeatDays, {1, 4});
      expect(back.dueDate, t.dueDate);
      expect(back.category, 'Health');
    });
  });

  group('csv', () {
    test('escapes commas and quotes', () {
      final csv = buildCsv([
        _task(due: DateTime(2026, 11, 5, 9, 0), title: 'Buy "milk", eggs'),
      ]);
      expect(csv.split('\r\n').length, 2);
      expect(csv, contains('"Buy ""milk"", eggs"'));
    });
  });
}

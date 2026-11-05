import '../models/task.dart';
import 'constants.dart';

/// Next due date-time for a repeating task after it has been completed.
///
/// The time of day is kept; the date moves to the next day that matches the
/// repeat rule and is strictly after both the old due date and today.
DateTime nextOccurrence(Task t, DateTime now) {
  if (!t.isRepeating) return t.dueDate;
  final dueDay = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  var day = dueDay.isAfter(today) ? dueDay : today;
  for (var i = 0; i < 8; i++) {
    day = DateTime(day.year, day.month, day.day + 1);
    final matches = t.repeatType == RepeatType.daily ||
        (t.repeatType == RepeatType.weekly &&
            t.repeatDays.contains(day.weekday));
    if (matches) break;
  }
  return DateTime(
      day.year, day.month, day.day, t.dueDate.hour, t.dueDate.minute);
}

/// For weekly tasks: if [due] falls on a weekday that is not selected, move it
/// forward to the next selected weekday (time of day is kept).
DateTime alignToRepeat(DateTime due, Set<int> days) {
  if (days.isEmpty) return due;
  var d = due;
  for (var i = 0; i < 7; i++) {
    if (days.contains(d.weekday)) return d;
    d = DateTime(d.year, d.month, d.day + 1, due.hour, due.minute);
  }
  return due;
}

String weekdayName(int d) => kWeekdayShort[d - 1];

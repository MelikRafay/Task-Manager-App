import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/file_ops.dart';

/// Local notifications.
///  * Android / iOS: scheduled with flutter_local_notifications.
///  * Web: the plugin is not supported, so AppState runs an in-app reminder
///    timer and this class shows browser notifications + plays a tone.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (kIsWeb) {
      await requestBrowserNotificationPermission();
      return;
    }
    if (!_supported) return;

    tzdata.initializeTimeZones();
    try {
      final dynamic tzRes = await FlutterTimezone.getLocalTimezone();
      final String name =
          tzRes is String ? tzRes : (tzRes as dynamic).name.toString();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      try {
        final String fallbackName = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(fallbackName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(init);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    _ready = true;
  }

  NotificationDetails _details(String soundId) {
    AndroidNotificationSound? sound;
    if (soundId == 'alarm') {
      sound = const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert');
    } else if (soundId == 'ringtone') {
      sound = const UriAndroidNotificationSound(
          'content://settings/system/ringtone');
    }
    return NotificationDetails(
      // Android channels are immutable, so each sound gets its own channel.
      android: AndroidNotificationDetails(
        'task_reminders_$soundId',
        'Task reminders (${kSoundOptions[soundId] ?? soundId})',
        channelDescription: 'Reminders for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
        playSound: soundId != 'silent',
        sound: sound,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(presentSound: soundId != 'silent'),
    );
  }

  Future<void> cancel(int taskId) async {
    if (!_ready) return;
    for (var k = 0; k <= 7; k++) {
      await _plugin.cancel(taskId * 10 + k);
    }
  }

  /// (Re)schedules the notification(s) for [t].
  Future<void> schedule(Task t, String soundId) async {
    if (!_ready || t.id == null) return;
    await cancel(t.id!);
    if (t.isCompleted && !t.isRepeating) return;

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidImpl?.canScheduleExactNotifications() ?? true;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final details = _details(soundId);
    final now = tz.TZDateTime.now(tz.local);
    final h = t.dueDate.hour;
    final m = t.dueDate.minute;
    final body = t.description.isEmpty ? t.category : t.description;

    Future<void> zoned(int id, tz.TZDateTime when, DateTimeComponents? match) =>
        _plugin.zonedSchedule(
          id,
          'Task due: ${t.title}',
          body,
          when,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: match,
        );

    switch (t.repeatType) {
      case RepeatType.none:
        final when = tz.TZDateTime.from(t.dueDate, tz.local);
        if (when.isAfter(now)) await zoned(t.id! * 10, when, null);
      case RepeatType.daily:
        var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        if (!when.isAfter(now)) {
          when = when.add(const Duration(days: 1));
        }
        await zoned(t.id! * 10, when, DateTimeComponents.time);
      case RepeatType.weekly:
        for (final d in t.repeatDays) {
          var when =
              tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
          for (var i = 0; i < 8; i++) {
            if (when.weekday == d && when.isAfter(now)) break;
            when = when.add(const Duration(days: 1));
          }
          await zoned(
              t.id! * 10 + d, when, DateTimeComponents.dayOfWeekAndTime);
        }
    }
  }

  /// Shows a notification immediately (used for web reminders and the
  /// "test notification" button).
  Future<void> notifyNow(String title, String body, String soundId) async {
    if (kIsWeb) {
      await showBrowserNotification(title, body);
      await playBeep(soundId);
      return;
    }
    if (!_ready) return;
    await _plugin.show(999999, title, body, _details(soundId));
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/shift.dart';

/// Schedules local reminders before each confirmed shift.
class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  static const String _channelId = 'shift_reminders';
  static const String _channelName = 'Shift Reminders';
  static const String _channelDesc =
      'Reminds you a few minutes before a shift starts.';

  /// Call once during app startup.
  Future<void> init() async {
    if (_initialised) return;

    // Timezone database for scheduled notifications.
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialised = true;
  }

  /// Ask for notification permission (Android 13+ and iOS).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  /// Schedule a reminder for [shift], [minutesBefore] minutes before it
  /// starts. Does nothing if the reminder time is already in the past.
  Future<void> scheduleForShift(Shift shift, int minutesBefore) async {
    if (kIsWeb) return;

    final reminderTime = shift.startDateTime
        .subtract(Duration(minutes: minutesBefore));

    if (reminderTime.isBefore(DateTime.now())) return;

    final notificationId = shift.key.hashCode & 0x7fffffff;

    await _plugin.zonedSchedule(
      notificationId,
      'Upcoming Shift',
      '${shift.title} starts at ${shift.startTime}',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Cancel a single shift's reminder.
  Future<void> cancelForShift(Shift shift) async {
    if (kIsWeb) return;
    await _plugin.cancel(shift.key.hashCode & 0x7fffffff);
  }

  /// Cancel everything (used when preferences change or data is cleared).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
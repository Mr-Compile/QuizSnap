import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

class ReminderService {
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _reminderDaysKey = 'reminder_days';
  static const String _reminderFrequencyKey = 'reminder_frequency';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;

  bool _isEnabled = false;
  String _reminderTime = '09:00';
  List<int> _reminderDays = [1, 2, 3, 4, 5]; // Monday to Friday
  String _frequency = 'daily'; // 'daily', 'weekly', 'custom'

  bool get isEnabled => _isEnabled;
  String get reminderTime => _reminderTime;
  List<int> get reminderDays => _reminderDays;
  String get frequency => _frequency;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    tz_data.initializeTimeZones();
    
    await _loadSettings();
    await _initializeNotifications();
    
    if (_isEnabled) {
      await scheduleReminders();
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to study screen
    // This will be handled by the app's navigation system
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _isEnabled = _prefs!.getBool(_reminderEnabledKey) ?? false;
    _reminderTime = _prefs!.getString(_reminderTimeKey) ?? '09:00';
    _frequency = _prefs!.getString(_reminderFrequencyKey) ?? 'daily';
    
    final daysString = _prefs!.getString(_reminderDaysKey);
    if (daysString != null) {
      _reminderDays = daysString.split(',').map(int.parse).toList();
    }
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    await _prefs!.setBool(_reminderEnabledKey, _isEnabled);
    await _prefs!.setString(_reminderTimeKey, _reminderTime);
    await _prefs!.setString(_reminderFrequencyKey, _frequency);
    await _prefs!.setString(_reminderDaysKey, _reminderDays.join(','));
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      await scheduleReminders();
    } else {
      await cancelAllReminders();
    }
  }

  Future<void> setReminderTime(String time) async {
    _reminderTime = time;
    await _saveSettings();

    if (_isEnabled) {
      await scheduleReminders();
    }
  }

  Future<void> setReminderDays(List<int> days) async {
    _reminderDays = days;
    await _saveSettings();

    if (_isEnabled) {
      await scheduleReminders();
    }
  }

  Future<void> setFrequency(String frequency) async {
    _frequency = frequency;
    await _saveSettings();

    if (_isEnabled) {
      await scheduleReminders();
    }
  }

  Future<void> scheduleReminders() async {
    await cancelAllReminders();

    if (!_isEnabled) return;

    final timeParts = _reminderTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    switch (_frequency) {
      case 'daily':
        await _scheduleDailyReminder(hour, minute);
        break;
      case 'weekly':
        for (final day in _reminderDays) {
          await _scheduleWeeklyReminder(day, hour, minute);
        }
        break;
      case 'custom':
        for (final day in _reminderDays) {
          await _scheduleWeeklyReminder(day, hour, minute);
        }
        break;
    }
  }

  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Try exact alarm first, fall back to inexact if permission not granted
    try {
      await _notifications.zonedSchedule(
        0,
        'Study Reminder',
        'Time to review your flashcards!',
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Fall back to inexact scheduling if exact alarm permission is denied
      await _notifications.zonedSchedule(
        0,
        'Study Reminder',
        'Time to review your flashcards!',
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _scheduleWeeklyReminder(int day, int hour, int minute) async {
    // Try exact alarm first, fall back to inexact if permission not granted
    try {
      await _notifications.zonedSchedule(
        day,
        'Study Reminder',
        'Time to review your flashcards!',
        _nextInstanceOfDay(day, hour, minute),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // Fall back to inexact scheduling if exact alarm permission is denied
      await _notifications.zonedSchedule(
        day,
        'Study Reminder',
        'Time to review your flashcards!',
        _nextInstanceOfDay(day, hour, minute),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'study_reminders',
      'Study Reminders',
      channelDescription: 'Notifications for study reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool> arePermissionsGranted() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      return granted ?? false;
    }

    return true; // Assume granted on iOS if we get here
  }
}

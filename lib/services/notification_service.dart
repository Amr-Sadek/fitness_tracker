import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Notification IDs
  // ---------------------------------------------------------------------------

  static const int _waterBaseId = 1000;
  static const int _activityReminderId = 2000;
  static const int _dailyGoalReminderId = 3000;

  static const int _waterGoalReachedId = 4000;
  static const int _stepsGoalReachedId = 4001;

  // ---------------------------------------------------------------------------
  // SharedPreferences keys
  // ---------------------------------------------------------------------------

  static const String _notificationsEnabledKey = 'notifications_enabled';

  static const String _waterRemindersEnabledKey = 'water_reminders_enabled';

  static const String _activityRemindersEnabledKey =
      'activity_reminders_enabled';

  static const String _goalReminderEnabledKey = 'goal_reminder_enabled';

  static const String _waterStartHourKey = 'water_reminder_start_hour';

  static const String _waterStartMinuteKey = 'water_reminder_start_minute';

  static const String _waterEndHourKey = 'water_reminder_end_hour';

  static const String _waterEndMinuteKey = 'water_reminder_end_minute';

  static const String _waterIntervalKey = 'water_reminder_interval';

  static const String _activityHourKey = 'activity_reminder_hour';

  static const String _activityMinuteKey = 'activity_reminder_minute';

  static const String _goalHourKey = 'goal_reminder_hour';

  static const String _goalMinuteKey = 'goal_reminder_minute';

  // ---------------------------------------------------------------------------
  // Default settings
  // ---------------------------------------------------------------------------

  static const bool defaultNotificationsEnabled = true;

  static const bool defaultWaterRemindersEnabled = true;

  static const bool defaultActivityRemindersEnabled = true;

  static const bool defaultGoalReminderEnabled = true;

  static const int defaultWaterStartHour = 9;

  static const int defaultWaterStartMinute = 0;

  static const int defaultWaterEndHour = 22;

  static const int defaultWaterEndMinute = 0;

  static const int defaultWaterIntervalHours = 2;

  static const int defaultActivityHour = 17;

  static const int defaultActivityMinute = 0;

  static const int defaultGoalHour = 20;

  static const int defaultGoalMinute = 0;

  // ---------------------------------------------------------------------------
  // Initialize
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      tz.initializeTimeZones();

      await _setDeviceTimeZone();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const settings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(settings: settings);

      _initialized = true;

      debugPrint('Notification service initialized.');
    } catch (error) {
      debugPrint('Notification initialization error: $error');

      rethrow;
    }
  }

  Future<void> _setDeviceTimeZone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();

      final location = tz.getLocation(timezoneInfo.identifier);

      tz.setLocalLocation(location);

      debugPrint('Device timezone: ${timezoneInfo.identifier}');
    } catch (error) {
      debugPrint('Timezone setup error: $error');

      // Fallback to the timezone package default.
      // Scheduling can still continue.
    }
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<bool> requestPermission() async {
    await initialize();

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await androidImplementation
        ?.requestNotificationsPermission();

    return granted ?? false;
  }

  Future<bool> areNotificationsEnabled() async {
    await initialize();

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final enabled = await androidImplementation?.areNotificationsEnabled();

    return enabled ?? false;
  }

  // ---------------------------------------------------------------------------
  // Main notification setup
  // ---------------------------------------------------------------------------

  Future<void> scheduleAllNotifications() async {
    await initialize();

    final preferences = await SharedPreferences.getInstance();

    final masterEnabled =
        preferences.getBool(_notificationsEnabledKey) ??
        defaultNotificationsEnabled;

    if (!masterEnabled) {
      await cancelAllReminders();
      return;
    }

    final waterEnabled =
        preferences.getBool(_waterRemindersEnabledKey) ??
        defaultWaterRemindersEnabled;

    final activityEnabled =
        preferences.getBool(_activityRemindersEnabledKey) ??
        defaultActivityRemindersEnabled;

    final goalEnabled =
        preferences.getBool(_goalReminderEnabledKey) ??
        defaultGoalReminderEnabled;

    if (waterEnabled) {
      await scheduleWaterReminders();
    } else {
      await cancelWaterReminders();
    }

    if (activityEnabled) {
      await scheduleActivityReminder();
    } else {
      await cancelActivityReminder();
    }

    if (goalEnabled) {
      await scheduleDailyGoalReminder();
    } else {
      await cancelDailyGoalReminder();
    }
  }

  // ---------------------------------------------------------------------------
  // Water reminders
  // ---------------------------------------------------------------------------

  Future<void> scheduleWaterReminders({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? intervalHours,
  }) async {
    await initialize();

    final preferences = await SharedPreferences.getInstance();

    final masterEnabled =
        preferences.getBool(_notificationsEnabledKey) ??
        defaultNotificationsEnabled;

    final enabled =
        preferences.getBool(_waterRemindersEnabledKey) ??
        defaultWaterRemindersEnabled;

    if (!masterEnabled || !enabled) {
      await cancelWaterReminders();
      return;
    }

    final startH =
        startHour ??
        preferences.getInt(_waterStartHourKey) ??
        defaultWaterStartHour;

    final startM =
        startMinute ??
        preferences.getInt(_waterStartMinuteKey) ??
        defaultWaterStartMinute;

    final endH =
        endHour ?? preferences.getInt(_waterEndHourKey) ?? defaultWaterEndHour;

    final endM =
        endMinute ??
        preferences.getInt(_waterEndMinuteKey) ??
        defaultWaterEndMinute;

    final interval =
        intervalHours ??
        preferences.getInt(_waterIntervalKey) ??
        defaultWaterIntervalHours;

    if (interval <= 0) {
      return;
    }

    await cancelWaterReminders();

    final startMinutes = startH * 60 + startM;

    final endMinutes = endH * 60 + endM;

    if (endMinutes <= startMinutes) {
      debugPrint('Invalid water reminder time range.');

      return;
    }

    int notificationIndex = 0;

    for (
      int minutes = startMinutes;
      minutes <= endMinutes;
      minutes += interval * 60
    ) {
      final hour = minutes ~/ 60;

      final minute = minutes % 60;

      await _scheduleDailyNotification(
        id: _waterBaseId + notificationIndex,
        title: 'Time to drink water 💧',
        body: _waterReminderMessage(hour),
        hour: hour,
        minute: minute,
        channelId: 'water_reminders',
        channelName: 'Water Reminders',
        channelDescription: 'Reminders to drink water during the day.',
      );

      notificationIndex++;
    }

    await preferences.setInt(_waterStartHourKey, startH);

    await preferences.setInt(_waterStartMinuteKey, startM);

    await preferences.setInt(_waterEndHourKey, endH);

    await preferences.setInt(_waterEndMinuteKey, endM);

    await preferences.setInt(_waterIntervalKey, interval);

    debugPrint('Water reminders scheduled: $notificationIndex');
  }

  String _waterReminderMessage(int hour) {
    if (hour < 12) {
      return 'Good morning 💧 Start your day with some water.';
    }

    if (hour < 17) {
      return 'Keep yourself hydrated and stay on track with your daily goal.';
    }

    return 'Don’t forget to stay hydrated before the day ends. 💧';
  }

  Future<void> cancelWaterReminders() async {
    await initialize();

    for (int i = 0; i < 20; i++) {
      await _notifications.cancel(id: _waterBaseId + i);
    }
  }

  // ---------------------------------------------------------------------------
  // Activity reminder
  // ---------------------------------------------------------------------------

  Future<void> scheduleActivityReminder({int? hour, int? minute}) async {
    await initialize();

    final preferences = await SharedPreferences.getInstance();

    final masterEnabled =
        preferences.getBool(_notificationsEnabledKey) ??
        defaultNotificationsEnabled;

    final enabled =
        preferences.getBool(_activityRemindersEnabledKey) ??
        defaultActivityRemindersEnabled;

    if (!masterEnabled || !enabled) {
      await cancelActivityReminder();
      return;
    }

    final reminderHour =
        hour ?? preferences.getInt(_activityHourKey) ?? defaultActivityHour;

    final reminderMinute =
        minute ??
        preferences.getInt(_activityMinuteKey) ??
        defaultActivityMinute;

    await _scheduleDailyNotification(
      id: _activityReminderId,
      title: 'Time to move 🚶',
      body: 'Take a short walk or stretch for a few minutes.',
      hour: reminderHour,
      minute: reminderMinute,
      channelId: 'activity_reminders',
      channelName: 'Activity Reminders',
      channelDescription: 'Reminders to move and stay active.',
    );

    await preferences.setInt(_activityHourKey, reminderHour);

    await preferences.setInt(_activityMinuteKey, reminderMinute);
  }

  Future<void> cancelActivityReminder() async {
    await initialize();

    await _notifications.cancel(id: _activityReminderId);
  }

  // ---------------------------------------------------------------------------
  // Daily goal reminder
  // ---------------------------------------------------------------------------

  Future<void> scheduleDailyGoalReminder({int? hour, int? minute}) async {
    await initialize();

    final preferences = await SharedPreferences.getInstance();

    final masterEnabled =
        preferences.getBool(_notificationsEnabledKey) ??
        defaultNotificationsEnabled;

    final enabled =
        preferences.getBool(_goalReminderEnabledKey) ??
        defaultGoalReminderEnabled;

    if (!masterEnabled || !enabled) {
      await cancelDailyGoalReminder();
      return;
    }

    final reminderHour =
        hour ?? preferences.getInt(_goalHourKey) ?? defaultGoalHour;

    final reminderMinute =
        minute ?? preferences.getInt(_goalMinuteKey) ?? defaultGoalMinute;

    await _scheduleDailyNotification(
      id: _dailyGoalReminderId,
      title: 'Keep going! 🎯',
      body: 'Check your progress and finish today’s goals.',
      hour: reminderHour,
      minute: reminderMinute,
      channelId: 'goal_reminders',
      channelName: 'Goal Reminders',
      channelDescription: 'Reminders to complete your daily fitness goals.',
    );

    await preferences.setInt(_goalHourKey, reminderHour);

    await preferences.setInt(_goalMinuteKey, reminderMinute);
  }

  Future<void> cancelDailyGoalReminder() async {
    await initialize();

    await _notifications.cancel(id: _dailyGoalReminderId);
  }

  // ---------------------------------------------------------------------------
  // Generic daily scheduling
  // ---------------------------------------------------------------------------

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ---------------------------------------------------------------------------
  // Immediate goal notifications
  // ---------------------------------------------------------------------------

  Future<void> showWaterGoalReached() async {
    await initialize();

    await _notifications.show(
      id: _waterGoalReachedId,
      title: 'Hydration goal completed! 💧',
      body: 'Great job! You reached your water goal for today.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_completed',
          'Goal Completed',
          channelDescription: 'Notifications when daily goals are completed.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    // Stop further water reminders for now.
    await cancelWaterReminders();
  }

  Future<void> showStepsGoalReached() async {
    await initialize();

    await _notifications.show(
      id: _stepsGoalReachedId,
      title: 'Step goal completed! 👟',
      body: 'Great job! You reached your steps goal for today.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_completed',
          'Goal Completed',
          channelDescription: 'Notifications when daily goals are completed.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Test notification
  // ---------------------------------------------------------------------------

  Future<void> showTestNotification() async {
    await initialize();

    await _notifications.show(
      id: 9999,
      title: 'Fitness Tracker 🔔',
      body: 'Notifications are working correctly.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_notifications',
          'Test Notifications',
          channelDescription: 'Test notifications for Fitness Tracker.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel everything
  // ---------------------------------------------------------------------------

  Future<void> cancelAllReminders() async {
    await initialize();

    await cancelWaterReminders();
    await cancelActivityReminder();
    await cancelDailyGoalReminder();
  }

  // ---------------------------------------------------------------------------
  // Settings helpers
  // ---------------------------------------------------------------------------

  Future<void> setNotificationsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      await scheduleAllNotifications();
    } else {
      await cancelAllReminders();
    }
  }

  Future<void> setWaterRemindersEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_waterRemindersEnabledKey, enabled);

    if (enabled) {
      await scheduleWaterReminders();
    } else {
      await cancelWaterReminders();
    }
  }

  Future<void> setActivityRemindersEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_activityRemindersEnabledKey, enabled);

    if (enabled) {
      await scheduleActivityReminder();
    } else {
      await cancelActivityReminder();
    }
  }

  Future<void> setGoalReminderEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_goalReminderEnabledKey, enabled);

    if (enabled) {
      await scheduleDailyGoalReminder();
    } else {
      await cancelDailyGoalReminder();
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final preferences = await SharedPreferences.getInstance();

    return {
      'notificationsEnabled':
          preferences.getBool(_notificationsEnabledKey) ??
          defaultNotificationsEnabled,

      'waterRemindersEnabled':
          preferences.getBool(_waterRemindersEnabledKey) ??
          defaultWaterRemindersEnabled,

      'activityRemindersEnabled':
          preferences.getBool(_activityRemindersEnabledKey) ??
          defaultActivityRemindersEnabled,

      'goalReminderEnabled':
          preferences.getBool(_goalReminderEnabledKey) ??
          defaultGoalReminderEnabled,

      'waterStartHour':
          preferences.getInt(_waterStartHourKey) ?? defaultWaterStartHour,

      'waterStartMinute':
          preferences.getInt(_waterStartMinuteKey) ?? defaultWaterStartMinute,

      'waterEndHour':
          preferences.getInt(_waterEndHourKey) ?? defaultWaterEndHour,

      'waterEndMinute':
          preferences.getInt(_waterEndMinuteKey) ?? defaultWaterEndMinute,

      'waterInterval':
          preferences.getInt(_waterIntervalKey) ?? defaultWaterIntervalHours,

      'activityHour':
          preferences.getInt(_activityHourKey) ?? defaultActivityHour,

      'activityMinute':
          preferences.getInt(_activityMinuteKey) ?? defaultActivityMinute,

      'goalHour': preferences.getInt(_goalHourKey) ?? defaultGoalHour,

      'goalMinute': preferences.getInt(_goalMinuteKey) ?? defaultGoalMinute,
    };
  }
}

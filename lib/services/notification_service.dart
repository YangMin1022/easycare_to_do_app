// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../task_item.dart';
import 'settings_service.dart';

// Split timezone imports to avoid analyzer confusion
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// This service is responsible for requesting OS permissions, accurately calculating 
// timezone-aware firing times, and managing the queue of scheduled alarms. It includes 
// state-syncing logic to prevent "ghost notifications" (alarms that ring for 
// tasks that were already deleted).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification system
  Future<void> init() async {
    if (_isInitialized) return;
    // Initialize timezone data and set local timezone
    tz_data.initializeTimeZones();

    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      debugPrint("Error setting location: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    // Configure Android specific settings (App notification icon)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    // Configure iOS specific settings (requesting permissions, set false cause don't have IOS support yet)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    // Initialize the plugin with settings and a callback for when notifications are tapped
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap (open app)
        debugPrint("Notification clicked with payload: ${response.payload}");
      },
    );

    _isInitialized = true;
  }
  // Requests necessary permissions on Android 13+ for notifications and exact alarms.
  Future<bool> requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotifications =
          await androidImplementation?.requestNotificationsPermission();

      final bool? grantedExactAlarms =
          await androidImplementation?.requestExactAlarmsPermission();

      return (grantedNotifications ?? false) && (grantedExactAlarms ?? true);
    }
    return true;
  }
 // Checks if the app has the necessary permissions to schedule notifications.
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? enabled = await androidImplementation?.areNotificationsEnabled();
      return enabled ?? false;
    }
    return true; 
  }

  /// Cleans up any notifications that are no longer valid, 
  /// past their due date, or belong to deleted/completed tasks.
  Future<void> cleanUpOutdatedNotifications(List<TaskItem> allTasks) async {
    // 1. Get all currently pending notifications from the OS
    final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    
    // 2. Build a Set of IDs that are valid and still in the future
    final now = DateTime.now();
    final validIds = <int>{};
    
    for (final task in allTasks) {
      // Skip completed, deleted, or unscheduled tasks
      if (task.completed || task.notificationId == null) continue;
      
      // If the main due time is in the future, its ID is valid
      if (task.due.isAfter(now)) {
        validIds.add(task.notificationId!);
      }
      
      // If the reminder time is in the future, its secondary ID is valid
      if (task.reminderTime != null && task.reminderTime!.isAfter(now)) {
        validIds.add(task.notificationId! + 1);
      }
    }
    
    // 3. Compare and cancel any ghost/outdated notifications
    int cancelledCount = 0;
    for (final pending in pendingNotifications) {
      if (!validIds.contains(pending.id)) {
        await cancelNotification(pending.id);
        cancelledCount++;
        debugPrint('Cancelled outdated notification: id=${pending.id} title="${pending.title}"');
      }
    }
    
    debugPrint('Cleanup complete. Cancelled $cancelledCount old notifications.');
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // 1. Create Timezone-aware date
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final nowTime = tz.TZDateTime.now(tz.local);

    // --- DEBUGGING ---
    print("⏰ SCHEDULING CHECK:");
    print("   Now: $nowTime");
    print("   Set: $tzTime");

    if (tzTime.isBefore(nowTime)) {
      print("⚠️ Time is in the past. Notification will not fire.");
      return;
    }
    // Check local settings before scheduling
    if (!SettingsService().notificationsEnabled) {
      print("⚠️ Notifications disabled in settings. Skipping schedule.");
      return;
    }
    // -----------------

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel_v2',
      'Reminders',
      channelDescription: 'Notifications for tasks',
      importance: Importance.max,
      priority: Priority.high,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      icon: 'ic_notification',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        platformDetails,
        // REMOVED: uiLocalNotificationDateInterpretation (Not in your version)
        
        // KEEP: This is required based on your source code
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      print("✅ SUCCESS: Notification Scheduled for $tzTime");
    } catch (e) {
      print("❌ ERROR: $e");
    }
  }

  // Returns the pending notification requests so tests/UI can inspect them.
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Restores notifications for all pending, future tasks
  Future<void> restoreAllNotifications(List<TaskItem> tasks) async {
    final now = DateTime.now();

    for (final task in tasks) {
      // Skip completed tasks or tasks without IDs
      if (task.completed || task.notificationId == null) continue;

      // Re-schedule main due time alert
      if (task.due.isAfter(now)) {
        await scheduleReminder(
          id: task.notificationId!,
          title: "Task Due: ${task.title}",
          body: "It is time for your task!",
          scheduledTime: task.due,
          payload: task.notificationId.toString(),
        );
      }

      // Re-schedule the "reminder before" alert
      if (task.reminderTime != null && task.reminderTime!.isAfter(now)) {
        await scheduleReminder(
          id: task.notificationId! + 1,
          title: "Reminder: ${task.title}",
          body: "Your task is due soon!",
          scheduledTime: task.reminderTime!,
          payload: (task.notificationId! + 1).toString(),
        );
      }
    }
  }
  
  /// Debug helper: logs pending requests to console.
  Future<void> debugPending() async {
    try {
      final pending = await getPendingNotificationRequests();
      debugPrint('Pending notifications count: ${pending.length}');
      for (final p in pending) {
        debugPrint('pending id=${p.id} title=${p.title} body=${p.body} payload=${p.payload}') ;
      }
    } catch (e) {
      debugPrint('Error fetching pending notifications: $e');
    }
  }
  // For testing/demo: shows an instant notification (not scheduled) to verify the system is working.
  Future<void> showInstantNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel_v2',
      'Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      platformDetails,
    );
  }
  // Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  // Cancels all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
// ignore_for_file: avoid_print, library_prefixes

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

class PushNotifications {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize the local notifications plugin and request necessary permissions.
  static Future<void> init() async {
    // Initialize timezone data
    tzData.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Initialize plugin and handle notification tap events
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    // Request permissions for notifications and exact alarms
    await _requestNotificationPermissions();
    await requestExactAlarmPermission(); // Call the requestExactAlarmPermission method
  }

  static Future<void> requestExactAlarmPermission() async {
    // Check if the permission is already granted
    if (await Permission.scheduleExactAlarm.isDenied) {
      // Request the permission from the user
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isGranted) {
        print("Exact alarm permission granted.");
      } else {
        print("Exact alarm permission denied.");
      }
    } else {
      print("Exact alarm permission already granted.");
    }
  }

  /// Send an immediate notification to the user.
  static Future<void> sendImmediateNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'test_channel', // Channel ID
      'Test Channel', // Channel Name
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification immediately
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique notification ID
      title,
      body,
      notificationDetails,
      payload: 'Immediate Notification Test', // Optional payload
    );

    print("Immediate notification sent: $title - $body");
  }

  /// Schedule a local notification for a specific time.
  static Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'test_channel', // Channel ID
        'Test Channel', // Channel Name
        channelDescription: 'Channel for testing notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Convert DateTime to a local `TZDateTime`
      final tz.TZDateTime localTime =
      tz.TZDateTime.from(scheduledTime, tz.local);

      // Schedule the notification using zonedSchedule without recurring components
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique notification ID
        title,
        body,
        localTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Ensure it works in Doze mode
      );

      print("One-time notification scheduled for $scheduledTime");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }


  /// Request notification and exact alarm permissions.
  static Future<void> _requestNotificationPermissions() async {
    // Request notification permission
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        print("Notification permission denied.");
        return;
      }
    } else {
      print("Notification permission already granted.");
    }

    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      if (!alarmStatus.isGranted) {
        print("Exact alarm permission denied.");
      } else {
        print("Exact alarm permission granted.");
      }
    } else {
      print("Exact alarm permission already granted.");
    }
  }

  /// Handle notification tap events.
  static void onNotificationTap(NotificationResponse notificationResponse) {
    print("Notification tapped with payload: ${notificationResponse.payload}");
  }
}

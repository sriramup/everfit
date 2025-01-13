import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// A service for managing local notifications, including scheduling daily reminders.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initializes the notification service.
  /// - This method sets up platform-specific settings, such as iOS notification configuration.
  Future<void> initialize() async {
    // iOS-specific initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    // Cross-platform initialization settings
    const InitializationSettings settings = InitializationSettings(
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  /// Requests notification permissions from the user.
  /// - If notifications are denied or restricted, a permission request dialog is shown.
  Future<void> requestPermission() async {
    final status = await Permission.notification.status;

    // Request permission if not already granted
    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  }

  /// Schedules a daily notification.
  ///
  /// - Parameters:
  ///   - [title]: The title of the notification.
  ///   - [body]: The body text of the notification.
  ///   - [id]: A unique identifier for the notification.
  /// - Example: Schedules a notification 5 seconds from the current time.
  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    // Initialize time zones
    tz.initializeTimeZones();

    await _notificationsPlugin.zonedSchedule(
      id, // Notification ID
      title, // Notification title
      body, // Notification body
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // Notification time
      const NotificationDetails(
        iOS: DarwinNotificationDetails(), // iOS-specific notification settings
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime, // Interpret the date/time absolutely
      androidScheduleMode: AndroidScheduleMode.exact, // Android scheduling mode
    );
  }
}
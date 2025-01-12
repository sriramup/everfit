import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings settings =
    InitializationSettings(iOS: iosSettings);

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> requestPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  }

  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    tz.initializeTimeZones();

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), // Example
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }
}

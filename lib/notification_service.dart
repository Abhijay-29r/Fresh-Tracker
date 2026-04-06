import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // The official name of our plugin variable
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // try-catch prevents the browser from crashing since it lacks Android hardware
    try {
      await _notificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print("Notification Init: Running in browser (Native features disabled)");
    }
  }

  static Future<void> scheduleExpiryWarning({
    required int id,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    // 1. Warning 3 days before (Set to 9:00 AM so it doesn't wake you up at night)
    final threeDaysBefore =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day - 3, 9, 0);
    if (threeDaysBefore.isAfter(DateTime.now())) {
      await _schedule(
          id, "Expiring Soon", "$itemName expires in 3 days!", threeDaysBefore);
    }

    // 2. Warning ON the day (at 9:00 AM)
    final dayOf =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day, 9, 0);
    if (dayOf.isAfter(DateTime.now())) {
      await _schedule(
          id + 1, "Expiry Alert", "$itemName expires TODAY!", dayOf);
    }
  }

  // NEW: Call this from HomeScreen when an item is Eaten or Wasted
  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id); // Cancels the 3-day warning
      await _notificationsPlugin.cancel(id + 1); // Cancels the same-day warning
    } catch (e) {
      print("Cancel Notification: Ignored on web");
    }
  }

  // Helper to handle the actual scheduling
  static Future<void> _schedule(
      int id, String title, String body, DateTime date) async {
    try {
      // Changed from _notifications to _notificationsPlugin to fix the error
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(date, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_channel',
            'Expirations',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print(
          "Scheduling skipped: Running in browser (Native features disabled)");
    }
  }
}

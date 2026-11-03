import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/booking_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> scheduleBookingReminder(BookingModel booking) async {
    try {
      final dateParts = booking.bookingDate.split('-');
      final timeParts = booking.startTime.split(':');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      final reminderDateTime =
          appointmentDateTime.subtract(const Duration(hours: 1));

      // If scheduled time is already in the past, do not schedule
      if (reminderDateTime.isBefore(DateTime.now())) return;

      final tzDateTime = tz.TZDateTime.from(reminderDateTime, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'bookease_reminders_channel',
        'Booking Reminders',
        channelDescription: 'Alerts you 1 hour before your service appointment',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails details =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        booking.id.hashCode,
        'Upcoming Booking Reminder',
        'Your appointment for ${booking.serviceName} is in 1 hour (${booking.startTime}).',
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Graceful fallback for web or unsupported targets
    }
  }

  Future<void> cancelReminder(String bookingId) async {
    try {
      await _notificationsPlugin.cancel(bookingId.hashCode);
    } catch (_) {}
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/services/log_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _log = LogService();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok')); // Vietnam timezone

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  /// Request notification permissions (required for Android 13+)
  Future<bool> _requestPermissions() async {
    bool granted = false;
    
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      granted = result ?? false;
    }

    final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }
    
    return granted;
  }

  /// Check if notification permissions are granted
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final result = await androidPlugin.areNotificationsEnabled();
      return result ?? false;
    }

    // For iOS, we can't reliably check, assume true if initialized
    return _initialized;
  }

  /// Request permissions again (for when user wants to enable after denying)
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - you can navigate to specific screen here
    _log.log('Notification tapped: ${response.payload}', level: LogLevel.info);
  }

  /// Schedule notifications for a class (1 hour, 30 min, 15 min before)
  Future<void> scheduleClassNotifications(
    StudentCourseSubject course,
    DateTime classDateTime,
    int weekDay,
    String timeSlot,
  ) async {
    if (!_initialized) await initialize();

    // Only schedule if the class is in the future
    final now = DateTime.now();
    if (classDateTime.isBefore(now)) return;

    final subjectName = course.courseName;
    final baseId = '${course.id}_${weekDay}_${classDateTime.millisecondsSinceEpoch}'.hashCode;

    // 1 hour before
    final oneHourBefore = classDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Sắp đến giờ học!',
        body: 'Còn 1 giờ nữa là đến giờ học môn: $subjectName!',
        scheduledDate: oneHourBefore,
        payload: 'class_${course.id}_1h',
      );
    }

    // 30 minutes before
    final thirtyMinBefore = classDateTime.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Sắp đến giờ học!',
        body: 'Còn 30 phút nữa là đến giờ học môn: $subjectName!',
        scheduledDate: thirtyMinBefore,
        payload: 'class_${course.id}_30m',
      );
    }

    // 15 minutes before
    final fifteenMinBefore = classDateTime.subtract(const Duration(minutes: 15));
    if (fifteenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: 'Sắp đến giờ học!',
        body: 'Còn 15 phút nữa là đến giờ học môn: $subjectName!',
        scheduledDate: fifteenMinBefore,
        payload: 'class_${course.id}_15m',
      );
    }
  }

  /// Schedule notifications for an exam (1 hour, 30 min, 15 min before)
  Future<void> scheduleExamNotifications(
    StudentExamRoom examRoom,
    DateTime examDateTime,
  ) async {
    if (!_initialized) await initialize();

    // Only schedule if the exam is in the future
    final now = DateTime.now();
    if (examDateTime.isBefore(now)) return;

    final subjectName = examRoom.subjectName;
    final examCode = examRoom.examCode ?? '';
    final baseId = '${examRoom.id}_${examDateTime.millisecondsSinceEpoch}'.hashCode;

    // 1 hour before
    final oneHourBefore = examDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Sắp đến giờ thi!',
        body: 'Còn 1 giờ nữa là đến giờ thi môn: $subjectName${examCode.isNotEmpty ? ' ($examCode)' : ''}!',
        scheduledDate: oneHourBefore,
        payload: 'exam_${examRoom.id}_1h',
      );
    }

    // 30 minutes before
    final thirtyMinBefore = examDateTime.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Sắp đến giờ thi!',
        body: 'Còn 30 phút nữa là đến giờ thi môn: $subjectName${examCode.isNotEmpty ? ' ($examCode)' : ''}!',
        scheduledDate: thirtyMinBefore,
        payload: 'exam_${examRoom.id}_30m',
      );
    }

    // 15 minutes before
    final fifteenMinBefore = examDateTime.subtract(const Duration(minutes: 15));
    if (fifteenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: 'Sắp đến giờ thi!',
        body: 'Còn 15 phút nữa là đến giờ thi môn: $subjectName${examCode.isNotEmpty ? ' ($examCode)' : ''}!',
        scheduledDate: fifteenMinBefore,
        payload: 'exam_${examRoom.id}_15m',
      );
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Validate the scheduled date to prevent year 32099 bug
    final now = DateTime.now();
    final maxYear = now.year + 10; // Maximum 10 years in future
    
    if (scheduledDate.year > maxYear || scheduledDate.year < 2020) {
      _log.log('Invalid scheduled date: $scheduledDate (year: ${scheduledDate.year})', level: LogLevel.warning);
      _log.log('Notification NOT scheduled - date out of valid range', level: LogLevel.warning);
      return;
    }
    
    // Don't schedule if already passed
    if (scheduledDate.isBefore(now)) {
      _log.log('Scheduled date is in the past: $scheduledDate', level: LogLevel.debug);
      return;
    }
    
    // Log notification scheduling
    _log.log('Scheduling notification: $title', level: LogLevel.info);
    _log.log('Scheduled for: $scheduledDate (in ${scheduledDate.difference(now).inMinutes} minutes)', level: LogLevel.debug);
    
    const androidDetails = AndroidNotificationDetails(
      'class_exam_reminders',
      'Nhắc nhở lịch học và lịch thi',
      channelDescription: 'Thông báo nhắc nhở trước giờ học và giờ thi',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    _log.log('TZ Scheduled date: $tzScheduledDate', level: LogLevel.debug);
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    
    _log.log('Notification scheduled successfully', level: LogLevel.success);
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'class_exam_reminders',
      'Nhắc nhở lịch học và lịch thi',
      channelDescription: 'Thông báo nhắc nhở trước giờ học và giờ thi',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }
}

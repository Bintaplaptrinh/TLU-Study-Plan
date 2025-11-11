import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/services/notification_service.dart';
import 'package:tlustudy_planner/services/log_service.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();
  static final _log = LogService();

  /// Schedule notifications for all classes in the current week
  static Future<void> scheduleWeekClassNotifications({
    required List<StudentCourseSubject> courses,
    required Map<int, CourseHour> courseHours,
    required DateTime weekStartDate,
    required DateTime semesterStartDate,
  }) async {
    _log.log('scheduleWeekClassNotifications called', level: LogLevel.info);
    _log.log('Courses: ${courses.length}', level: LogLevel.debug);
    _log.log('Week start: $weekStartDate', level: LogLevel.debug);
    _log.log('Semester start: $semesterStartDate', level: LogLevel.debug);
    
    final now = DateTime.now();

    for (final course in courses) {
      // Check if course is active during this week
      if (!course.isActiveOn(weekStartDate, semesterStartDate)) {
        _log.log('Course ${course.courseName} not active this week', level: LogLevel.debug);
        continue;
      }

      _log.log('Course ${course.courseName} is active', level: LogLevel.debug);
      
      // Get day of week from API (2=Monday, 3=Tuesday, ..., 8=Sunday)
      // Convert to 0-based (0=Monday, 1=Tuesday, ..., 6=Sunday)
      final apiDayOfWeek = course.dayOfWeek;
      final dayOfWeek = apiDayOfWeek - 2; // Convert from 2-based to 0-based
      _log.log('Day of week from API: $apiDayOfWeek (2=Mon, 3=Tue, ..., 8=Sun)', level: LogLevel.debug);
      _log.log('Converted to 0-based: $dayOfWeek (0=Mon, 1=Tue, ..., 6=Sun)', level: LogLevel.debug);

      // Calculate the actual date for this class in the week
      final classDate = weekStartDate.add(Duration(days: dayOfWeek));
      _log.log('Week start date: $weekStartDate', level: LogLevel.debug);
      _log.log('Adding $dayOfWeek days', level: LogLevel.debug);
      _log.log('Calculated class date: $classDate', level: LogLevel.debug);
      _log.log('Class date day of week: ${classDate.weekday} (1=Mon, 7=Sun in Dart)', level: LogLevel.debug);

      // Skip if class date is in the past
      if (classDate.isBefore(now) && !_isSameDay(classDate, now)) {
        _log.log('Class date is in the past', level: LogLevel.debug);
        continue;
      }

      // Get start hour details
      final startCourseHour = courseHours[course.startCourseHour];
      if (startCourseHour == null) {
        _log.log('No start course hour found for ID: ${course.startCourseHour}', level: LogLevel.warning);
        continue;
      }

      // Get end hour details  
      final endCourseHour = courseHours[course.endCourseHour];
      if (endCourseHour == null) {
        _log.log('No end course hour found for ID: ${course.endCourseHour}', level: LogLevel.warning);
        continue;
      }

      // Parse start time from startString (e.g., "07:00")
      final startParts = startCourseHour.startString.split(':');
      if (startParts.length != 2) {
        _log.log('Invalid start time format: ${startCourseHour.startString}', level: LogLevel.warning);
        continue;
      }

      final hour = int.tryParse(startParts[0]);
      final minute = int.tryParse(startParts[1]);
      if (hour == null || minute == null) {
        _log.log('Could not parse hour/minute from: ${startCourseHour.startString}', level: LogLevel.warning);
        continue;
      }

      _log.log('Start time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}', level: LogLevel.debug);

      // Create the full datetime for the class
      final classDateTime = DateTime(
        classDate.year,
        classDate.month,
        classDate.day,
        hour,
        minute,
      );
      
      _log.log('Class DateTime: $classDateTime', level: LogLevel.debug);
      _log.log('Current time: $now', level: LogLevel.debug);
      _log.log('Is in future: ${classDateTime.isAfter(now)}', level: LogLevel.debug);
      
      // Validate year to prevent 32099 bug
      if (classDateTime.year > now.year + 10 || classDateTime.year < 2020) {
        _log.log('Invalid class date year: ${classDateTime.year} - SKIPPING', level: LogLevel.warning);
        continue;
      }

      // Format time slot string using the string fields
      final timeSlot = '${startCourseHour.startString} - ${endCourseHour.endString}';

      // Schedule notifications
      await _notificationService.scheduleClassNotifications(
        course,
        classDateTime,
        dayOfWeek + 2, // Convert to 2-based (2=Monday, 3=Tuesday, etc.)
        timeSlot,
      );
    }
  }

  /// Schedule notifications for upcoming exams
  static Future<void> scheduleExamNotifications({
    required List<StudentExamRoom> examRooms,
  }) async {
    _log.log('scheduleExamNotifications called with ${examRooms.length} exam rooms', level: LogLevel.info);
    
    for (final examRoom in examRooms) {
      final examDetail = examRoom.examRoom;
      if (examDetail == null) {
        _log.log('Exam room ${examRoom.id} has no examRoom detail', level: LogLevel.warning);
        continue;
      }

      // Get exam date and time
      final examDate = examDetail.examDate;
      final examHour = examDetail.examHour;

      if (examDate == null || examHour == null) {
        _log.log('Exam ${examRoom.subjectName}: missing date or hour', level: LogLevel.warning);
        continue;
      }

      // Convert timestamp to DateTime
      final date = DateTime.fromMillisecondsSinceEpoch(examDate);
      _log.log('Exam: ${examRoom.subjectName}', level: LogLevel.debug);
      _log.log('Date from timestamp: $date', level: LogLevel.debug);

      // Parse exam hour start time from startString (e.g., "07:00")
      final startString = examHour.startString;
      if (startString == null) {
        _log.log('No startString in examHour', level: LogLevel.warning);
        continue;
      }
      
      _log.log('Start time string: $startString', level: LogLevel.debug);

      final startParts = startString.split(':');
      if (startParts.length != 2) {
        _log.log('Invalid start time format: $startString', level: LogLevel.warning);
        continue;
      }

      final hour = int.tryParse(startParts[0]);
      final minute = int.tryParse(startParts[1]);
      if (hour == null || minute == null) {
        _log.log('Could not parse hour/minute from: $startString', level: LogLevel.warning);
        continue;
      }

      // Create full exam datetime
      final examDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      
      _log.log('Exam DateTime: $examDateTime', level: LogLevel.debug);
      _log.log('Current time: ${DateTime.now()}', level: LogLevel.debug);
      _log.log('Is in future: ${examDateTime.isAfter(DateTime.now())}', level: LogLevel.debug);
      
      // Validate year to prevent invalid dates
      final now = DateTime.now();
      if (examDateTime.year > now.year + 10 || examDateTime.year < 2020) {
        _log.log('Invalid exam date year: ${examDateTime.year} - SKIPPING', level: LogLevel.warning);
        continue;
      }

      // Schedule notifications
      await _notificationService.scheduleExamNotifications(
        examRoom,
        examDateTime,
      );
    }
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  /// Get count of pending notifications
  static Future<int> getPendingNotificationCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }
}

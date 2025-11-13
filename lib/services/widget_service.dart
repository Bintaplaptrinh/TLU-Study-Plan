import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/services/database_helper.dart';

/// Service for managing home screen widget
class WidgetService {
  static const String androidProviderName = 'TodayScheduleWidgetProvider';
  static const String iOSWidgetKind = 'TodayScheduleWidget';

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Update widget with today's schedule
  Future<void> updateWidget({
    List<StudentCourseSubject>? courses,
    int? semesterId,
  }) async {
    try {
      if (kDebugMode) {
        print('📱 Updating home screen widget...');
      }

      // If courses not provided, fetch from database
      courses ??= await _getTodaySchedule(semesterId);

      if (courses == null || courses.isEmpty) {
        await _updateWidgetWithEmptyState();
        return;
      }

      // Sort courses by start hour
      courses.sort((a, b) {
        return a.startCourseHour.compareTo(b.startCourseHour);
      });

      // Prepare widget data
      final now = DateTime.now();
      final weekdayNames = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
      final weekdayName = weekdayNames[now.weekday];
      final todayDate = '$weekdayName, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final courseCount = courses.length;

      // Build courses text (show max 5 courses)
      final coursesText = courses.take(5).map((course) {
        final startHour = course.startCourseHour;
        final endHour = course.endCourseHour;
        final room = course.room.isNotEmpty ? course.room : 'N/A';
        final courseName = course.courseName;
        
        return 'Tiết $startHour-$endHour: $courseName\n📍 $room';
      }).join('\n\n');

      // Save widget data
      await HomeWidget.saveWidgetData<String>('widget_title', 'Lịch học hôm nay');
      await HomeWidget.saveWidgetData<String>('widget_date', todayDate);
      await HomeWidget.saveWidgetData<int>('course_count', courseCount);
      await HomeWidget.saveWidgetData<String>('courses_text', coursesText);
      await HomeWidget.saveWidgetData<String>('last_update', DateTime.now().toIso8601String());

      // Update widget UI
      await HomeWidget.updateWidget(
        androidName: androidProviderName,
        iOSName: iOSWidgetKind,
      );

      if (kDebugMode) {
        print('✅ Widget updated successfully with $courseCount courses');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating widget: $e');
      }
    }
  }

  /// Update widget with empty state (no classes today)
  Future<void> _updateWidgetWithEmptyState() async {
    final now = DateTime.now();
    final weekdayNames = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final weekdayName = weekdayNames[now.weekday];
    final todayDate = '$weekdayName, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    await HomeWidget.saveWidgetData<String>('widget_title', 'Lịch học hôm nay');
    await HomeWidget.saveWidgetData<String>('widget_date', todayDate);
    await HomeWidget.saveWidgetData<int>('course_count', 0);
    await HomeWidget.saveWidgetData<String>('courses_text', 'Không có lịch học\n\n🎉 Hôm nay bạn rảnh!');
    await HomeWidget.saveWidgetData<String>('last_update', DateTime.now().toIso8601String());

    await HomeWidget.updateWidget(
      androidName: androidProviderName,
      iOSName: iOSWidgetKind,
    );

    if (kDebugMode) {
      print('✅ Widget updated with empty state');
    }
  }

  /// Get today's schedule from database
  Future<List<StudentCourseSubject>?> _getTodaySchedule(int? semesterId) async {
    try {
      if (semesterId == null) {
        if (kDebugMode) {
          print('⚠️ No semester ID provided for widget');
        }
        return null;
      }

      final today = DateTime.now();
      final apiDayOfWeek = today.weekday + 1; // API: 2=Monday, 3=Tuesday, ..., 8=Sunday
      
      // Get courses from database for this semester
      final allCourses = await _dbHelper.getStudentCourses(semesterId);
      
      // Filter courses for today
      final todayCourses = allCourses.where((course) {
        // Check if course is on this day of week
        return course.dayOfWeek == apiDayOfWeek;
      }).toList();

      return todayCourses;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching today schedule: $e');
      }
      return null;
    }
  }

  /// Register widget callback for when widget is clicked
  Future<void> registerWidgetCallback(Function(Uri?) callback) async {
    HomeWidget.widgetClicked.listen(callback);
  }

  /// Initialize widget (call this on app startup)
  Future<void> initializeWidget() async {
    try {
      // Set initial widget data
      await HomeWidget.setAppGroupId('group.com.nekkochan.tlucalendar');
      
      // Update widget with current data
      await updateWidget();

      if (kDebugMode) {
        print('✅ Widget initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing widget: $e');
      }
    }
  }

  /// Force refresh widget
  Future<void> refreshWidget() async {
    await updateWidget();
  }
}

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';

/// One class on one particular day, with its wall-clock start/end resolved
/// from the student's course-hour table.
class ClassSlot {
  ClassSlot({
    required this.course,
    required this.startLabel,
    required this.endLabel,
    required this.start,
    required this.end,
  });

  final StudentCourseSubject course;
  final String startLabel; // "07:00"
  final String endLabel; // "09:25"
  final DateTime start;
  final DateTime end;

  factory ClassSlot.from(
    StudentCourseSubject course,
    UserProvider userProvider,
    DateTime day,
  ) {
    final startHour = userProvider.courseHours[course.startCourseHour];
    final endHour = userProvider.courseHours[course.endCourseHour];

    final startLabel = startHour?.startString ?? 'Tiết ${course.startCourseHour}';
    final endLabel = endHour?.endString ?? 'Tiết ${course.endCourseHour}';

    return ClassSlot(
      course: course,
      startLabel: startLabel,
      endLabel: endLabel,
      start: _combine(day, startHour?.startString) ??
          DateTime(day.year, day.month, day.day, 0, 0),
      end: _combine(day, endHour?.endString) ??
          DateTime(day.year, day.month, day.day, 23, 59),
    );
  }

  ClassState stateAt(DateTime now) {
    if (now.isAfter(end)) return ClassState.past;
    if (!now.isBefore(start) && !now.isAfter(end)) return ClassState.current;
    return ClassState.upcoming;
  }

  /// "07:00" + a date → a DateTime; null when the label isn't a clock time.
  static DateTime? _combine(DateTime day, String? hhmm) {
    if (hhmm == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm.trim());
    if (match == null) return null;
    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }
}

const List<String> _vnWeekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

/// "Thứ Ba" for a DateTime.
String vietnameseWeekday(DateTime date) {
  if (date.weekday < 1 || date.weekday > 7) return '';
  return _vnWeekdays[date.weekday - 1];
}

/// "Thứ Ba, 25 tháng 8, 2026"
String vietnameseFullDate(DateTime date) {
  return '${vietnameseWeekday(date)}, ${date.day} tháng ${date.month}, ${date.year}';
}

/// "Tháng 8, 2026"
String vietnameseMonth(DateTime date) => 'Tháng ${date.month}, ${date.year}';

/// "25/08 – 31/08"
String weekRangeLabel(DateTime anyDayInWeek) {
  final d = DateTime(anyDayInWeek.year, anyDayInWeek.month, anyDayInWeek.day);
  final monday = d.subtract(Duration(days: d.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(monday.day)}/${two(monday.month)} – ${two(sunday.day)}/${two(sunday.month)}';
}

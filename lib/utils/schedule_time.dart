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
    this.exam,
    this.hasKnownTime = true,
  });

  final StudentCourseSubject course;
  final String startLabel; // "07:00"
  final String endLabel; // "09:25"
  final DateTime start;
  final DateTime end;
  final StudentExamRoom? exam;
  final bool hasKnownTime;
  bool get isExam => exam != null;

  /// Exams use the same timeline cards without becoming recurring courses.
  static ClassSlot? fromExam(StudentExamRoom exam) {
    final room = exam.examRoom;
    if (room == null) return null;
    DateTime? day;
    final raw = room.examDateString?.trim() ?? '';
    final match = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
    ).firstMatch(raw);
    if (match != null) {
      final d = int.parse(match[1]!),
          m = int.parse(match[2]!),
          y = int.parse(match[3]!);
      final parsed = DateTime(y, m, d);
      if (parsed.year == y && parsed.month == m && parsed.day == d)
        day = parsed;
    } else if (raw.isNotEmpty) {
      day = DateTime.tryParse(raw);
    }
    if (day == null && room.examDate != null && room.examDate! > 0) {
      final epoch = room.examDate!;
      day = DateTime.fromMillisecondsSinceEpoch(
        epoch < 100000000000 ? epoch * 1000 : epoch,
      );
    }
    if (day == null) return null;
    day = DateTime(day.year, day.month, day.day);
    final start = _combine(day, room.examHour?.startString);
    var end = _combine(day, room.examHour?.endString);
    if (start != null && end == null && (room.duration ?? 0) > 0) {
      end = start.add(Duration(minutes: room.duration!));
    }
    if (start != null && end != null && end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    String clock(DateTime? time) => time == null
        ? 'Chưa có'
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return ClassSlot(
      exam: exam,
      hasKnownTime: start != null && end != null,
      start: start ?? day,
      end: end ?? DateTime(day.year, day.month, day.day, 23, 59),
      startLabel: clock(start),
      endLabel: clock(end),
      course: StudentCourseSubject(
        id: exam.id,
        courseCode: 'LỊCH THI',
        courseName: exam.subjectName,
        classCode: exam.examCode ?? '',
        className: room.examHour?.name ?? '',
        lecturer: null,
        dayOfWeek: day.weekday + 1,
        startCourseHour: 0,
        endCourseHour: 0,
        room: room.room?.name ?? room.roomCode,
        building: '',
        campus: '',
        credits: 0,
        startDate: day.millisecondsSinceEpoch,
        endDate: day.millisecondsSinceEpoch,
        fromWeek: 0,
        toWeek: 0,
        status: 'exam',
        grade: null,
      ),
    );
  }

  factory ClassSlot.from(
    StudentCourseSubject course,
    UserProvider userProvider,
    DateTime day,
  ) {
    final startHour = userProvider.courseHours[course.startCourseHour];
    final endHour = userProvider.courseHours[course.endCourseHour];

    final startLabel =
        startHour?.startString ?? 'Tiết ${course.startCourseHour}';
    final endLabel = endHour?.endString ?? 'Tiết ${course.endCourseHour}';

    return ClassSlot(
      course: course,
      startLabel: startLabel,
      endLabel: endLabel,
      start:
          _combine(day, startHour?.startString) ??
          DateTime(day.year, day.month, day.day, 0, 0),
      end:
          _combine(day, endHour?.endString) ??
          DateTime(day.year, day.month, day.day, 23, 59),
    );
  }

  ClassState stateAt(DateTime now) {
    if (now.isAfter(end)) return ClassState.past;
    if (!hasKnownTime) return ClassState.upcoming;
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
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }
}

/// Merge and deduplicate exams exposed under multiple portal filters.
List<ClassSlot> timetableOn(
  List<ClassSlot> classes,
  Iterable<StudentExamRoom> exams,
  DateTime day,
) {
  final seen = <String>{};
  final slots = [...classes];
  for (final exam in exams) {
    final slot = ClassSlot.fromExam(exam);
    if (slot == null ||
        slot.start.year != day.year ||
        slot.start.month != day.month ||
        slot.start.day != day.day)
      continue;
    final key =
        '${exam.id}:${exam.subjectName}:${slot.start}:${slot.course.room}';
    if (seen.add(key)) slots.add(slot);
  }
  slots.sort((a, b) => a.start.compareTo(b.start));
  return slots;
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

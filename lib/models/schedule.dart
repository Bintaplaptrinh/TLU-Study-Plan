import 'package:tlustudy_planner/models/course.dart';

class Schedule {
  final String id;
  final Course course;
  final DateTime startTime;
  final DateTime endTime;
  final String dayOfWeek;
  final List<int> weeks;
  final bool isRemote;

  Schedule({
    required this.id,
    required this.course,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.weeks,
    this.isRemote = false,
  });

  Duration get duration => endTime.difference(startTime);

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  bool get isUpcoming {
    return startTime.isAfter(DateTime.now());
  }
}

import 'package:flutter/material.dart';
import 'package:tlustudy_planner/models/schedule.dart';
import 'package:tlustudy_planner/models/course.dart';

class ScheduleProvider extends ChangeNotifier {
  late List<Schedule> _schedules;

  List<Schedule> get schedules => _schedules;

  List<Schedule> get todaySchedules {
    final today = DateTime.now();
    return _schedules
        .where(
          (s) =>
              s.startTime.year == today.year &&
              s.startTime.month == today.month &&
              s.startTime.day == today.day,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Schedule> get upcomingSchedules {
    return _schedules.where((s) => s.isUpcoming).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  ScheduleProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Use only if no data loaded!
    // _schedules = [
    //   Schedule(
    //     id: '1',
    //     course: Course(
    //       id: 'c1',
    //       name: 'Phân tích dữ liệu lớn-1-25',
    //       code: '64CNTT2',
    //       classroom: '323-A2',
    //       instructor: 'Dr. Tran',
    //       credits: '3',
    //     ),
    //     startTime: DateTime.now().copyWith(hour: 7, minute: 0),
    //     endTime: DateTime.now().copyWith(hour: 9, minute: 0),
    //     dayOfWeek: 'Monday',
    //     weeks: [1, 2, 3, 4, 5],
    //   ),
    //   Schedule(
    //     id: '2',
    //     course: Course(
    //       id: 'c2',
    //       name: 'Quản trị mạng-1-25',
    //       code: '64CNTT2',
    //       classroom: '323-A2',
    //       instructor: 'Dr. Nguyen',
    //       credits: '3',
    //     ),
    //     startTime: DateTime.now()
    //         .add(const Duration(days: 2))
    //         .copyWith(hour: 9, minute: 45),
    //     endTime: DateTime.now()
    //         .add(const Duration(days: 2))
    //         .copyWith(hour: 11, minute: 45),
    //     dayOfWeek: 'Wednesday',
    //     weeks: [1, 2, 3, 4, 5],
    //   ),
    //   Schedule(
    //     id: '3',
    //     course: Course(
    //       id: 'c3',
    //       name: 'Chuyên đề Công nghệ Thông tin-1-25',
    //       code: '64CNTT2',
    //       classroom: '325-A2',
    //       instructor: 'Dr. Hoang',
    //       credits: '3',
    //     ),
    //     startTime: DateTime.now()
    //         .add(const Duration(days: 3))
    //         .copyWith(hour: 7, minute: 0),
    //     endTime: DateTime.now()
    //         .add(const Duration(days: 3))
    //         .copyWith(hour: 9, minute: 0),
    //     dayOfWeek: 'Thursday',
    //     weeks: [1, 2, 3, 4, 5],
    //   ),
    // ];
  }

  void addSchedule(Schedule schedule) {
    _schedules.add(schedule);
    notifyListeners();
  }

  void removeSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}

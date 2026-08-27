import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';
import 'package:tlustudy_planner/widgets/detail_sheet.dart';

/// Popup chi tiết một buổi học, mở khi chạm vào thẻ ở Hôm nay hoặc Lịch học.
///
/// Thẻ trên danh sách chỉ đủ chỗ cho giờ, phòng và giảng viên; những thứ còn
/// lại (mã lớp học phần, số tín chỉ, khoảng tuần, cơ sở) trước đây không có
/// chỗ nào xem được trong ứng dụng.
class ClassDetailSheet extends StatelessWidget {
  const ClassDetailSheet({
    super.key,
    required this.course,
    required this.startLabel,
    required this.endLabel,
    this.state = ClassState.upcoming,
  });

  final StudentCourseSubject course;
  final String startLabel;
  final String endLabel;
  final ClassState state;

  /// API trả 2 = Thứ Hai ... 8 = Chủ Nhật.
  static String _weekday(int dayOfWeek) {
    const names = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final index = dayOfWeek - 2;
    if (index < 0 || index >= names.length) return '';
    return names[index];
  }

  static String _date(int millis) {
    if (millis <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (String stateLabel, Color stateColor) = switch (state) {
      ClassState.current => ('Đang diễn ra', AppColors.success(context)),
      ClassState.past => ('Đã kết thúc', AppColors.textMuted(context)),
      ClassState.upcoming => ('Sắp tới', AppColors.accent(context)),
    };

    final place = course.building.isEmpty
        ? course.room
        : '${course.room} · ${course.building}';
    final start = _date(course.startDate);
    final end = _date(course.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSheetHeader(
          icon: Symbols.menu_book_rounded,
          color: AppColors.accent(context),
          title: course.courseName,
          subtitle: course.courseCode,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            DetailChip(label: stateLabel, color: stateColor),
            const SizedBox(width: 8),
            if (course.credits > 0)
              DetailChip(
                label: '${course.credits} tín chỉ',
                color: AppColors.accent(context),
              ),
          ],
        ),
        const DetailDivider(),

        DetailRow(
          icon: Symbols.schedule_rounded,
          label: 'Giờ học',
          value: '$startLabel – $endLabel',
          strong: true,
        ),
        if (_weekday(course.dayOfWeek).isNotEmpty)
          DetailRow(
            icon: Symbols.calendar_today_rounded,
            label: 'Thứ',
            value: _weekday(course.dayOfWeek),
            translateValue: true,
          ),
        DetailRow(
          icon: Symbols.location_on_rounded,
          label: 'Địa điểm',
          value: place.isEmpty ? '—' : place,
        ),
        if (course.campus.isNotEmpty)
          DetailRow(
            icon: Symbols.apartment_rounded,
            label: 'Cơ sở',
            value: course.campus,
          ),

        const DetailDivider(),

        if ((course.lecturer?.name ?? '').isNotEmpty)
          DetailRow(
            icon: Symbols.person_rounded,
            label: 'Giảng viên',
            value: course.lecturer!.name,
          ),
        if ((course.lecturer?.email ?? '').isNotEmpty)
          DetailRow(
            icon: Symbols.mail_rounded,
            label: 'Email',
            value: course.lecturer!.email,
          ),
        if (course.classCode.isNotEmpty)
          DetailRow(
            icon: Symbols.tag_rounded,
            label: 'Mã lớp',
            value: course.classCode,
          ),
        if (course.className.isNotEmpty)
          DetailRow(
            icon: Symbols.groups_rounded,
            label: 'Lớp học phần',
            value: course.className,
          ),

        if (start.isNotEmpty || course.fromWeek > 0) ...[
          const DetailDivider(),
          if (start.isNotEmpty && end.isNotEmpty)
            DetailRow(
              icon: Symbols.date_range_rounded,
              label: 'Thời gian',
              value: '$start – $end',
            ),
          if (course.fromWeek > 0 && course.toWeek > 0)
            DetailRow(
              icon: Symbols.view_week_rounded,
              label: 'Tuần học',
              value: 'Tuần ${course.fromWeek} – ${course.toWeek}',
              translateValue: true,
            ),
        ],
      ],
    );
  }
}

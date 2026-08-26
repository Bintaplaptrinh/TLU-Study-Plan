// Regression tests for two layout defects:
//  1. In Tháng view the calendar filled the screen and the class list below
//     could not be reached, because the page was a Column with a fixed header.
//  2. Long course names and long class codes overflowed the class card.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';

StudentCourseSubject buildCourse({
  required String code,
  required String name,
  String room = 'A2-305',
  String building = 'Nhà A2',
  String lecturer = 'TS. Nguyễn Văn An',
}) {
  return StudentCourseSubject(
    id: 1,
    courseCode: code,
    courseName: name,
    classCode: code,
    className: name,
    lecturer: LecturerInfo(id: 1, name: lecturer, email: ''),
    dayOfWeek: 3,
    startCourseHour: 1,
    endCourseHour: 3,
    room: room,
    building: building,
    campus: 'Cơ sở 1',
    credits: 3,
    startDate: 0,
    endDate: 0,
    fromWeek: 1,
    toWeek: 15,
    status: 'registered',
    grade: null,
  );
}

Widget wrap(Widget child) {
  // The translator must stay offline in tests: no network, no timers left
  // pending at the end of the frame.
  TranslationService.instance.networkEnabled = false;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider.value(value: TranslationService.instance),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

/// The month-view page structure: a single CustomScrollView, so the tall
/// calendar can scroll away and expose the class list.
Widget monthPage(List<StudentCourseSubject> courses) {
  return wrap(
    Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 190)), // header
          const SliverToBoxAdapter(child: SizedBox(height: 400)), // month grid
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          DecoratedSliver(
            decoration: const BoxDecoration(color: Colors.white),
            sliver: SliverMainAxisGroup(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 70)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 20, 8),
                  sliver: SliverList.separated(
                    itemCount: courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => ClassCard(
                      course: courses[i],
                      startLabel: '07:00',
                      endLabel: '09:25',
                    ),
                  ),
                ),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(height: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Month view page scrolls so the class list is reachable',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final courses = List.generate(
      4,
      (i) => buildCourse(code: 'CSE44$i', name: 'Học phần số $i'),
    );
    await tester.pumpWidget(monthPage(courses));
    await tester.pumpAndSettle();

    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    // The regression: with the old Column layout the page itself had no
    // scroll extent at all in Tháng view.
    expect(position.maxScrollExtent, greaterThan(0),
        reason: 'the whole page must be scrollable in month view');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0),
        reason: 'dragging must actually move the page');
  });

  testWidgets('Long course name and long class code do not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
          children: [
            ClassCard(
              course: buildCourse(
                code: 'ENG302_NHOM04_HOCKY1_2026',
                name: 'Tiếng Anh chuyên ngành nâng cao dành cho sinh viên '
                    'ngành Công nghệ thông tin chất lượng cao',
                building: 'Toà nhà thí nghiệm C3 mở rộng',
                lecturer: 'ThS. Nguyễn Thị Minh Phương Thảo Linh',
              ),
              startLabel: '13:00',
              endLabel: '15:25',
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // A RenderFlex overflow is reported through the normal error channel, so
    // an empty exception slot means the card laid out cleanly.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Very narrow screens still lay the card out cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(
      Scaffold(
        body: ListView(
          children: [
            ClassCard(
              course: buildCourse(
                code: 'PHYS101_LAB_GROUP_12',
                name: 'Vật lý đại cương phần cơ nhiệt và thí nghiệm',
              ),
              startLabel: '07:00',
              endLabel: '09:25',
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

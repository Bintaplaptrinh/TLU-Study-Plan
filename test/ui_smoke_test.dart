import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';
import 'package:tlustudy_planner/widgets/class_detail_sheet.dart';
import 'package:tlustudy_planner/widgets/detail_sheet.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/widgets/student_barcode.dart';
import 'package:tlustudy_planner/widgets/tab_slide_switcher.dart';
import 'package:tlustudy_planner/widgets/tuition_detail_sheet.dart';

/// Kiểm tra các mảnh giao diện mới dựng được ở cả hai chế độ sáng/tối và trên
/// màn hình hẹp - chỗ dễ tràn (overflow) nhất.
Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<TranslationService>.value(
        value: TranslationService.instance,
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: child),
    ),
  );
}

const _items = [
  FloatingNavItem(label: 'Hôm nay', icon: Symbols.home_rounded),
  FloatingNavItem(label: 'Lịch học', icon: Symbols.calendar_month_rounded),
  FloatingNavItem(label: 'Lịch thi', icon: Symbols.quiz_rounded),
  FloatingNavItem(label: 'Tiện ích', icon: Symbols.apps_rounded),
  FloatingNavItem(label: 'Cài đặt', icon: Symbols.settings_rounded),
];

StudentCourseSubject _course() => StudentCourseSubject(
  id: 1,
  courseCode: 'CSE441',
  courseName: 'Lập trình ứng dụng cho các thiết bị di động',
  classCode: 'CSE441.1',
  className: '65HTTT1',
  lecturer: LecturerInfo(id: 1, name: 'Nguyễn Văn A', email: 'a@tlu.edu.vn'),
  dayOfWeek: 3,
  startCourseHour: 1,
  endCourseHour: 3,
  room: 'P.305',
  building: 'Nhà A2',
  campus: 'Cơ sở 1',
  credits: 3,
  startDate: DateTime(2026, 2, 10).millisecondsSinceEpoch,
  endDate: DateTime(2026, 6, 20).millisecondsSinceEpoch,
  fromWeek: 1,
  toWeek: 15,
  status: 'registered',
  grade: null,
);

void main() {
  testWidgets('thanh điều hướng dựng được ở dạng pill và dạng tròn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final collapsed in [false, true]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          wrap(
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingNavBar(
                items: _items,
                currentIndex: 3,
                collapsed: collapsed,
                onTap: (_) {},
                onBack: () {},
              ),
            ),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('thanh nằm sát đáy chứ không trôi ra giữa trang', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.white)),
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingNavBar(
                items: _items,
                currentIndex: 0,
                onTap: (_) {},
                onBack: () {},
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(FloatingNavBar));
    final page = tester.getRect(find.byType(Scaffold));
    // Đáy thanh phải chạm đáy trang, không được nổi lơ lửng ở giữa.
    expect(bar.bottom, closeTo(page.bottom, 1));
    expect(bar.height, closeTo(FloatingNavBar.barHeight + 12, 1));
  });

  testWidgets('tab chỉ còn icon, không có nhãn chữ', (tester) async {
    await tester.pumpWidget(
      wrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: FloatingNavBar(
            items: _items,
            currentIndex: 2,
            onTap: (_) {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final item in _items) {
      expect(find.text(item.label), findsNothing);
    }
    expect(find.byIcon(Symbols.quiz_rounded), findsOneWidget);
  });

  testWidgets('không tràn trong lúc thanh đang thu lại', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var collapsed = false;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => setState(() => collapsed = !collapsed),
                  child: const Text('toggle'),
                ),
                FloatingNavBar(
                  items: _items,
                  currentIndex: 0,
                  collapsed: collapsed,
                  onTap: (_) {},
                  onBack: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('toggle'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('đổi tab trượt đúng hướng của tab đích', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var index = 0;
    var direction = 1;
    late StateSetter setPage;

    Widget page(int i) => SizedBox.expand(
      child: Align(alignment: Alignment.topLeft, child: Text('Trang $i')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setPage = setState;
              return TabSlideSwitcher(
                index: index,
                direction: direction,
                child: page(index),
              );
            },
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.text('Trang 0')).dx, 0);

    // Sang tab bên phải: trang mới vào từ mép phải, trang cũ ra ở mép trái.
    setPage(() {
      index = 2;
      direction = 1;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getTopLeft(find.text('Trang 2')).dx, greaterThan(0));
    expect(tester.getTopLeft(find.text('Trang 0')).dx, lessThan(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Trang 2')).dx, 0);

    // Lùi về tab bên trái: đúng chiều ngược lại.
    setPage(() {
      index = 1;
      direction = -1;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getTopLeft(find.text('Trang 1')).dx, lessThan(0));
    expect(tester.getTopLeft(find.text('Trang 2')).dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mở trang con thì trượt vào từ mép phải', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Dựng đúng hình dạng khung chính: trang gốc nằm trong Navigator lồng và
    // tự khai báo cú lùi khi bị phủ.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder(
              settings: settings,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder: (context, animation, secondary, child) =>
                  buildCoveredSlide(secondary, child),
              pageBuilder: (_, _, _) => Builder(
                builder: (context) => SizedBox.expand(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => pushSlide(
                        context,
                        const Scaffold(
                          body: SizedBox.expand(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text('Trang con'),
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Mở'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('Mở')).dx, 0);

    await tester.tap(find.text('Mở'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Trang mới vào từ mép phải, trang cũ lùi sang trái chứ không đứng yên.
    expect(tester.getTopLeft(find.text('Trang con')).dx, greaterThan(0));
    expect(tester.getTopLeft(find.text('Mở')).dx, lessThan(0));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Trang con')).dx, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hộp thoại chờ đóng đúng Navigator, không làm rỗng khung', (
    tester,
  ) async {
    // Dựng lại đúng hình dạng của khung chính: một Navigator lồng bên trong,
    // trang nằm trong đó mở một hộp thoại trên Navigator gốc. Đóng nhầm bằng
    // Navigator lồng là ngăn xếp của khung rỗng và Flutter ném
    // '_history.isNotEmpty': is not true - đó là lỗi của nút "Cập nhật dữ liệu".
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final rootNavigator = Navigator.of(
                        context,
                        rootNavigator: true,
                      );
                      showDialog<void>(
                        context: context,
                        useRootNavigator: true,
                        barrierDismissible: false,
                        builder: (_) => const AlertDialog(
                          content: Text('Đang cập nhật...'),
                        ),
                      );
                      await Future<void>.delayed(
                        const Duration(milliseconds: 20),
                      );
                      if (rootNavigator.canPop()) rootNavigator.pop();
                    },
                    child: const Text('Cập nhật ngay'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cập nhật ngay'));
    await tester.pump();
    expect(find.text('Đang cập nhật...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Đang cập nhật...'), findsNothing);
    // Trang bên dưới vẫn còn: ngăn xếp của khung không bị pop nhầm.
    expect(find.text('Cập nhật ngay'), findsOneWidget);
  });

  testWidgets('popup chi tiết lớp học hiện đủ thông tin', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDetailSheet(
              context,
              child: ClassDetailSheet(
                course: _course(),
                startLabel: '07:00',
                endLabel: '09:25',
                state: ClassState.current,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('07:00 – 09:25'), findsOneWidget);
    expect(find.text('P.305 · Nhà A2'), findsOneWidget);
  });

  testWidgets('popup chi tiết học phí tính đúng số còn lại', (tester) async {
    const entry = TuitionEntry(
      id: 42,
      semesterName: 'Học kỳ 1 - 2025-2026',
      amount: 12500000,
      amountPaid: 5000000,
      isPayment: false,
      dateString: '12/09/2025',
      note: 'Học phí kỳ chính',
    );

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDetailSheet(
              context,
              child: const TuitionDetailSheet(entry: entry),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('12,500,000 đ'), findsOneWidget);
    expect(find.text('5,000,000 đ'), findsOneWidget);
    expect(find.text('7,500,000 đ'), findsOneWidget);
  });

  testWidgets('mã vạch dựng được, và tự ẩn khi không mã hoá được', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SizedBox(width: 240, child: StudentBarcode(data: '2251060123'))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(wrap(const StudentBarcode(data: '')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

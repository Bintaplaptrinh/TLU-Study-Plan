import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';
import 'package:tlustudy_planner/screens/document_branch_screen.dart';
import 'package:tlustudy_planner/screens/documents_screen.dart';
import 'package:tlustudy_planner/widgets/circle_back_button.dart';

/// Cùng khung với `ui_smoke_test.dart`: có provider ngôn ngữ, dựng được ở cả
/// hai chế độ sáng/tối.
Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<TranslationService>.value(
        value: TranslationService.instance,
      ),
    ],
    child: MaterialApp(theme: ThemeData(brightness: brightness), home: child),
  );
}

void main() {
  testWidgets('"Đơn từ" hiện thẻ Phân hiệu và mở được trang ba bước', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const DocumentsScreen()));
    await tester.pump();

    expect(find.text('Đơn từ'), findsOneWidget);
    expect(find.text('Phân hiệu trường Đại học Thủy Lợi'), findsOneWidget);

    await tester.tap(find.text('Phân hiệu trường Đại học Thủy Lợi'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo đơn'), findsOneWidget);
    expect(find.text('Ghi danh nộp đơn'), findsOneWidget);
    expect(find.text('Kiểm tra tình trạng đơn'), findsOneWidget);
  });

  testWidgets('ba mục xếp đúng thứ tự bước 1 - 2 - 3', (tester) async {
    await tester.pumpWidget(_wrap(const DocumentBranchScreen()));
    await tester.pump();

    double topOf(String label) => tester.getTopLeft(find.text(label)).dy;

    expect(topOf('Tạo đơn'), lessThan(topOf('Ghi danh nộp đơn')));
    expect(
      topOf('Ghi danh nộp đơn'),
      lessThan(topOf('Kiểm tra tình trạng đơn')),
    );
  });

  testWidgets('dấu ? mở hướng dẫn ba bước', (tester) async {
    await tester.pumpWidget(_wrap(const DocumentBranchScreen()));
    await tester.pump();

    await tester.tap(find.byTooltip('Hướng dẫn quy trình'));
    await tester.pumpAndSettle();

    expect(find.text('Quy trình tạo đơn'), findsOneWidget);
    expect(find.text('Vào mini app tạo đơn'), findsOneWidget);
    // "Ghi danh nộp đơn" xuất hiện hai lần khi popup mở: một ở thẻ bên dưới,
    // một trong hướng dẫn.
    expect(find.text('Ghi danh nộp đơn'), findsNWidgets(2));
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('nút back tròn bấm được và nằm ở mép phải', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: Stack(
            children: [
              Positioned(
                right: 16,
                bottom: 12,
                child: CircleBackButton(onTap: () => tapped = true),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(CircleBackButton));
    expect(box.width, CircleBackButton.diameter);
    // Nằm ở nửa phải màn hình - chỗ ngón cái với tới, và không che phần đầu
    // câu hỏi của biểu mẫu.
    expect(box.center.dx, greaterThan(tester.view.physicalSize.width / 2 / 3));

    await tester.tap(find.byType(CircleBackButton));
    expect(tapped, isTrue);
  });

  testWidgets('dựng được ở chế độ tối và trên màn hình hẹp', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(const DocumentBranchScreen(), brightness: Brightness.dark),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

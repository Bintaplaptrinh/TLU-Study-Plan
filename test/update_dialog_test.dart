import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';
import 'package:tlustudy_planner/services/update_service.dart';
import 'package:tlustudy_planner/widgets/update_dialog.dart';

AppRelease _release({String notes = '', int size = 29360128}) => AppRelease(
  tag: 'v2.3.0',
  version: AppVersion.tryParse('v2.3.0')!,
  title: 'v2.3.0',
  notes: notes,
  pageUrl: 'https://github.com/o/r/releases/tag/v2.3.0',
  apkUrl: 'https://x/a.apk',
  apkSize: size,
  publishedAt: DateTime(2026, 9, 1),
);

Widget _host(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider.value(value: TranslationService.instance),
  ],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('hộp thoại dựng được và hiện đủ các nút', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    showUpdateDialog(
      ctx,
      _release(
        notes: '## Có gì mới\n- Sửa lỗi lịch thi\n\n'
            '**Full Changelog**: https://github.com/o/r/compare/v2.2.0...v2.3.0',
      ),
      allowSkip: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã có bản cập nhật'), findsOneWidget);
    expect(find.textContaining('→'), findsOneWidget);
    expect(find.text('Cập nhật ngay'), findsOneWidget);
    expect(find.text('Để sau'), findsOneWidget);
    expect(find.text('Bỏ qua bản này'), findsOneWidget);

    // Ghi chú đã được gọt: bỏ dấu ## và dòng Full Changelog.
    expect(find.textContaining('Có gì mới\n- Sửa lỗi lịch thi'), findsOneWidget);
    expect(find.textContaining('Full Changelog'), findsNothing);

    // Kích thước tệp hiển thị bên cạnh ngày phát hành.
    expect(find.textContaining('28,0 MB'), findsOneWidget);

    // Không có lỗi tràn khung nào trong lúc dựng.
    expect(tester.takeException(), isNull);
  });

  testWidgets('không có "Bỏ qua" khi người dùng tự bấm kiểm tra', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    showUpdateDialog(ctx, _release());
    await tester.pumpAndSettle();

    expect(find.text('Bỏ qua bản này'), findsNothing);
    expect(find.text('Cập nhật ngay'), findsOneWidget);

    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.text('Đã có bản cập nhật'), findsNothing);
  });
}

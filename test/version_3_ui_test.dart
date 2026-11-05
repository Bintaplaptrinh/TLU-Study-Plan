import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';
import 'package:tlustudy_planner/providers/theme_provider.dart';
import 'package:tlustudy_planner/screens/choose_date_screen.dart';
import 'package:tlustudy_planner/services/notice_service.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';
import 'package:tlustudy_planner/theme/glass_appearance.dart';
import 'package:tlustudy_planner/utils/schedule_time.dart';
import 'package:tlustudy_planner/utils/shell_scope.dart';
import 'package:tlustudy_planner/widgets/calendar_widgets.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/notice_list.dart';
import 'package:tlustudy_planner/widgets/styled_dropdown.dart';
import 'package:tlustudy_planner/widgets/timetable_card.dart';
import 'version_3_data_test.dart' show exam;

Widget wrap(Widget child, {bool dark = false}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider.value(value: TranslationService.instance),
  ],
  child: MaterialApp(
    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: child,
  ),
);

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('V3_PREVIEW')) {
      final fontFile = File('C:/Windows/Fonts/segoeui.ttf');
      if (await fontFile.exists()) {
        final font = FontLoader(
          'Roboto',
        )..addFont(fontFile.readAsBytes().then((b) => ByteData.sublistView(b)));
        await font.load();
      }
      for (final entry in {
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'packages/material_symbols_icons/MaterialSymbolsRounded':
            'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
    }
  });
  test(
    'glass transparency persists and has opaque and clear endpoints',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = ThemeProvider();
      await first.init();
      await first.setGlassTransparency(.8);
      final restored = ThemeProvider();
      await restored.init();
      expect(restored.glassTransparency, .8);
      expect(const GlassAppearance(transparency: 0).alpha(.2), 1);
      expect(const GlassAppearance(transparency: 1).alpha(.2), 0);
      first.dispose();
      restored.dispose();
    },
  );

  testWidgets('glass dropdown opens and chooses a semester', (tester) async {
    int? selected;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: StyledDropdownButton<int>(
            value: 1,
            onChanged: (value) => selected = value,
            items: const [
              DropdownMenuItem(value: 1, child: Text('HK1')),
              DropdownMenuItem(value: 2, child: Text('HK2')),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('HK1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HK2'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choose Date defers back navigation to the shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ShellScope(
          goToTab: (_) {},
          child: ChooseDateScreen(initialDate: DateTime(2026, 11, 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.leading, isNull);
    expect(appBar.automaticallyImplyLeading, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice skeleton becomes a retryable error then a loaded article', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final service = NoticeService(
      MockClient((_) {
        calls++;
        return calls == 1
            ? pending.future
            : Future.value(
                http.Response(
                  '<h2 class="post-title"><a href="/article">School notice</a></h2>',
                  200,
                ),
              );
      }),
    );
    await tester.pumpWidget(wrap(Scaffold(body: NoticeList(service: service))));
    expect(find.byType(NoticeSkeleton), findsOneWidget);
    pending.complete(http.Response('', 503));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NoticeSkeleton), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('School notice'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    service.close();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'ported glass controls and exam cards render in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          wrap(
            RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 36, 20, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Lịch học',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SegmentedPill<int>(
                            value: 0,
                            onChanged: (_) {},
                            segments: const [
                              SegmentItem(
                                value: 0,
                                label: 'Tuần',
                                icon: Icons.view_week_rounded,
                              ),
                              SegmentItem(
                                value: 1,
                                label: 'Tháng',
                                icon: Icons.calendar_month_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          WeekStrip(
                            selectedDate: DateTime(2026, 11, 5),
                            onSelect: (_) {},
                            hasEvents: (_) => true,
                            hasExams: (d) => d.day == 5,
                          ),
                          const SizedBox(height: 18),
                          StyledDropdownButton(
                            value: 1,
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text('Học kỳ 1 · 2026–2027'),
                              ),
                            ],
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 24),
                          TimetableCard(
                            slot: ClassSlot.fromExam(exam())!,
                            state: ClassState.upcoming,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('Tiếp tục'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Xem thêm'),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FloatingNavBar(
                        items: const [
                          FloatingNavItem(
                            label: 'Hôm nay',
                            icon: Icons.home_rounded,
                          ),
                          FloatingNavItem(
                            label: 'Lịch học',
                            icon: Icons.calendar_month_rounded,
                          ),
                          FloatingNavItem(
                            label: 'Lịch thi',
                            icon: Icons.quiz_rounded,
                          ),
                          FloatingNavItem(
                            label: 'Tiện ích',
                            icon: Icons.apps_rounded,
                          ),
                          FloatingNavItem(
                            label: 'Cài đặt',
                            icon: Icons.settings_rounded,
                          ),
                        ],
                        currentIndex: 1,
                        onTap: (_) {},
                        onBack: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('V3_PREVIEW')) {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'build/v3-preview-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }
}

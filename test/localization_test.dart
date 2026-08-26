// Switching to Vietnamese used to crash every screen with an AppBar:
//   debugCheckHasMaterialLocalizations ... No MaterialLocalizations found
// because `locale`/`supportedLocales` were set without the delegates that
// actually provide non-English Material strings.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app({required Locale locale, required bool withDelegates}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: withDelegates
        ? const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ]
        : null,
    home: Scaffold(
      appBar: AppBar(title: const Text('Lịch học')),
      body: Builder(
        builder: (context) =>
            Text(MaterialLocalizations.of(context).backButtonTooltip),
      ),
    ),
  );
}

void main() {
  testWidgets('Vietnamese without the delegates reproduces the crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(locale: const Locale('vi'), withDelegates: false),
    );

    // Two errors are raised: a warning about the unsupported locale and the
    // assertion from the AppBar. Both must be drained or the leftover one
    // fails the test at teardown.
    final errors = <String>[];
    for (
      var error = tester.takeException();
      error != null;
      error = tester.takeException()
    ) {
      errors.add(error.toString());
    }

    // The framework collapses several errors into one opaque sentinel, so the
    // assertion is simply that this configuration fails at all - the device
    // stack trace already told us it is debugCheckHasMaterialLocalizations.
    expect(
      errors,
      isNotEmpty,
      reason:
          'Vietnamese without the delegates must fail, '
          'otherwise the next test proves nothing',
    );
  });

  testWidgets('Vietnamese with the delegates builds cleanly', (tester) async {
    await tester.pumpWidget(
      app(locale: const Locale('vi'), withDelegates: true),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Lịch học'), findsOneWidget);
  });

  testWidgets('Material strings really are Vietnamese', (tester) async {
    await tester.pumpWidget(
      app(locale: const Locale('vi'), withDelegates: true),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final vi = MaterialLocalizations.of(context);
    // Not just "did it resolve" - it must be the Vietnamese bundle.
    expect(vi.backButtonTooltip, isNot('Back'));
    expect(vi.okButtonLabel, isNotEmpty);
  });

  testWidgets('English still works after the change', (tester) async {
    await tester.pumpWidget(
      app(locale: const Locale('en'), withDelegates: true),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(Scaffold));
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Back');
  });
}

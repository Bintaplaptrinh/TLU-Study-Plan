import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';
import 'package:tlustudy_planner/providers/theme_provider.dart';
import 'package:tlustudy_planner/providers/enrollment_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/providers/schedule_provider.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/services/notification_service.dart';
import 'package:tlustudy_planner/services/daily_notification_service.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';
import 'package:tlustudy_planner/screens/home_shell.dart';
import 'package:tlustudy_planner/utils/error_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final errorLogger = ErrorLogger();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errorLogger.logError(
      details.exception,
      details.stack,
      context: 'Flutter Framework Error',
    );
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Capture async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogger.logError(error, stack, context: 'Async Error');
    debugPrint('Async Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Loads the saved language (or falls back to the device locale) and warms
  // the on-disk translation cache before the first frame.
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  final userProvider = UserProvider();
  await userProvider.init();

  final examProvider = ExamProvider();

  // Link providers so UserProvider can fetch exam data during login
  userProvider.setExamProvider(examProvider);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  debugPrint('Notification service initialized');

  // Initialize daily notification background worker
  await DailyNotificationService.initialize();
  debugPrint('Daily notification service initialized');

  // Schedule daily check if user has enabled it
  if (userProvider.dailyNotificationsEnabled) {
    await DailyNotificationService.scheduleDailyCheck();
    debugPrint('Daily notification check scheduled');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: TranslationService.instance),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider.value(value: examProvider),
        // Đăng ký học phần dựa vào phiên đăng nhập của UserProvider để
        // lấy token và mã sinh viên, nên nhận thẳng instance đó.
        ChangeNotifierProvider(
          create: (_) => EnrollmentProvider(userProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          title: 'TLU Study Planner',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('vi'), Locale('en')],
          // Without these, Flutter only ships English Material strings, so
          // resolving to 'vi' leaves MaterialLocalizations.of(context) null
          // and every AppBar asserts on debugCheckHasMaterialLocalizations.
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlustudy_planner/config/app_info.dart';
import 'package:tlustudy_planner/config/app_secrets.dart';
import 'package:tlustudy_planner/config/mail_config.dart';
import 'package:tlustudy_planner/services/weather_service.dart';

/// Bảo vệ hai bất biến dễ vỡ âm thầm:
///
///  1. Số phiên bản chỉ có **một** nguồn - `pubspec.yaml`. Bản dự phòng trong
///     [AppInfo] không được lệch khỏi nó.
///  2. **Không khoá API nào nằm trong mã nguồn.** Đây là thứ đã từng xảy ra
///     (khoá OpenWeather bị commit và lọt vào lịch sử git), nên nó xứng đáng
///     có một bài kiểm tra chặn lại thay vì trông vào trí nhớ người review.
void main() {
  group('Chỉ mục phiên bản', () {
    test('AppInfo.fallbackVersion khớp với version trong pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(
        r'^version:\s*(\S+)\s*$',
        multiLine: true,
      ).firstMatch(pubspec);

      expect(match, isNotNull, reason: 'pubspec.yaml phải có dòng version:');

      // pubspec cho phép dạng `2.2.0+15`; phần hiển thị chỉ là vế trước dấu +.
      final pubspecVersion = match!.group(1)!.split('+').first;

      expect(
        AppInfo.fallbackVersion,
        pubspecVersion,
        reason: 'Đổi version trong pubspec.yaml thì sửa luôn '
            'AppInfo.fallbackVersion (lib/config/app_info.dart)',
      );
    });

    test('ngày phát hành đúng định dạng dd-MM-yyyy', () {
      expect(AppInfo.releaseDate, matches(RegExp(r'^\d{2}-\d{2}-\d{4}$')));
    });
  });

  group('Không hard-code khoá API', () {
    test('app_secrets chỉ đọc khoá qua String.fromEnvironment', () {
      final source = File('lib/config/app_secrets.dart').readAsStringSync();

      // Mọi `static const String <tên> =` phải nối thẳng vào
      // String.fromEnvironment, không phải một chuỗi viết sẵn.
      final declarations = RegExp(
        r'static const String \w+ =\s*([^;]+);',
        multiLine: true,
      ).allMatches(source);

      expect(declarations, isNotEmpty);
      for (final d in declarations) {
        expect(
          d.group(1),
          contains('String.fromEnvironment'),
          reason: 'Khoá phải đến từ --dart-define, không viết vào mã nguồn',
        );
      }
    });

    test('không có chuỗi nào trong lib/ trông giống khoá API', () {
      // Khoá OpenWeather là 32 ký tự hex; token và khoá của phần lớn dịch vụ
      // khác cũng rơi vào dạng này. Quét toàn bộ lib/ để lần sau ai dán khoá
      // vào code là đỏ ngay ở CI.
      final suspicious = RegExp(r'''['"][0-9a-f]{32}['"]''');
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (suspicious.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Đưa khoá vào env.json và đọc qua AppSecrets thay vì viết '
            'thẳng vào mã nguồn',
      );
    });
  });

  group('Cấu hình hộp thư', () {
    test('redirectUri dùng đúng scheme đã khai', () {
      expect(MailConfig.redirectUri, startsWith('${MailConfig.redirectScheme}:'));
    });

    test('scheme viết thường toàn bộ', () {
      // AppAuth trên Android xử lý sai redirect nếu scheme có chữ hoa.
      expect(MailConfig.redirectScheme, MailConfig.redirectScheme.toLowerCase());
    });

    test('xin quyền đọc, không xin quyền gửi', () {
      expect(MailConfig.scopes, contains('offline_access'));
      expect(MailConfig.scopes.any((s) => s.startsWith('Mail.')), isTrue);
      expect(MailConfig.scopes, isNot(contains('Mail.Send')));
    });

    test('markReadOnServer chỉ bật cùng quyền ghi', () {
      if (MailConfig.markReadOnServer) {
        expect(MailConfig.scopes, contains('Mail.ReadWrite'));
      }
    });
  });

  group('Thời tiết khi thiếu khoá', () {
    test('báo lỗi rõ ràng thay vì gọi mạng', () async {
      // Chỉ có nghĩa khi chạy test không kèm --dart-define; có khoá thì bỏ qua.
      if (AppSecrets.hasWeatherKey) return;

      await expectLater(
        WeatherService().loadCurrentWeather(),
        throwsA(isA<WeatherException>()),
      );
    });
  });
}

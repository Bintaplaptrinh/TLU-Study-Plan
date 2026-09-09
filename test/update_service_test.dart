import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/services/update_service.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('nhận các dạng tag hợp lệ', () {
      expect(AppVersion.tryParse('v2.3.0')?.canonical, '2.3.0');
      expect(AppVersion.tryParse('2.3.0')?.canonical, '2.3.0');
      expect(AppVersion.tryParse('V2.3.0')?.canonical, '2.3.0');
      expect(AppVersion.tryParse('  v2.3.0  ')?.canonical, '2.3.0');
      expect(AppVersion.tryParse('v2.3.0.4')?.canonical, '2.3.0.4');
      expect(AppVersion.tryParse('v2.3.0+15')?.canonical, '2.3.0');
      expect(AppVersion.tryParse('v2.3.0-beta.1')?.canonical, '2.3.0-beta.1');
    });

    test('từ chối tag không phải số phiên bản', () {
      // Đây là dạng tag kho này từng dùng - phải bị bỏ qua, không được đọc
      // nhầm thành "12.30" rồi coi là mới hơn 2.2.0.
      expect(AppVersion.tryParse('release_2026.09.04_12-30'), isNull);
      expect(AppVersion.tryParse('release-1'), isNull);
      expect(AppVersion.tryParse('v2.3'), isNull);
      expect(AppVersion.tryParse('latest'), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('v2.3.0-'), isNull);
    });
  });

  group('so sánh', () {
    int cmp(String a, String b) =>
        AppVersion.tryParse(a)!.compareTo(AppVersion.tryParse(b)!);

    test('theo từng thành phần số', () {
      expect(cmp('v2.3.0', 'v2.2.0'), greaterThan(0));
      expect(cmp('v2.2.0', 'v2.3.0'), lessThan(0));
      expect(cmp('v2.2.0', 'v2.2.0'), 0);
      expect(cmp('v2.10.0', 'v2.9.0'), greaterThan(0)); // không so chuỗi
      expect(cmp('v10.0.0', 'v9.9.9'), greaterThan(0));
      expect(cmp('v2.2.1', 'v2.2.0'), greaterThan(0));
    });

    test('phần thứ tư và số build', () {
      expect(cmp('v2.2.0.1', 'v2.2.0'), greaterThan(0));
      expect(cmp('v2.2.0', 'v2.2.0.0'), 0);
      expect(cmp('v2.2.0+20', 'v2.2.0+3'), 0); // build không tính
    });

    test('bản chính thức đứng trên bản thử nghiệm', () {
      expect(cmp('v2.3.0', 'v2.3.0-beta.1'), greaterThan(0));
      expect(cmp('v2.3.0-beta.1', 'v2.3.0'), lessThan(0));
      expect(cmp('v2.3.0-beta.2', 'v2.3.0-beta.1'), greaterThan(0));
    });
  });

  group('AppRelease.tryParse', () {
    Map<String, dynamic> release(String body) =>
        jsonDecode(body) as Map<String, dynamic>;

    test('lấy asset .apk và các trường hiển thị', () {
      final r = AppRelease.tryParse(release('''
      {
        "tag_name": "v2.3.0",
        "name": "v2.3.0",
        "body": "## Có gì mới\\n- Sửa lỗi\\n\\n**Full Changelog**: https://x",
        "html_url": "https://github.com/o/r/releases/tag/v2.3.0",
        "published_at": "2026-09-01T10:00:00Z",
        "assets": [
          {"name": "tlu-study-plan.aab", "browser_download_url": "https://x/a.aab", "size": 1},
          {"name": "tlu-study-plan.apk", "browser_download_url": "https://x/a.apk", "size": 29360128}
        ]
      }'''));

      expect(r, isNotNull);
      expect(r!.version.canonical, '2.3.0');
      expect(r.apkUrl, 'https://x/a.apk');
      expect(r.apkSize, 29360128);
      expect(r.readableSize, '28,0 MB');
      expect(r.publishedAt, isNotNull);
    });

    test('không có asset thì dựng đường dẫn theo quy ước', () {
      final r = AppRelease.tryParse(release(
          '{"tag_name": "v2.4.0", "assets": []}'));
      expect(
        r!.apkUrl,
        'https://github.com/Bintaplaptrinh/TLU-Study-Plan'
        '/releases/download/v2.4.0/tlu-study-plan.apk',
      );
      expect(r.title, 'v2.4.0'); // rơi về tag khi name trống
    });

    test('chọn tệp .apk kể cả khi tên khác quy ước', () {
      final r = AppRelease.tryParse(release('''
      {"tag_name": "v2.5.0", "assets": [
        {"name": "app-release.apk", "browser_download_url": "https://x/app.apk", "size": 5}
      ]}'''));
      expect(r!.apkUrl, 'https://x/app.apk');
    });

    test('bỏ qua bản phát hành có tag không đọc được', () {
      expect(
        AppRelease.tryParse(release('{"tag_name": "release_2026.09.04_12-30"}')),
        isNull,
      );
      expect(AppRelease.tryParse(release('{}')), isNull);
    });
  });

  group('formatBytes', () {
    test('dùng dấu phẩy thập phân', () {
      expect(formatBytes(0), '');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024 * 1024), '1,0 MB');
      expect(formatBytes(29360128), '28,0 MB');
    });
  });
}

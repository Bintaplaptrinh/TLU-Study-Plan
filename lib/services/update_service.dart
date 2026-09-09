import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlustudy_planner/config/app_info.dart';
import 'package:tlustudy_planner/services/log_service.dart';

/// ╔══════════════════════════════════════════════════════════════════════╗
/// ║  CẬP NHẬT TRONG ỨNG DỤNG - ĐỌC TAG TỪ GITHUB RELEASES                ║
/// ╚══════════════════════════════════════════════════════════════════════╝
///
/// Ứng dụng không phát hành qua Play Store, nên không có cơ chế cập nhật nào
/// tự chạy. Thay vào đó, nó tự hỏi GitHub: bản phát hành mới nhất mang tag
/// nào, tag đó có lớn hơn [AppInfo.version] đang chạy không, và nếu có thì
/// tải thẳng tệp `.apk` đính kèm rồi giao cho trình cài đặt của hệ thống.
/// Sinh viên không phải mở trình duyệt, tìm bản phát hành, rồi tự lục trong
/// thư mục Downloads nữa.
///
/// ── Quy ước về tag ─────────────────────────────────────────────────────
///
/// Chỉ những tag dạng `v2.3.0` (hoặc `2.3.0`, kèm `-beta.1` / `+15` tuỳ ý)
/// mới được coi là một *phiên bản*. Kho này từng phát hành với tag dạng
/// `release_2026.09.04_12-30`; những tag như vậy bị bỏ qua có chủ đích, vì
/// không thể so sánh chúng với `2.2.0` một cách có nghĩa - và đoán bừa thì
/// tệ hơn nhiều so với việc im lặng.
///
/// Vì lý do đó service đọc *danh sách* `/releases` chứ không phải
/// `/releases/latest`: `/latest` trả về bản mới nhất theo thời gian, có thể
/// là một tag không đọc được. Danh sách cho phép lọc ra các tag hợp lệ rồi
/// chọn phiên bản cao nhất trong số đó.
///
/// ── Quyền cài đặt trên Android ─────────────────────────────────────────
///
/// Từ Android 8 (API 26), mỗi ứng dụng phải được cấp riêng quyền "cài ứng
/// dụng không rõ nguồn gốc" thì mới mở được trình cài đặt. Manifest đã khai
/// `REQUEST_INSTALL_PACKAGES`, nhưng khai báo thôi chưa đủ - người dùng vẫn
/// phải bật công tắc cho ứng dụng này. Nếu chưa bật, hệ thống tự hiện màn
/// hình xin quyền khi ta gửi intent cài đặt; [openInstallPermissionSettings]
/// là lối đi thủ công cho những máy không hiện màn hình đó.
class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  final LogService _log = LogService();

  // ── Kho phát hành ───────────────────────────────────────────────────────

  static const String owner = 'Bintaplaptrinh';
  static const String repo = 'TLU-Study-Plan';

  /// Tên tệp `.apk` mà workflow phát hành đính kèm. Chỉ dùng để dựng đường
  /// dẫn dự phòng khi GitHub API không trả về danh sách asset.
  static const String apkAssetName = 'tlu-study-plan.apk';

  static const String releasesPage =
      'https://github.com/$owner/$repo/releases';

  static const String _apiBase = 'https://api.github.com/repos/$owner/$repo';

  // ── Khoá lưu trong SharedPreferences ────────────────────────────────────

  static const String _kAutoCheck = 'update_auto_check_enabled';
  static const String _kLastCheck = 'update_last_check_ms';
  static const String _kSkipped = 'update_skipped_version';

  /// Khoảng cách tối thiểu giữa hai lần tự kiểm tra. GitHub cho 60 lượt gọi
  /// mỗi giờ với mỗi địa chỉ IP; ký túc xá và thư viện thì hàng trăm máy
  /// dùng chung một IP, nên gọi mỗi lần mở app là cách nhanh nhất để cả
  /// trường cùng bị chặn.
  static const Duration autoCheckGap = Duration(hours: 24);

  static const Duration _requestTimeout = Duration(seconds: 15);

  // ── Hỏi GitHub ──────────────────────────────────────────────────────────

  /// Bản phát hành mới nhất *có tag đọc được*, hoặc null nếu kho chưa có bản
  /// nào như vậy.
  ///
  /// Ném [UpdateException] khi không gọi được mạng hoặc GitHub từ chối.
  Future<AppRelease?> fetchLatestRelease() async {
    final uri = Uri.parse('$_apiBase/releases?per_page=30');

    // GitHub từ chối các yêu cầu không kèm User-Agent, nên nó bắt buộc chứ
    // không phải để cho đẹp.
    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': AppInfo.userAgent,
    };

    final http.Response res;
    try {
      res = await http.get(uri, headers: headers).timeout(_requestTimeout);
    } on TimeoutException {
      throw const UpdateException('Máy chủ phản hồi quá chậm');
    } catch (e) {
      throw UpdateException('Không kết nối được tới GitHub: $e');
    }

    if (res.statusCode == 403 || res.statusCode == 429) {
      // Hết lượt gọi ẩn danh. Không phải lỗi của người dùng, và thử lại ngay
      // cũng vô ích - nói thẳng là chờ một lát.
      throw const UpdateException(
        'GitHub tạm thời giới hạn số lần kiểm tra, thử lại sau ít phút',
      );
    }
    if (res.statusCode != 200) {
      throw UpdateException('GitHub trả về lỗi ${res.statusCode}');
    }

    final List<dynamic> raw;
    try {
      raw = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    } catch (e) {
      throw UpdateException('Không đọc được dữ liệu phát hành: $e');
    }

    AppRelease? best;
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      if (item['draft'] == true) continue;
      // Bản thử nghiệm chỉ dành cho người tự vào GitHub tải, không đẩy cho
      // toàn bộ sinh viên.
      if (item['prerelease'] == true) continue;

      final release = AppRelease.tryParse(item);
      if (release == null) continue;
      if (best == null || release.version.compareTo(best.version) > 0) {
        best = release;
      }
    }

    return best;
  }

  /// Kiểm tra ngay, do người dùng bấm nút.
  ///
  /// Trả về bản phát hành *mới hơn* bản đang chạy, hoặc null nếu đã là mới
  /// nhất. Bản bị "bỏ qua" trước đó vẫn được trả về: người dùng chủ động hỏi
  /// thì phải được trả lời.
  Future<AppRelease?> checkNow() async {
    final release = await fetchLatestRelease();
    await markChecked();
    if (release == null) return null;
    return release.isNewerThanInstalled ? release : null;
  }

  /// Kiểm tra ngầm lúc mở ứng dụng. Không bao giờ ném lỗi - mất mạng thì
  /// lặng lẽ bỏ qua, chứ không hiện thông báo lỗi cho một việc người dùng
  /// không yêu cầu.
  Future<AppRelease?> autoCheck() async {
    if (!Platform.isAndroid) return null;

    try {
      if (!await isAutoCheckEnabled()) return null;

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_kLastCheck);
      if (last != null) {
        final since = DateTime.now().millisecondsSinceEpoch - last;
        if (since >= 0 && since < autoCheckGap.inMilliseconds) return null;
      }

      // Đánh dấu *trước* khi gọi mạng: một lần gọi hỏng cũng phải tính là đã
      // thử, nếu không thì mỗi lần mở app lại gọi lại đúng cái đang hỏng.
      await markChecked();

      final release = await fetchLatestRelease();
      if (release == null || !release.isNewerThanInstalled) return null;

      final skipped = prefs.getString(_kSkipped);
      if (skipped != null && skipped == release.version.canonical) return null;

      _log.log(
        'Có bản cập nhật ${release.tag} (đang chạy ${AppInfo.version})',
        level: LogLevel.info,
      );
      return release;
    } catch (e) {
      _log.log('Tự kiểm tra cập nhật thất bại: $e', level: LogLevel.warning);
      return null;
    }
  }

  // ── Tải tệp cài đặt ─────────────────────────────────────────────────────

  /// Tải `.apk` của [release] về bộ nhớ riêng của ứng dụng.
  ///
  /// [onProgress] nhận (số byte đã tải, tổng số byte); tổng là -1 khi máy chủ
  /// không gửi `Content-Length`.
  Future<File> downloadApk(
    AppRelease release, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = release.apkUrl;
    if (url == null) {
      throw const UpdateException(
        'Bản phát hành này không kèm tệp cài đặt cho Android',
      );
    }

    final dir = await _downloadDirectory();
    final target = File('${dir.path}/tlu-study-plan-${release.version}.apk');
    // Tải vào tệp tạm rồi mới đổi tên: nếu người dùng huỷ giữa chừng hoặc
    // mạng đứt, cái còn lại trên đĩa là một tệp `.part` dở dang chứ không
    // phải một `.apk` cụt đuôi mà trình cài đặt sẽ nhận rồi báo lỗi khó hiểu.
    final part = File('${target.path}.part');

    try {
      if (await part.exists()) await part.delete();
      if (await target.exists()) await target.delete();
    } catch (_) {
      // Không xoá được thì cứ ghi đè.
    }

    final dio = Dio(
      BaseOptions(
        headers: {'User-Agent': AppInfo.userAgent},
        followRedirects: true,
        // GitHub chuyển tiếp sang máy chủ tải của họ; mặc định của Dio là 5
        // lần, đủ rộng.
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    try {
      await dio.download(
        url,
        part.path,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      if (CancelToken.isCancel(e)) rethrow;
      throw UpdateException('Tải bản cập nhật thất bại: ${_dioMessage(e)}');
    } finally {
      dio.close(force: true);
    }

    // Một trang lỗi HTML cũng là 200 OK với vài KB nội dung. Bốn byte đầu của
    // mọi tệp .apk là chữ ký ZIP "PK\x03\x04"; kiểm ở đây rẻ hơn nhiều so với
    // việc để trình cài đặt báo "gói không hợp lệ".
    if (!await _looksLikeApk(part)) {
      try {
        await part.delete();
      } catch (_) {}
      throw const UpdateException(
        'Tệp tải về không phải bản cài đặt hợp lệ',
      );
    }

    await part.rename(target.path);
    _log.log(
      'Đã tải ${release.tag} về ${target.path}',
      level: LogLevel.success,
    );
    return target;
  }

  /// Giao tệp cho trình cài đặt của hệ thống.
  ///
  /// Trên Android 8+, nếu ứng dụng chưa được bật "cài ứng dụng không rõ nguồn
  /// gốc", hệ thống sẽ tự hiện màn hình xin quyền thay vì cài ngay.
  Future<void> installApk(File apk) async {
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      _log.log(
        'Không mở được trình cài đặt: ${result.type} ${result.message}',
        level: LogLevel.error,
      );
      throw const UpdateException(
        'Không mở được trình cài đặt của hệ thống',
      );
    }
  }

  /// Mở thẳng màn hình cấp quyền "Cài ứng dụng không rõ nguồn gốc" của hệ
  /// thống cho riêng ứng dụng này.
  Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    final package = AppInfo.packageName;
    try {
      await AndroidIntent(
        action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
        data: 'package:$package',
      ).launch();
    } catch (_) {
      // Máy chạy Android 7 trở xuống không có màn hình đó; trang thông tin
      // ứng dụng là chỗ gần nhất còn có ý nghĩa.
      try {
        await AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:$package',
        ).launch();
      } catch (e) {
        _log.log('Không mở được cài đặt quyền: $e', level: LogLevel.warning);
      }
    }
  }

  /// Dọn các tệp `.apk` và `.part` còn sót lại từ những lần cập nhật trước.
  /// Gọi sau khi cài xong, hoặc lúc khởi động - mỗi tệp là vài chục MB.
  Future<void> cleanUpDownloads({String? keepPath}) async {
    try {
      final dir = await _downloadDirectory();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.path.split(Platform.pathSeparator).last;
        if (!name.startsWith('tlu-study-plan-')) continue;
        if (!name.endsWith('.apk') && !name.endsWith('.part')) continue;
        if (keepPath != null && entity.path == keepPath) continue;
        try {
          await entity.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('cleanUpDownloads: $e');
    }
  }

  // ── Tuỳ chọn của người dùng ─────────────────────────────────────────────

  Future<bool> isAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoCheck) ?? true;
  }

  Future<void> setAutoCheckEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoCheck, value);
  }

  Future<DateTime?> lastCheckedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastCheck);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastCheck, DateTime.now().millisecondsSinceEpoch);
  }

  /// Ghi nhớ rằng người dùng không muốn được nhắc về đúng phiên bản này nữa.
  /// Bản kế tiếp vẫn được nhắc bình thường.
  Future<void> skipVersion(String canonicalVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSkipped, canonicalVersion);
  }

  // ── Phần dùng nội bộ ────────────────────────────────────────────────────

  Future<Directory> _downloadDirectory() async {
    // Bộ nhớ ngoài riêng của ứng dụng (/Android/data/<gói>/files) không cần
    // xin quyền, và trình cài đặt đọc được qua FileProvider của open_filex.
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final dir = Directory('${external.path}/updates');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      }
    }
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/updates');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<bool> _looksLikeApk(File file) async {
    try {
      if (!await file.exists()) return false;
      if (await file.length() < 1024) return false;
      final head = await file.openRead(0, 4).first;
      return head.length >= 4 &&
          head[0] == 0x50 && // P
          head[1] == 0x4B && // K
          head[2] == 0x03 &&
          head[3] == 0x04;
    } catch (_) {
      return false;
    }
  }

  String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'mạng quá chậm hoặc bị ngắt';
      case DioExceptionType.badResponse:
        return 'máy chủ trả về lỗi ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'không có kết nối mạng';
      default:
        return e.message ?? 'lỗi không xác định';
    }
  }
}

/// Một bản phát hành trên GitHub, đã đọc được số phiên bản từ tag.
@immutable
class AppRelease {
  const AppRelease({
    required this.tag,
    required this.version,
    required this.title,
    required this.notes,
    required this.pageUrl,
    required this.apkUrl,
    required this.apkSize,
    required this.publishedAt,
  });

  /// Tag gốc trên GitHub, ví dụ `v2.3.0`.
  final String tag;

  final AppVersion version;

  /// Tiêu đề bản phát hành; rơi về [tag] khi để trống.
  final String title;

  /// Nội dung mô tả (Markdown thô do GitHub sinh ra hoặc người viết tay).
  final String notes;

  final String pageUrl;

  /// Đường dẫn tải trực tiếp tệp `.apk`, hoặc null nếu bản này không kèm.
  final String? apkUrl;

  /// Kích thước tệp theo byte; 0 khi không rõ.
  final int apkSize;

  final DateTime? publishedAt;

  bool get isNewerThanInstalled =>
      version.compareTo(AppVersion.installed) > 0;

  /// Kích thước dạng đọc được, ví dụ `28,4 MB`.
  String get readableSize => formatBytes(apkSize);

  static AppRelease? tryParse(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String?)?.trim();
    if (tag == null || tag.isEmpty) return null;

    final version = AppVersion.tryParse(tag);
    if (version == null) return null;

    String? apkUrl;
    int apkSize = 0;
    final assets = json['assets'];
    if (assets is List) {
      Map<String, dynamic>? chosen;
      for (final a in assets) {
        if (a is! Map<String, dynamic>) continue;
        final name = (a['name'] as String?)?.toLowerCase() ?? '';
        if (!name.endsWith('.apk')) continue;
        // Tên đã thống nhất thì ưu tiên; còn lại lấy tệp .apk đầu tiên, để
        // một lần đổi tên trong workflow không làm hỏng chức năng cập nhật.
        if (name == apkAssetNameLower) {
          chosen = a;
          break;
        }
        chosen ??= a;
      }
      if (chosen != null) {
        apkUrl = chosen['browser_download_url'] as String?;
        final size = chosen['size'];
        if (size is int) apkSize = size;
      }
    }

    // Không có asset nào (hoặc API bị cắt bớt) thì dựng đường dẫn theo quy
    // ước tên tệp - vẫn tốt hơn là báo "không có bản tải".
    apkUrl ??=
        'https://github.com/${UpdateService.owner}/${UpdateService.repo}'
        '/releases/download/$tag/${UpdateService.apkAssetName}';

    DateTime? published;
    final publishedRaw = json['published_at'] as String?;
    if (publishedRaw != null) {
      published = DateTime.tryParse(publishedRaw)?.toLocal();
    }

    final name = (json['name'] as String?)?.trim();
    final body = (json['body'] as String?)?.trim() ?? '';

    return AppRelease(
      tag: tag,
      version: version,
      title: (name == null || name.isEmpty) ? tag : name,
      notes: body,
      pageUrl:
          (json['html_url'] as String?) ?? UpdateService.releasesPage,
      apkUrl: apkUrl,
      apkSize: apkSize,
      publishedAt: published,
    );
  }

  static final String apkAssetNameLower =
      UpdateService.apkAssetName.toLowerCase();
}

/// Số phiên bản dạng `x.y.z`, so sánh được.
///
/// Chỉ nhận chuỗi *đúng* dạng đó (cho phép tiền tố `v`, phần thứ tư, hậu tố
/// `-beta.1` và `+build`). Mọi thứ khác trả về null - xem ghi chú về tag ở
/// đầu [UpdateService].
@immutable
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.numbers, {this.preRelease = ''});

  final List<int> numbers;

  /// Phần sau dấu `-`, ví dụ `beta.1`. Rỗng nghĩa là bản chính thức.
  final String preRelease;

  static final RegExp _pattern = RegExp(
    r'^v?(\d{1,5})\.(\d{1,5})\.(\d{1,5})(?:\.(\d{1,5}))?'
    r'(?:-([0-9A-Za-z][0-9A-Za-z.\-]*))?'
    r'(?:\+([0-9A-Za-z][0-9A-Za-z.\-]*))?$',
    caseSensitive: false,
  );

  /// Phiên bản đang chạy, đọc từ `pubspec.yaml` qua [AppInfo].
  static AppVersion get installed =>
      tryParse(AppInfo.version) ?? const AppVersion([0, 0, 0]);

  static AppVersion? tryParse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;

    final numbers = <int>[
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      if (match.group(4) != null) int.parse(match.group(4)!),
    ];
    return AppVersion(numbers, preRelease: match.group(5) ?? '');
  }

  /// Dạng chuẩn hoá không có tiền tố `v`, dùng làm khoá lưu trữ.
  String get canonical {
    final base = numbers.join('.');
    return preRelease.isEmpty ? base : '$base-$preRelease';
  }

  @override
  int compareTo(AppVersion other) {
    final length =
        numbers.length > other.numbers.length
        ? numbers.length
        : other.numbers.length;
    for (var i = 0; i < length; i++) {
      final a = i < numbers.length ? numbers[i] : 0;
      final b = i < other.numbers.length ? other.numbers[i] : 0;
      if (a != b) return a.compareTo(b);
    }

    // Theo semver: `2.3.0` là bản hoàn chỉnh nên đứng *trên* `2.3.0-beta.1`.
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    return preRelease.compareTo(other.preRelease);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}

/// Lỗi đã có thông điệp viết sẵn cho người dùng đọc.
class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `28956123` → `27,6 MB`. Dấu phẩy thập phân theo thói quen tiếng Việt.
String formatBytes(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$text ${units[unit]}';
}

import 'package:package_info_plus/package_info_plus.dart';

/// ╔══════════════════════════════════════════════════════════════════════╗
/// ║  CHỈ MỤC PHIÊN BẢN CỦA ỨNG DỤNG - SỬA Ở ĐÂY, CẢ APP ĐỔI THEO         ║
/// ╚══════════════════════════════════════════════════════════════════════╝
///
/// Có đúng **hai** chỗ cần đụng tới khi phát hành bản mới:
///
///   1. `pubspec.yaml`  →  dòng `version: 2.2.0`
///      Đây là nguồn duy nhất của *số* phiên bản. Flutter đọc nó để sinh ra
///      `versionName` cho Android (`android/app/build.gradle.kts` đang để
///      `versionName = flutter.versionName`) và `CFBundleShortVersionString`
///      cho iOS. [AppInfo.version] đọc lại đúng giá trị đó lúc chạy, nên màn
///      hình Cài đặt, log, và mọi nơi khác tự khớp - không còn chuỗi '2.0.0'
///      gõ tay nằm rải rác trong code nữa.
///
///      Muốn "kéo dài" số phiên bản (2.2.0 → 2.3.0 → 2.3.0+15) thì cứ sửa
///      thẳng dòng đó; định dạng `x.y.z+build` đều được, [buildNumber] sẽ
///      nhận phần sau dấu `+`.
///
///   2. [releaseDate] ngay bên dưới - ngày phát hành. pubspec không có chỗ
///      cho nó nên nó phải nằm đây; đây là hằng số duy nhất còn lại.
///
/// Lưu ý riêng cho Android: `versionCode` (số nguyên tăng dần mà Play Store
/// dùng để phân biệt bản build) vẫn được đặt tay trong
/// `android/app/build.gradle.kts`. Nó không phải thứ người dùng nhìn thấy,
/// và Play Store bắt buộc phải tăng, nên nó cố tình tách khỏi chỗ này.
class AppInfo {
  AppInfo._();

  // ── Thứ duy nhất phải sửa tay ở file này ────────────────────────────────

  /// Ngày phát hành bản hiện tại, hiển thị trong Cài đặt → Thông tin.
  static const String releaseDate = '04-09-2026';

  /// Giá trị hiển thị khi chưa kịp đọc `pubspec` (ví dụ khung nền chạy trước
  /// khi [load] xong). Nên giữ khớp với `pubspec.yaml`, nhưng nếu lệch thì
  /// giá trị thật vẫn thắng ngay khi [load] chạy xong.
  static const String fallbackVersion = '2.1.7';

  // ── Đọc từ pubspec/native lúc chạy ──────────────────────────────────────

  static PackageInfo? _info;

  /// Nạp thông tin gói. Gọi một lần trong `main()` trước `runApp`.
  ///
  /// Không ném lỗi: một thiết bị không trả về được PackageInfo thì app vẫn
  /// chạy, chỉ là hiển thị [fallbackVersion].
  static Future<void> load() async {
    try {
      _info = await PackageInfo.fromPlatform();
    } catch (_) {
      _info = null;
    }
  }

  /// Số phiên bản người dùng nhìn thấy, ví dụ `2.0.0`.
  static String get version {
    final v = _info?.version;
    return (v == null || v.isEmpty) ? fallbackVersion : v;
  }

  /// Số build (phần sau dấu `+` trong pubspec, hoặc `versionCode` trên
  /// Android). Rỗng nếu không có.
  static String get buildNumber => _info?.buildNumber ?? '';

  /// Tên ứng dụng theo khai báo của nền tảng.
  static String get appName {
    final n = _info?.appName;
    return (n == null || n.isEmpty) ? 'TLU Study Planner' : n;
  }

  /// Định danh gói, ví dụ `com.tlu.studyplanner`.
  static String get packageName => _info?.packageName ?? 'com.tlu.studyplanner';

  /// Chuỗi đầy đủ `2.2.0 (2025110220)` - dùng cho log và báo lỗi, nơi số
  /// build có ích. Màn hình Cài đặt dùng [version] cho gọn.
  static String get fullVersion {
    final build = buildNumber;
    return build.isEmpty ? version : '$version ($build)';
  }

  /// Chuỗi User-Agent dùng khi gọi API ngoài.
  static String get userAgent => 'TLUStudyPlanner/$version';
}

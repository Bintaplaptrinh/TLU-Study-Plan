/// Khoá API của các dịch vụ bên ngoài.
///
/// ┌──────────────────────────────────────────────────────────────────────┐
/// │ KHÔNG BAO GIỜ GHI GIÁ TRỊ THẬT VÀO FILE NÀY - NÓ NẰM TRONG GIT       │
/// └──────────────────────────────────────────────────────────────────────┘
///
/// Mọi giá trị ở đây đọc từ `--dart-define` lúc biên dịch, và nơi giữ chúng
/// là `env.json` ở gốc dự án - file đã được .gitignore. Xem `env.example.json`
/// để biết cấu trúc, và README mục "Cấu hình khoá API".
///
/// Chạy và build đều phải kèm cờ:
///
/// ```bash
/// flutter run   --dart-define-from-file=env.json
/// flutter build apk --release --dart-define-from-file=env.json
/// ```
///
/// (`.vscode/launch.json` đã cấu hình sẵn cờ này, nên bấm F5 trong VS Code thì
/// không cần gõ gì thêm.)
///
/// Vì sao không dùng một file `secrets.dart` bị gitignore: người clone repo về
/// sẽ không biên dịch được cho tới khi tự tạo file đó, và lỗi báo ra là "URI
/// doesn't exist" - khó hiểu. Với `String.fromEnvironment`, thiếu khoá thì
/// ứng dụng vẫn build và chạy, chỉ riêng tính năng cần khoá đó báo một câu rõ
/// ràng.
class AppSecrets {
  AppSecrets._();

  /// Khoá OpenWeatherMap cho thẻ thời tiết ở Trang chủ.
  /// Lấy miễn phí tại <https://home.openweathermap.org/api_keys>.
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static bool get hasOpenWeatherKey => openWeatherApiKey.isNotEmpty;
}

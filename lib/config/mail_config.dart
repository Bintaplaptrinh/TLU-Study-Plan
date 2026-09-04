/// Cấu hình OAuth cho hộp thư trường (mail.tlu.edu.vn).
///
/// Tên miền `tlu.edu.vn` là một tenant Microsoft 365 ("Thuyloi University",
/// dạng *Managed* - đăng nhập thẳng tại login.microsoftonline.com, không qua
/// ADFS liên kết), nên hộp thư đọc được bằng **Microsoft Graph**.
///
/// ┌──────────────────────────────────────────────────────────────────────┐
/// │ CẦN ĐIỀN [clientId] TRƯỚC KHI TÍNH NĂNG CHẠY ĐƯỢC                    │
/// │ Các bước đăng ký ứng dụng trên Azure: xem docs/AZURE_MAIL_SETUP.md   │
/// └──────────────────────────────────────────────────────────────────────┘
class MailConfig {
  MailConfig._();

  // ── Điền sau khi đăng ký ứng dụng trên Azure Portal ─────────────────────

  /// Application (client) ID của App Registration.
  ///
  /// Có thể truyền lúc build thay vì sửa file:
  ///   flutter build apk --dart-define=TLU_MAIL_CLIENT_ID=xxxxxxxx-...
  static const String clientId = String.fromEnvironment(
    'TLU_MAIL_CLIENT_ID',
    defaultValue: '', // ← dán Application (client) ID vào đây
  );

  /// Tenant dùng để dựng URL cấp quyền.
  ///
  /// Để nguyên ID của Thuỷ Lợi thì chỉ tài khoản @tlu.edu.vn đăng nhập được -
  /// đúng ý đồ ("email trường"). Đổi thành `'organizations'` nếu sau này muốn
  /// nhận tài khoản của trường khác, hoặc `'common'` để nhận cả tài khoản cá
  /// nhân Microsoft.
  static const String tenantId = 'bbf9aad6-5f58-4387-927e-02f0b07a72fa';

  /// Redirect URI kiểu native. Phần scheme phải trùng với
  /// `appAuthRedirectScheme` khai trong `android/app/build.gradle.kts` và với
  /// `CFBundleURLSchemes` trong `ios/Runner/Info.plist`.
  static const String redirectScheme = 'com.tlu.studyplanner';
  static const String redirectUri = '$redirectScheme://oauth2redirect';

  // ── Phần dưới đây thường không phải sửa ────────────────────────────────

  static const String _authority =
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0';

  static const String authorizationEndpoint = '$_authority/authorize';
  static const String tokenEndpoint = '$_authority/token';
  static const String endSessionEndpoint =
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/logout';

  /// Gốc của Microsoft Graph.
  static const String graphBase = 'https://graph.microsoft.com/v1.0';

  /// Quyền xin cấp. Cố tình **chỉ đọc**: `Mail.Read` không cho gửi hay sửa
  /// thư. `offline_access` là thứ đổi lấy refresh token - không có nó thì
  /// sinh viên phải đăng nhập lại mỗi giờ, trong khi yêu cầu là đăng nhập
  /// một lần duy nhất.
  ///
  /// `Mail.ReadWrite` chỉ cần nếu muốn đánh dấu đã đọc *ngược lên server*.
  /// Mặc định không xin, xem [markReadOnServer].
  static const List<String> scopes = <String>[
    'openid',
    'profile',
    'offline_access',
    'User.Read',
    'Mail.Read',
  ];

  /// Bật lên nếu muốn khi mở thư trong app thì server cũng đánh dấu đã đọc.
  /// Kèm theo phải đổi `'Mail.Read'` ở trên thành `'Mail.ReadWrite'`.
  static const bool markReadOnServer = false;

  /// Số thư tải về mỗi lần.
  static const int pageSize = 25;

  /// Đã cấu hình xong chưa - dùng để hiện thông báo thân thiện thay vì để
  /// luồng OAuth ném lỗi khó hiểu.
  static bool get isConfigured => clientId.isNotEmpty;
}

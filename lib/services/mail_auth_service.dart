import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tlustudy_planner/config/mail_config.dart';
import 'package:tlustudy_planner/services/log_service.dart';

/// Lỗi có thông điệp đọc được, để giao diện khỏi phải bóc tách chuỗi.
class MailAuthException implements Exception {
  MailAuthException(this.message, {this.needsRelink = false});

  final String message;

  /// Đúng khi phiên không cứu được nữa và sinh viên phải liên kết lại.
  final bool needsRelink;

  @override
  String toString() => message;
}

/// Đăng nhập hộp thư trường **một lần duy nhất**, rồi tự sống bằng refresh
/// token cất trong Keystore/Keychain.
///
/// Vì sao chia hai loại token:
///   * *access token* sống khoảng một giờ, chỉ để ký lên từng lời gọi Graph.
///     Nó nằm trong RAM, mất đi cũng không sao.
///   * *refresh token* mới là thứ đáng giữ - nó đổi lấy access token mới mà
///     không cần mở lại trình duyệt. Nó là thứ duy nhất được ghi xuống đĩa,
///     và ghi vào [FlutterSecureStorage] (Android KeyStore / iOS Keychain),
///     không phải SharedPreferences.
///
/// Luồng dùng PKCE và mở Custom Tab / ASWebAuthenticationSession chứ không
/// phải WebView nhúng: Microsoft chặn đăng nhập trong WebView, và mật khẩu
/// trường không bao giờ đi qua tay ứng dụng này.
class MailAuthService {
  MailAuthService._();

  static final MailAuthService instance = MailAuthService._();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final LogService _log = LogService();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kRefreshToken = 'tlu_mail_refresh_token';
  static const _kAccount = 'tlu_mail_account';
  static const _kDisplayName = 'tlu_mail_display_name';

  /// Access token đang dùng, kèm hạn - chỉ nằm trong bộ nhớ.
  String? _accessToken;
  DateTime? _accessTokenExpiry;

  String? _account;
  String? _displayName;

  /// Chạy một lần lúc khởi động: đọc lại xem có phiên cũ không.
  Future<void> restore() async {
    try {
      _account = await _storage.read(key: _kAccount);
      _displayName = await _storage.read(key: _kDisplayName);
    } catch (_) {
      _account = null;
      _displayName = null;
    }
  }

  /// Địa chỉ hộp thư đã liên kết, hoặc null.
  String? get account => _account;

  String? get displayName => _displayName;

  /// Đã liên kết chưa. Chỉ dựa vào việc có tài khoản lưu trong keystore -
  /// đủ để giao diện quyết định hiện danh sách hay hiện "Vui lòng liên kết".
  bool get isLinked => (_account ?? '').isNotEmpty;

  Future<bool> get hasRefreshToken async {
    try {
      final token = await _storage.read(key: _kRefreshToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Liên kết ────────────────────────────────────────────────────────────

  /// Mở trình duyệt hệ thống cho sinh viên đăng nhập, rồi cất refresh token.
  ///
  /// Trả về địa chỉ hộp thư đã liên kết. Ném [MailAuthException] khi sinh
  /// viên bấm huỷ hoặc cấu hình còn thiếu.
  Future<String> link() async {
    if (!MailConfig.isConfigured) {
      throw MailAuthException(
        'Ứng dụng chưa được cấu hình để kết nối email. '
        'Vui lòng cập nhật lên phiên bản mới hơn.',
      );
    }

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          MailConfig.clientId,
          MailConfig.redirectUri,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: MailConfig.authorizationEndpoint,
            tokenEndpoint: MailConfig.tokenEndpoint,
            endSessionEndpoint: MailConfig.endSessionEndpoint,
          ),
          scopes: MailConfig.scopes,
          // Buộc hiện màn hình chọn tài khoản: máy dùng chung, hoặc sinh viên
          // đã đăng nhập sẵn tài khoản cá nhân trong trình duyệt, thì không
          // nên im lặng liên kết nhầm hộp thư.
          promptValues: const ['select_account'],
        ),
      );

      _applyTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiry: result.accessTokenExpirationDateTime,
      );

      final claims = _decodeIdToken(result.idToken);
      final account = (claims['preferred_username'] ??
              claims['upn'] ??
              claims['email'] ??
              '')
          .toString();
      final name = (claims['name'] ?? '').toString();

      if (account.isEmpty) {
        throw MailAuthException('Không đọc được địa chỉ email từ tài khoản.');
      }

      _account = account;
      _displayName = name.isEmpty ? account : name;

      await _storage.write(key: _kAccount, value: _account);
      await _storage.write(key: _kDisplayName, value: _displayName);
      if (result.refreshToken != null) {
        await _storage.write(key: _kRefreshToken, value: result.refreshToken);
      }

      _log.log('Đã liên kết hộp thư $account', level: LogLevel.info);
      return account;
    } on MailAuthException {
      rethrow;
    } catch (e) {
      // Người dùng bấm back trong Custom Tab cũng rơi vào đây; phân biệt bằng
      // chuỗi lỗi của plugin để khỏi hiện thông báo lỗi đỏ cho một thao tác
      // hoàn toàn bình thường.
      final text = e.toString().toLowerCase();
      if (text.contains('cancel') || text.contains('user_cancel')) {
        throw MailAuthException('Đã huỷ liên kết email');
      }
      _log.log('Liên kết hộp thư thất bại: $e', level: LogLevel.error);
      throw MailAuthException('Không thể liên kết email: $e');
    }
  }

  /// Xoá sạch phiên khỏi máy.
  Future<void> unlink() async {
    _accessToken = null;
    _accessTokenExpiry = null;
    _account = null;
    _displayName = null;
    try {
      await _storage.delete(key: _kRefreshToken);
      await _storage.delete(key: _kAccount);
      await _storage.delete(key: _kDisplayName);
    } catch (_) {
      // Keystore hỏng thì cũng không còn gì để làm thêm.
    }
  }

  // ── Access token ────────────────────────────────────────────────────────

  /// Trả về access token còn hạn, tự làm mới nếu cần.
  ///
  /// Đây là điểm vào duy nhất của mọi lời gọi Graph, nên toàn bộ logic hết
  /// hạn nằm gọn ở một chỗ.
  Future<String> accessToken() async {
    final token = _accessToken;
    final expiry = _accessTokenExpiry;

    // Làm mới sớm 2 phút: một lời gọi mạng chậm có thể vắt qua đúng thời điểm
    // token hết hạn và trả về 401 khó lần ra nguyên nhân.
    if (token != null &&
        expiry != null &&
        DateTime.now().isBefore(expiry.subtract(const Duration(minutes: 2)))) {
      return token;
    }

    return _refresh();
  }

  Future<String> _refresh() async {
    String? refreshToken;
    try {
      refreshToken = await _storage.read(key: _kRefreshToken);
    } catch (_) {
      refreshToken = null;
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw MailAuthException(
        'Phiên đăng nhập email đã hết hạn. Vui lòng liên kết lại.',
        needsRelink: true,
      );
    }

    try {
      final result = await _appAuth.token(
        TokenRequest(
          MailConfig.clientId,
          MailConfig.redirectUri,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: MailConfig.authorizationEndpoint,
            tokenEndpoint: MailConfig.tokenEndpoint,
            endSessionEndpoint: MailConfig.endSessionEndpoint,
          ),
          refreshToken: refreshToken,
          grantType: 'refresh_token',
          scopes: MailConfig.scopes,
        ),
      );

      _applyTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiry: result.accessTokenExpirationDateTime,
      );

      // Entra ID xoay vòng refresh token: bản cũ chết ngay khi bản mới sinh
      // ra, nên phải ghi đè, không thì lần làm mới sau sẽ hỏng.
      if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
        await _storage.write(key: _kRefreshToken, value: result.refreshToken);
      }

      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw MailAuthException(
          'Không lấy được phiên email mới. Vui lòng liên kết lại.',
          needsRelink: true,
        );
      }
      return token;
    } catch (e) {
      _log.log('Làm mới token hộp thư thất bại: $e', level: LogLevel.error);
      // Refresh token bị thu hồi (đổi mật khẩu, quản trị viên gỡ quyền) là
      // hỏng vĩnh viễn - dọn luôn để giao diện quay về trạng thái chưa liên
      // kết thay vì thử lại vô ích ở mỗi lần mở app.
      await unlink();
      throw MailAuthException(
        'Phiên đăng nhập email đã hết hạn. Vui lòng liên kết lại.',
        needsRelink: true,
      );
    }
  }

  void _applyTokens({
    String? accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) {
    _accessToken = accessToken;
    // Không có hạn thì coi như 55 phút - ngắn hơn mặc định một giờ của
    // Microsoft, thà làm mới thừa còn hơn dùng token đã chết.
    _accessTokenExpiry =
        expiry ?? DateTime.now().add(const Duration(minutes: 55));
  }

  /// Bóc phần payload của id_token để lấy email và tên.
  ///
  /// Không kiểm chữ ký: token vừa nhận trực tiếp từ endpoint của Microsoft
  /// qua TLS trong cùng lời gọi này, và nó chỉ dùng để hiển thị - mọi quyết
  /// định về quyền đều do server làm khi kiểm access token.
  Map<String, dynamic> _decodeIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return <String, dynamic>{};
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return <String, dynamic>{};
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

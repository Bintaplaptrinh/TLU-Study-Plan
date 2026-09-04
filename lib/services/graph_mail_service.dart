import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:tlustudy_planner/config/app_info.dart';
import 'package:tlustudy_planner/config/mail_config.dart';
import 'package:tlustudy_planner/models/mail_message.dart';
import 'package:tlustudy_planner/services/log_service.dart';
import 'package:tlustudy_planner/services/mail_auth_service.dart';

/// Lớp bọc các endpoint REST của Microsoft Graph mà app dùng đến.
///
/// Chỉ đọc, đúng như yêu cầu: không có gửi thư, không có trả lời, không có
/// xoá. Mỗi hàm ứng với một endpoint:
///
///   GET  /me/mailFolders/inbox/messages          → [fetchMessages]
///   GET  /me/messages/{id}                       → [fetchMessage]
///   GET  /me/messages/{id}/attachments           → [fetchAttachments]
///   GET  /me/messages/{id}/attachments/{aid}/$value → [downloadAttachment]
///   GET  /me/mailFolders/inbox                   → [unreadCount]
///   PATCH /me/messages/{id}  {isRead:true}       → [markRead] (tuỳ chọn)
class GraphMailService {
  GraphMailService._();

  static final GraphMailService instance = GraphMailService._();

  final MailAuthService _auth = MailAuthService.instance;
  final LogService _log = LogService();

  // ── Danh sách thư ───────────────────────────────────────────────────────

  /// Lấy [MailConfig.pageSize] thư mới nhất trong Hộp thư đến.
  ///
  /// [skip] để tải thêm trang sau. `$select` cắt bớt trường không dùng - thư
  /// có thân HTML dài vài trăm KB, tải hết cho một danh sách là phí băng
  /// thông và pin.
  Future<List<MailMessage>> fetchMessages({int skip = 0}) async {
    final uri = Uri.parse(
      '${MailConfig.graphBase}/me/mailFolders/inbox/messages'
      '?\$select=id,subject,from,bodyPreview,receivedDateTime,isRead,'
      'hasAttachments,importance,webLink'
      '&\$orderby=receivedDateTime desc'
      '&\$top=${MailConfig.pageSize}'
      '&\$skip=$skip',
    );

    final json = await _getJson(uri);
    final value = json['value'];
    if (value is! List) return const <MailMessage>[];

    return [
      for (final item in value)
        if (item is Map<String, dynamic>) MailMessage.fromJson(item),
    ];
  }

  /// Tải đầy đủ một thư, gồm cả thân thư.
  Future<MailMessage> fetchMessage(String id) async {
    final uri = Uri.parse(
      '${MailConfig.graphBase}/me/messages/${Uri.encodeComponent(id)}'
      '?\$select=id,subject,from,toRecipients,body,bodyPreview,'
      'receivedDateTime,isRead,hasAttachments,importance,webLink',
    );
    return MailMessage.fromJson(await _getJson(uri));
  }

  /// Danh sách tệp đính kèm (không tải nội dung).
  Future<List<MailAttachment>> fetchAttachments(String messageId) async {
    final uri = Uri.parse(
      '${MailConfig.graphBase}/me/messages/${Uri.encodeComponent(messageId)}'
      '/attachments?\$select=id,name,size,contentType',
    );

    final json = await _getJson(uri);
    final value = json['value'];
    if (value is! List) return const <MailAttachment>[];

    return [
      for (final item in value)
        if (item is Map<String, dynamic>) MailAttachment.fromJson(item),
    ];
  }

  /// Tải một tệp đính kèm về thư mục tạm và trả về đường dẫn.
  ///
  /// Dùng `/$value` để nhận thẳng byte thay vì JSON có `contentBytes` mã hoá
  /// base64 - tiết kiệm được một phần ba dung lượng truyền và cả bước giải mã.
  Future<File> downloadAttachment(
    String messageId,
    MailAttachment attachment,
  ) async {
    final uri = Uri.parse(
      '${MailConfig.graphBase}/me/messages/${Uri.encodeComponent(messageId)}'
      '/attachments/${Uri.encodeComponent(attachment.id)}/\$value',
    );

    final token = await _auth.accessToken();
    final response = await http.get(uri, headers: _headers(token)).timeout(
          const Duration(seconds: 60),
        );

    if (response.statusCode != 200) {
      throw MailAuthException(
        'Không tải được tệp đính kèm (mã ${response.statusCode})',
      );
    }

    final dir = await getTemporaryDirectory();
    final folder = Directory(p.join(dir.path, 'tlu_mail_attachments'));
    if (!await folder.exists()) await folder.create(recursive: true);

    // Tên tệp từ thư người khác gửi là dữ liệu không tin được: một cái tên
    // như "../../shared_prefs/x.xml" sẽ ghi ra ngoài thư mục tạm. Chỉ giữ
    // phần tên cuối và thay ký tự lạ.
    final safeName = p
        .basename(attachment.name)
        .replaceAll(RegExp(r'[^A-Za-z0-9._\- ]'), '_');
    final file = File(p.join(folder.path, safeName.isEmpty ? 'tep' : safeName));

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Số thư chưa đọc trong Hộp thư đến - dùng cho badge và thông báo.
  Future<int> unreadCount() async {
    final uri = Uri.parse(
      '${MailConfig.graphBase}/me/mailFolders/inbox'
      '?\$select=unreadItemCount',
    );
    final json = await _getJson(uri);
    final count = json['unreadItemCount'];
    return count is num ? count.toInt() : 0;
  }

  /// Đánh dấu đã đọc trên server. Chỉ chạy khi [MailConfig.markReadOnServer]
  /// bật *và* phạm vi quyền có `Mail.ReadWrite`; ngược lại lặng lẽ bỏ qua để
  /// một lỗi 403 không phá trải nghiệm mở thư.
  Future<void> markRead(String messageId) async {
    if (!MailConfig.markReadOnServer) return;

    try {
      final token = await _auth.accessToken();
      final uri = Uri.parse(
        '${MailConfig.graphBase}/me/messages/${Uri.encodeComponent(messageId)}',
      );
      await http
          .patch(
            uri,
            headers: {..._headers(token), 'Content-Type': 'application/json'},
            body: jsonEncode({'isRead': true}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      _log.log('Không đánh dấu đã đọc được: $e', level: LogLevel.warning);
    }
  }

  // ── Hạ tầng chung ───────────────────────────────────────────────────────

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'User-Agent': AppInfo.userAgent,
      };

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final token = await _auth.accessToken();

    http.Response response;
    try {
      response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw MailAuthException('Không có kết nối mạng.');
    } catch (e) {
      throw MailAuthException('Lỗi kết nối tới hộp thư: $e');
    }

    if (response.statusCode == 401) {
      // Token bị thu hồi giữa chừng. `accessToken()` đã lo phần hết hạn, nên
      // 401 ở đây nghĩa là chính quyền truy cập không còn giá trị.
      throw MailAuthException(
        'Phiên đăng nhập email đã hết hạn. Vui lòng liên kết lại.',
        needsRelink: true,
      );
    }

    if (response.statusCode == 403) {
      throw MailAuthException(
        'Tài khoản chưa được cấp quyền đọc thư. Vui lòng liên hệ quản trị.',
      );
    }

    if (response.statusCode != 200) {
      _log.log(
        'Graph trả về ${response.statusCode}: ${response.body}',
        level: LogLevel.error,
      );
      throw MailAuthException('Không tải được thư (mã ${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}

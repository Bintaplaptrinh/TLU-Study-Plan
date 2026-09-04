import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlustudy_planner/config/mail_config.dart';
import 'package:tlustudy_planner/models/mail_message.dart';
import 'package:tlustudy_planner/services/graph_mail_service.dart';
import 'package:tlustudy_planner/services/mail_auth_service.dart';
import 'package:tlustudy_planner/services/notification_service.dart';

/// Trạng thái hộp thư trường cho toàn bộ giao diện.
///
/// Giữ danh sách thư trong bộ nhớ chứ không xuống SQLite: nội dung thư là dữ
/// liệu riêng tư và thường xuyên đổi, cache nó xuống đĩa được lợi rất ít mà
/// lại thêm một chỗ phải nhớ xoá khi sinh viên huỷ liên kết.
class MailProvider extends ChangeNotifier {
  MailProvider();

  final MailAuthService _auth = MailAuthService.instance;
  final GraphMailService _graph = GraphMailService.instance;

  static const String _kNotifyNewMail = 'mailNotificationsEnabled';
  static const String _kLastSeenMailId = 'mailLastSeenId';

  SharedPreferences? _prefs;

  List<MailMessage> _messages = const <MailMessage>[];
  bool _isLoading = false;
  bool _isLinking = false;
  bool _hasLoadedOnce = false;
  String? _error;
  bool _notifyNewMail = true;

  // ── Trạng thái đọc được từ giao diện ────────────────────────────────────

  List<MailMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLinking => _isLinking;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get error => _error;

  bool get isLinked => _auth.isLinked;
  String? get account => _auth.account;
  String? get displayName => _auth.displayName;

  /// Cấu hình OAuth đã sẵn sàng chưa (client ID đã điền chưa).
  bool get isConfigured => MailConfig.isConfigured;

  bool get notifyNewMail => _notifyNewMail;

  int get unreadCount => _messages.where((m) => m.isUnread).length;

  // ── Khởi tạo ────────────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _notifyNewMail = _prefs?.getBool(_kNotifyNewMail) ?? true;
    await _auth.restore();
    notifyListeners();
  }

  // ── Liên kết / huỷ liên kết ─────────────────────────────────────────────

  /// Mở luồng OAuth. Trả về true khi liên kết thành công.
  Future<bool> link() async {
    if (_isLinking) return false;
    _isLinking = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.link();
      _isLinking = false;
      notifyListeners();
      await refresh();
      return true;
    } on MailAuthException catch (e) {
      _isLinking = false;
      // Huỷ giữa chừng không phải lỗi - đừng bôi đỏ màn hình vì nó.
      _error = e.message.contains('huỷ') ? null : e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLinking = false;
      _error = 'Không thể liên kết email: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> unlink() async {
    await _auth.unlink();
    _messages = const <MailMessage>[];
    _hasLoadedOnce = false;
    _error = null;
    await _prefs?.remove(_kLastSeenMailId);
    notifyListeners();
  }

  // ── Tải thư ─────────────────────────────────────────────────────────────

  /// Tải lại danh sách thư. [silent] để chạy nền mà không hiện vòng quay.
  Future<void> refresh({bool silent = false}) async {
    if (!isLinked) return;
    if (_isLoading) return;

    _isLoading = !silent;
    if (!silent) {
      _error = null;
      notifyListeners();
    }

    try {
      final list = await _graph.fetchMessages();
      _messages = list;
      _hasLoadedOnce = true;
      _error = null;
      await _notifyIfNewMail(list);
    } on MailAuthException catch (e) {
      _error = e.message;
      // Phiên chết hẳn: xoá luôn để màn hình quay về "Vui lòng liên kết"
      // thay vì kẹt ở một danh sách cũ không bao giờ làm mới được.
      if (e.needsRelink) {
        _messages = const <MailMessage>[];
        _hasLoadedOnce = false;
      }
    } catch (e) {
      _error = 'Không tải được thư: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải đầy đủ một thư (thân thư + đính kèm) khi mở thẻ.
  Future<MailMessage> loadMessage(String id) async {
    final full = await _graph.fetchMessage(id);
    _replace(full.copyWith(isRead: true));
    // Đánh dấu đã đọc phía server nếu bật trong cấu hình.
    await _graph.markRead(id);
    return full;
  }

  Future<List<MailAttachment>> loadAttachments(String messageId) =>
      _graph.fetchAttachments(messageId);

  Future<String> downloadAttachment(
    String messageId,
    MailAttachment attachment,
  ) async {
    final file = await _graph.downloadAttachment(messageId, attachment);
    return file.path;
  }

  /// Đánh dấu đã đọc trong danh sách hiện tại (chỉ phía máy).
  void markReadLocally(String id) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index < 0 || _messages[index].isRead) return;
    _replace(_messages[index].copyWith(isRead: true));
  }

  void _replace(MailMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index < 0) return;
    final next = List<MailMessage>.from(_messages);
    // Giữ nguyên đoạn xem trước và cờ đính kèm của bản trong danh sách - bản
    // đầy đủ có thể thiếu trường nếu `$select` khác nhau giữa hai lời gọi.
    next[index] = message;
    _messages = next;
    notifyListeners();
  }

  // ── Thông báo thư mới ───────────────────────────────────────────────────

  Future<void> setNotifyNewMail(bool value) async {
    _notifyNewMail = value;
    await _prefs?.setBool(_kNotifyNewMail, value);
    notifyListeners();
  }

  /// Bắn thông báo hệ thống cho những thư chưa đọc xuất hiện *sau* lần kiểm
  /// tra trước.
  ///
  /// Mốc so sánh là id của thư mới nhất từng thấy, không phải thời gian: đồng
  /// hồ máy có thể lệch, và Graph trả danh sách đã sắp xếp sẵn nên "những thư
  /// đứng trước id đã thấy" chính là phần mới.
  Future<void> _notifyIfNewMail(List<MailMessage> list) async {
    if (!_notifyNewMail || list.isEmpty) return;

    final lastSeen = _prefs?.getString(_kLastSeenMailId);
    // Lần đầu tiên sau khi liên kết: chỉ ghi mốc, không dội một loạt thông
    // báo cho toàn bộ hộp thư cũ.
    if (lastSeen == null) {
      await _prefs?.setString(_kLastSeenMailId, list.first.id);
      return;
    }
    if (lastSeen == list.first.id) return;

    final cutoff = list.indexWhere((m) => m.id == lastSeen);
    final fresh = (cutoff < 0 ? list.take(1) : list.take(cutoff))
        .where((m) => m.isUnread)
        .toList();

    await _prefs?.setString(_kLastSeenMailId, list.first.id);
    if (fresh.isEmpty) return;

    final notifications = NotificationService();

    if (fresh.length == 1) {
      final mail = fresh.first;
      await notifications.showImmediateNotification(
        id: mail.id.hashCode & 0x7FFFFFFF,
        title: mail.displaySender,
        body: mail.displaySubject,
        payload: 'mail:${mail.id}',
      );
    } else {
      // Nhiều thư cùng lúc thì gộp lại - dội năm thông báo liền nhau là cách
      // nhanh nhất để sinh viên tắt hẳn thông báo của app.
      await notifications.showImmediateNotification(
        id: 'tlu_mail_group'.hashCode & 0x7FFFFFFF,
        title: 'Có ${fresh.length} thư mới',
        body: fresh.take(3).map((m) => m.displaySubject).join(' • '),
        payload: 'mail:',
      );
    }
  }
}

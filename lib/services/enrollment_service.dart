import 'dart:convert';
import 'dart:io';

import 'package:tlustudy_planner/models/enrollment.dart';
import 'package:tlustudy_planner/services/auth_service.dart';
import 'package:tlustudy_planner/services/log_service.dart';

/// Gọi các API đăng ký học phần của cổng sinh viên.
///
/// Ba endpoint, tất cả dưới `/api/cs_reg_mongo/` và đều nhận cặp
/// `{studentId}/{periodId}` trên đường dẫn:
///
/// | Việc | Method | Path |
/// |---|---|---|
/// | Nạp dữ liệu đợt | GET | `findByPeriod/{studentId}/{periodId}` |
/// | Đăng ký lớp | POST | `add-register/{studentId}/{periodId}` |
/// | Hủy đăng ký | DELETE | `remove-register/{studentId}/{periodId}` |
///
/// Với hai endpoint ghi, body là **nguyên object lớp học phần** lấy từ
/// `findByPeriod` - xem `docs/enrollment_feature.md` mục 5 và 6.
class EnrollmentService {
  static final LogService _log = LogService();

  /// Dùng chung base URL và timeout với [AuthService] để chỉ có một nơi
  /// cần sửa khi cổng đổi địa chỉ.
  static const String _baseUrl = AuthService.baseUrl;
  static const Duration _timeout = AuthService.apiTimeout;

  /// Cổng dùng chứng chỉ mà `HttpClient` mặc định từ chối, nên mọi request
  /// đều đi qua client đã nới kiểm tra - giống hệt [AuthService].
  HttpClient _client() => HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  void _addHeaders(HttpClientRequest request, String accessToken) {
    request.headers.add('Authorization', 'Bearer $accessToken');
    request.headers.add('Accept', 'application/json');
  }

  /// Lấy `studentId` - **không phải** id của user đăng nhập.
  ///
  /// Các endpoint đăng ký dùng id trong bảng sinh viên, lấy từ
  /// `GET /api/student/getstudentbylogin`.
  Future<int?> getStudentId(String accessToken) async {
    try {
      final student = await AuthService().getStudentByLogin(accessToken);
      final id = student['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      _log.log('Đăng ký học: không đọc được studentId', level: LogLevel.warning);
      return null;
    } catch (e) {
      _log.log('Đăng ký học: lỗi lấy studentId: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Nạp toàn bộ dữ liệu đăng ký của một đợt.
  ///
  /// `GET /api/cs_reg_mongo/findByPeriod/{studentId}/{periodId}`
  Future<EnrollmentView> findByPeriod(
    String accessToken,
    int studentId,
    int periodId,
  ) async {
    final path = '/api/cs_reg_mongo/findByPeriod/$studentId/$periodId';
    try {
      final client = _client();
      final request = await client.getUrl(Uri.parse('$_baseUrl$path'));
      _addHeaders(request, accessToken);

      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final view = EnrollmentView.fromJson(decoded);
          _log.log(
            'Đăng ký học: đợt $periodId có ${view.subjects.length} môn, '
            'đã đăng ký ${view.registeredCount}',
            level: LogLevel.success,
          );
          return view;
        }
        _log.log(
          'Đăng ký học: findByPeriod trả về dạng không mong đợi',
          level: LogLevel.warning,
        );
        return EnrollmentView.empty;
      }

      // 401/403 nghĩa là token hỏng chứ không phải sai đường dẫn - báo ra
      // để lớp trên còn kịp làm mới phiên.
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Phiên đăng nhập đã hết hạn (${response.statusCode})');
      }

      throw Exception('Không thể tải dữ liệu đăng ký (${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      rethrow;
    }
  }

  /// Đăng ký một lớp học phần.
  ///
  /// `POST /api/cs_reg_mongo/add-register/{studentId}/{periodId}`
  ///
  /// [classRaw] phải là map gốc của lớp (`CourseClass.raw`); server đọc nhiều
  /// trường phụ trợ nên không được rút gọn.
  Future<void> register(
    String accessToken,
    int studentId,
    int periodId,
    Map<String, dynamic> classRaw,
  ) {
    return _write(
      accessToken: accessToken,
      method: 'POST',
      path: '/api/cs_reg_mongo/add-register/$studentId/$periodId',
      classRaw: classRaw,
      label: 'Đăng ký lớp',
    );
  }

  /// Hủy đăng ký một lớp học phần.
  ///
  /// `DELETE /api/cs_reg_mongo/remove-register/{studentId}/{periodId}`
  Future<void> unregister(
    String accessToken,
    int studentId,
    int periodId,
    Map<String, dynamic> classRaw,
  ) {
    return _write(
      accessToken: accessToken,
      method: 'DELETE',
      path: '/api/cs_reg_mongo/remove-register/$studentId/$periodId',
      classRaw: classRaw,
      label: 'Hủy đăng ký lớp',
    );
  }

  /// Thân chung của đăng ký và hủy: chỉ khác method và đường dẫn.
  ///
  /// Ném [Exception] kèm thông điệp của server khi thất bại, để màn hình hiển
  /// thị đúng lý do ("lớp đã đầy", "ngoài thời gian đăng ký"...) thay vì một
  /// mã lỗi trần trụi.
  Future<void> _write({
    required String accessToken,
    required String method,
    required String path,
    required Map<String, dynamic> classRaw,
    required String label,
  }) async {
    final code = classRaw['code'] ?? classRaw['id'];
    try {
      final client = _client();
      final uri = Uri.parse('$_baseUrl$path');

      // `openUrl` để dùng được DELETE kèm body - `deleteUrl` cũng được nhưng
      // giữ một lối đi chung cho cả hai method thì dễ đọc hơn.
      final request = await client.openUrl(method, uri);
      _addHeaders(request, accessToken);
      request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

      final payload = utf8.encode(jsonEncode(classRaw));
      request.headers.contentLength = payload.length;
      request.add(payload);

      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log.log('$label $code: thành công', level: LogLevel.success);
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Phiên đăng nhập đã hết hạn (${response.statusCode})');
      }

      final reason = _serverMessage(body) ?? 'mã lỗi ${response.statusCode}';
      _log.log('$label $code thất bại: $reason', level: LogLevel.error);
      throw Exception(reason);
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      rethrow;
    }
  }

  /// Rút thông điệp lỗi mà cổng trả về.
  ///
  /// Cổng không nhất quán: khi thì `message`, khi thì `error_description`,
  /// đôi khi chỉ là một chuỗi trần. Trả `null` nếu không đọc được gì hữu ích.
  String? _serverMessage(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is String && decoded.isNotEmpty) return decoded;
      if (decoded is Map) {
        for (final key in [
          'message',
          'error_description',
          'error',
          'msg',
          'detail',
        ]) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) return value;
        }
      }
    } catch (_) {
      // Không phải JSON: dùng nguyên văn nếu đủ ngắn để hiển thị.
      final text = body.trim();
      if (text.length <= 200) return text;
    }
    return null;
  }
}

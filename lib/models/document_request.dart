/// Một dòng trong bảng theo dõi đơn của Phân hiệu.
///
/// Bảng là kết quả của một Google Form nên thứ tự cột là cố định và một vài
/// cột trong đó bị ẩn với sinh viên (địa chỉ email, địa chỉ thường trú...).
/// Ở đây chỉ giữ những cột sinh viên thực sự cần đọc.
library;

/// Trạng thái xử lý đơn - cột K của bảng.
enum DocumentRequestStatus {
  /// Đơn đã xong, sinh viên có thể tới lấy.
  completed('Đã hoàn thành'),

  /// Phân hiệu đã xem nhưng không xử lý được (sai thông tin, không thấy đơn...).
  notCompleted('Không hoàn thành'),

  /// Đang trong hàng đợi xử lý.
  processing('Đang xử lý'),

  /// Cột trạng thái còn trống - đơn vừa gửi, chưa ai chạm tới.
  pending('Chưa xử lý');

  const DocumentRequestStatus(this.label);

  final String label;

  /// Đọc trạng thái từ ô chữ trong bảng.
  ///
  /// So khớp lỏng vì người nhập gõ tay: "Đang xử lý" và "Đang xử lí" là cùng
  /// một trạng thái, và ô có thể thừa dấu cách hoặc viết hoa khác nhau.
  static DocumentRequestStatus parse(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return DocumentRequestStatus.pending;
    if (v.contains('không hoàn thành') || v.contains('khong hoan thanh')) {
      return DocumentRequestStatus.notCompleted;
    }
    if (v.contains('đã hoàn thành') || v.contains('da hoan thanh')) {
      return DocumentRequestStatus.completed;
    }
    if (v.contains('đang xử') || v.contains('dang xu')) {
      return DocumentRequestStatus.processing;
    }
    return DocumentRequestStatus.pending;
  }
}

/// Một lần nộp đơn của sinh viên.
class DocumentRequest {
  const DocumentRequest({
    required this.submittedAtRaw,
    required this.submittedAt,
    required this.type,
    required this.studentCode,
    required this.fullName,
    required this.className,
    required this.source,
    required this.statusRaw,
    required this.status,
    required this.condition,
    required this.notice,
  });

  /// Cột A, giữ nguyên chuỗi gốc để hiển thị khi không parse được ngày.
  final String submittedAtRaw;

  /// Cột A đã parse - `null` khi ô trống hoặc sai định dạng.
  final DateTime? submittedAt;

  /// Cột C - tên loại đơn.
  final String type;

  /// Cột D - mã số sinh viên.
  final String studentCode;

  /// Cột E - họ và tên.
  final String fullName;

  /// Cột F - tên lớp.
  final String className;

  /// Cột J - nộp qua mini app, tại phòng, từ xa...
  final String source;

  /// Cột K nguyên văn.
  final String statusRaw;

  /// Cột K đã phân loại.
  final DocumentRequestStatus status;

  /// Cột M - tình trạng đơn: đã lấy, đơn trùng, sai thông tin gì...
  final String condition;

  /// Cột N - thông báo chung của Phân hiệu (lịch nhận đơn, ghi chú...).
  final String notice;

  Map<String, String> toMap() => {
    'submittedAtRaw': submittedAtRaw,
    'type': type,
    'studentCode': studentCode,
    'fullName': fullName,
    'className': className,
    'source': source,
    'statusRaw': statusRaw,
    'condition': condition,
    'notice': notice,
  };

  /// Dựng lại từ [toMap] - dùng khi dữ liệu đi qua isolate hoặc bộ nhớ đệm.
  factory DocumentRequest.fromMap(Map<String, dynamic> map) {
    final raw = (map['submittedAtRaw'] ?? '').toString();
    final statusRaw = (map['statusRaw'] ?? '').toString();
    return DocumentRequest(
      submittedAtRaw: raw,
      submittedAt: parseSheetDate(raw),
      type: (map['type'] ?? '').toString(),
      studentCode: (map['studentCode'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      className: (map['className'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      statusRaw: statusRaw,
      status: DocumentRequestStatus.parse(statusRaw),
      condition: (map['condition'] ?? '').toString(),
      notice: (map['notice'] ?? '').toString(),
    );
  }

  /// Đọc dấu thời gian kiểu Google Form: `dd/MM/yyyy H:mm:ss`.
  ///
  /// Không dùng `DateTime.parse` được vì chuỗi là ngày trước tháng; và ô trống
  /// là chuyện thường (nhiều dòng được nhập tay chứ không qua form).
  static DateTime? parseSheetDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final m = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:[ ,]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(v);
    if (m == null) return null;
    try {
      return DateTime(
        int.parse(m.group(3)!),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
        int.parse(m.group(4) ?? '0'),
        int.parse(m.group(5) ?? '0'),
        int.parse(m.group(6) ?? '0'),
      );
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:tlustudy_planner/models/document_request.dart';

/// Tra cứu tình trạng đơn của sinh viên trong bảng theo dõi của Phân hiệu.
///
/// Bảng là một Google Sheet công khai (kết quả của Google Form). Thay vì nhúng
/// nguyên trang sheet - rộng mười mấy cột, cuộn ngang trên điện thoại thì gần
/// như không đọc nổi - ở đây tải bản CSV rồi lọc ra đúng những dòng của sinh
/// viên đang đăng nhập.
///
/// Bản CSV nặng vài megabyte (hơn mười nghìn dòng từ 2023 tới nay) nhưng đi
/// qua đường truyền đã nén còn khoảng 600 KB, và việc tách dòng được đẩy sang
/// isolate khác nên danh sách hiện ra không giật.
class DocumentRequestService {
  DocumentRequestService._();

  static final DocumentRequestService instance = DocumentRequestService._();

  /// Bảng theo dõi đơn của Phân hiệu.
  static const String spreadsheetId =
      '11oikKuckPA2w_WX_FwyTRd78BJexdNyoRrXC1yfDY4U';

  /// Tab chứa dữ liệu - cùng `gid` với đường dẫn htmlview mà Phân hiệu công bố.
  static const String sheetGid = '1804533748';

  /// Trang sheet dạng người đọc, để mở ra khi cần đối chiếu bản gốc.
  static const String htmlViewUrl =
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/htmlview#gid=$sheetGid';

  static Uri get _csvUri => Uri.parse(
    'https://docs.google.com/spreadsheets/d/$spreadsheetId/export'
    '?format=csv&gid=$sheetGid',
  );

  static const Duration _timeout = Duration(seconds: 30);

  /// Giữ kết quả đã lọc trong 15 phút.
  ///
  /// Bảng chỉ được cập nhật khi Phân hiệu xử lý đơn (vài lần một tuần), nên
  /// tải lại toàn bộ CSV mỗi lần mở trang là phí. Người dùng vẫn kéo xuống để
  /// làm mới được khi vừa nộp đơn xong.
  static const Duration cacheTtl = Duration(minutes: 15);

  static String? _cacheKey;
  static List<DocumentRequest>? _cached;
  static DateTime? _cachedAt;

  /// Thời điểm dữ liệu đang giữ được tải về, `null` nếu chưa tải lần nào.
  DateTime? get lastFetchedAt => _cachedAt;

  /// Danh sách đơn của một sinh viên, mới nhất lên trước.
  ///
  /// Khớp theo mã số sinh viên **hoặc** họ tên: nhiều em gõ nhầm mã khi điền
  /// form, và ngược lại có em viết tên không dấu - lấy hợp của hai phép so
  /// khớp thì không bỏ sót đơn nào của mình.
  Future<List<DocumentRequest>> fetchForStudent({
    required String studentCode,
    required String fullName,
    bool forceRefresh = false,
  }) async {
    final key = '${studentCode.trim()}|${fullName.trim().toLowerCase()}';
    final cached = _cached;
    final cachedAt = _cachedAt;

    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        _cacheKey == key &&
        DateTime.now().difference(cachedAt) < cacheTtl) {
      return cached;
    }

    final response = await http
        .get(_csvUri, headers: const {'Accept': 'text/csv'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw DocumentRequestException(
        'Máy chủ trả về mã ${response.statusCode}',
      );
    }

    // Google trả UTF-8 nhưng không phải lúc nào cũng khai báo charset, nên tự
    // giải mã thay vì tin vào `response.body`.
    final csv = utf8.decode(response.bodyBytes, allowMalformed: true);

    final rows = await compute(parseAndFilterDocumentCsv, <String, String>{
      'csv': csv,
      'code': studentCode,
      'name': fullName,
    });

    final result = rows.map(DocumentRequest.fromMap).toList()
      ..sort((a, b) {
        final x = a.submittedAt;
        final y = b.submittedAt;
        // Dòng không có dấu thời gian (nhập tay) xuống cuối, chứ không lẫn vào
        // giữa danh sách ở một vị trí ngẫu nhiên.
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return y.compareTo(x);
      });

    _cacheKey = key;
    _cached = List.unmodifiable(result);
    _cachedAt = DateTime.now();
    return _cached!;
  }

  /// Quên dữ liệu đã tải - gọi khi đăng xuất.
  static void clearCache() {
    _cacheKey = null;
    _cached = null;
    _cachedAt = null;
  }
}

/// Lỗi đọc bảng theo dõi đơn, kèm câu giải thích hiển thị được cho sinh viên.
class DocumentRequestException implements Exception {
  const DocumentRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ─────────────────────────────── Isolate side ────────────────────────────────

/// Vị trí các cột trong bảng, đếm từ 0.
const int _colTimestamp = 0; // A
const int _colType = 2; // C
const int _colStudentCode = 3; // D
const int _colFullName = 4; // E
const int _colClassName = 5; // F
const int _colSource = 9; // J
const int _colStatus = 10; // K
const int _colCondition = 12; // M
const int _colNotice = 13; // N

/// Chạy trong isolate riêng: tách CSV rồi chỉ trả về các dòng của sinh viên.
///
/// Trả `Map` chứ không phải [DocumentRequest] để dữ liệu đi qua ranh giới
/// isolate mà không phụ thuộc vào cách Dart chép đối tượng.
///
/// Ở cấp cao nhất và công khai vì [compute] chỉ nhận hàm top-level, và vì đây
/// là phần duy nhất của service kiểm thử được mà không cần mạng: đưa vào một
/// chuỗi CSV, nhận ra đúng những dòng của một sinh viên.
///
/// [args] gồm `csv`, `code` (mã sinh viên) và `name` (họ tên).
List<Map<String, String>> parseAndFilterDocumentCsv(Map<String, String> args) {
  final wantedCode = _normalizeCode(args['code'] ?? '');
  final wantedName = _normalizeName(args['name'] ?? '');
  final rows = _parseCsv(args['csv'] ?? '');

  final matches = <Map<String, String>>[];
  // Bỏ dòng đầu: đó là hàng tiêu đề của Google Form.
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;

    final code = _normalizeCode(_cell(row, _colStudentCode));
    final name = _normalizeName(_cell(row, _colFullName));

    final codeHit = wantedCode.isNotEmpty && code == wantedCode;
    final nameHit = wantedName.isNotEmpty && name == wantedName;
    if (!codeHit && !nameHit) continue;

    matches.add({
      'submittedAtRaw': _cell(row, _colTimestamp),
      'type': _cell(row, _colType),
      'studentCode': _cell(row, _colStudentCode),
      'fullName': _cell(row, _colFullName),
      'className': _cell(row, _colClassName),
      'source': _cell(row, _colSource),
      'statusRaw': _cell(row, _colStatus),
      'condition': _cell(row, _colCondition),
      'notice': _cell(row, _colNotice),
    });
  }
  return matches;
}

String _cell(List<String> row, int index) =>
    index < row.length ? row[index].trim() : '';

/// Mã số sinh viên chỉ gồm chữ số; bỏ mọi thứ khác để "2251018070 " và
/// "2251018070" là một.
String _normalizeCode(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

/// Chuẩn hoá họ tên trước khi so khớp: bỏ hoa/thường, gộp dấu cách thừa và bỏ
/// dấu tiếng Việt - nhiều em điền form bằng bàn phím không dấu.
String _normalizeName(String raw) {
  final lower = raw.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    buffer.write(_foldMap[String.fromCharCode(rune)] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

/// Bảng bỏ dấu, viết thẳng ra thay vì dùng chuẩn hoá Unicode vì Dart lõi không
/// có sẵn NFD và thêm một gói chỉ để làm việc này thì không đáng.
final Map<String, String> _foldMap = _buildFoldMap();

Map<String, String> _buildFoldMap() {
  const groups = <String, String>{
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final map = <String, String>{};
  groups.forEach((plain, accented) {
    for (final ch in accented.split('')) {
      map[ch] = plain;
    }
  });
  return map;
}

/// Bộ tách CSV theo RFC 4180.
///
/// Không dùng `split(',')` được: ô "Tình trạng đơn" thường xuyên chứa dấu phẩy
/// và cả xuống dòng bên trong cặp nháy kép.
List<List<String>> _parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  while (i < input.length) {
    final ch = input[i];

    if (inQuotes) {
      if (ch == '"') {
        // Hai nháy liền nhau là một nháy thật nằm trong nội dung ô.
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(ch);
      i++;
      continue;
    }

    if (ch == '"') {
      inQuotes = true;
      i++;
      continue;
    }
    if (ch == ',') {
      endField();
      i++;
      continue;
    }
    if (ch == '\r') {
      // CRLF hay CR đơn đều tính là hết dòng.
      if (i + 1 < input.length && input[i + 1] == '\n') i++;
      endRow();
      i++;
      continue;
    }
    if (ch == '\n') {
      endRow();
      i++;
      continue;
    }

    field.write(ch);
    i++;
  }

  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

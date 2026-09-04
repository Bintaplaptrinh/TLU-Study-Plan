import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/models/document_request.dart';
import 'package:tlustudy_planner/services/document_request_service.dart';

/// Bản thu nhỏ của bảng theo dõi đơn: cùng thứ tự cột với bản thật, đủ các ca
/// khó mà bảng thật có (ô trống, dấu phẩy và xuống dòng trong ô, viết hoa lẫn
/// lộn, tên không dấu).
const String _csv = '''
Dấu thời gian,Địa chỉ email,Bạn đang xác nhận giấy: ,MSSV,Họ tên,Lớp,NGÀNH HỌC,Ngày sinh,Số điện thoại,Nơi làm đơn:,Tình trạng xử lý,Địa chỉ thường trú (Theo CCCD),Tình trạng đơn,Thời gian nhận đơn
04/08/2026 16:37:48,an@gmail.com,Đơn xin hoãn NVQS,2251018070,Bùi Bảo Tín,S25-64CTN,CTN,20/10/2004,0353628124,Mini app,Đã hoàn thành,Quận 1,Đã lấy đơn,Nhận đơn chiều thứ 3 và thứ 5
,,Xác nhận sinh viên,2251018070,BÙI BẢO TÍN ,S25-64CTN,,,,Tại phòng,Đang xử lý,,,
08/08/2026 10:44:01,b@gmail.com,Xác nhận vay vốn sinh viên,9999999999,bui bao tin,S25-64CTN,,,,Mini app,Không hoàn thành,,"Sai thông tin khoá học, vui lòng điền lại","Ngưng nhận đơn 26/8
Xem thông báo trên trang khoa"
09/08/2026 08:00:00,c@gmail.com,Xác nhận sinh viên,2251099999,Người Khác,S25-64CTN,,,,Mini app,Đã hoàn thành,,Đã lấy đơn,
''';

List<DocumentRequest> _filter({String code = '', String name = ''}) =>
    parseAndFilterDocumentCsv({
      'csv': _csv,
      'code': code,
      'name': name,
    }).map(DocumentRequest.fromMap).toList();

void main() {
  group('Lọc bảng theo dõi đơn', () {
    test('khớp theo mã sinh viên', () {
      final rows = _filter(code: '2251018070', name: 'Không Trùng Ai');
      expect(rows.length, 2);
      expect(rows.every((r) => r.studentCode == '2251018070'), isTrue);
    });

    test('khớp theo họ tên bất kể hoa thường và dấu', () {
      // Dòng thứ ba mang mã khác nhưng cùng tên viết không dấu; dòng thứ hai
      // viết hoa toàn bộ và thừa dấu cách cuối.
      final rows = _filter(code: '0000000000', name: 'Bùi Bảo Tín');
      expect(rows.length, 3);
      expect(rows.map((r) => r.type), contains('Xác nhận vay vốn sinh viên'));
    });

    test('mã hoặc tên - lấy hợp của hai phép khớp, không nhân đôi dòng', () {
      final rows = _filter(code: '2251018070', name: 'Bùi Bảo Tín');
      expect(rows.length, 3);
    });

    test('không lấy đơn của người khác', () {
      final rows = _filter(code: '2251018070', name: 'Bùi Bảo Tín');
      expect(rows.any((r) => r.fullName == 'Người Khác'), isFalse);
    });

    test('mã sinh viên chỉ so phần chữ số', () {
      final rows = _filter(code: ' 2251018070 ');
      expect(rows.length, 2);
    });

    test('bỏ trống cả mã lẫn tên thì không khớp gì', () {
      expect(_filter().isEmpty, isTrue);
    });
  });

  group('Đọc từng ô', () {
    test('ô chứa dấu phẩy và xuống dòng vẫn nguyên vẹn', () {
      final row = _filter(code: '9999999999').single;
      expect(row.condition, 'Sai thông tin khoá học, vui lòng điền lại');
      expect(row.notice, contains('\n'));
      expect(row.notice, startsWith('Ngưng nhận đơn 26/8'));
    });

    test('lấy đúng cột J, K, M, N', () {
      final row = _filter(code: '2251018070').first;
      expect(row.type, 'Đơn xin hoãn NVQS');
      expect(row.className, 'S25-64CTN');
      expect(row.source, 'Mini app');
      expect(row.statusRaw, 'Đã hoàn thành');
      expect(row.condition, 'Đã lấy đơn');
      expect(row.notice, 'Nhận đơn chiều thứ 3 và thứ 5');
    });

    test('bỏ qua cột B (email) và các cột ẩn khác', () {
      final row = _filter(code: '2251018070').first;
      expect(row.toMap().values.join(' '), isNot(contains('@gmail.com')));
      expect(row.toMap().values.join(' '), isNot(contains('Quận 1')));
    });
  });

  group('Trạng thái và dấu thời gian', () {
    test('phân loại đúng bốn trạng thái', () {
      expect(
        DocumentRequestStatus.parse('Đã hoàn thành'),
        DocumentRequestStatus.completed,
      );
      expect(
        DocumentRequestStatus.parse('Không hoàn thành'),
        DocumentRequestStatus.notCompleted,
      );
      // "xử lí" và "xử lý" cùng xuất hiện trong bảng thật.
      expect(
        DocumentRequestStatus.parse('Đang xử lí'),
        DocumentRequestStatus.processing,
      );
      expect(
        DocumentRequestStatus.parse('  '),
        DocumentRequestStatus.pending,
      );
    });

    test('đọc dấu thời gian kiểu ngày/tháng/năm', () {
      final t = DocumentRequest.parseSheetDate('04/08/2026 16:37:48');
      expect(t, DateTime(2026, 8, 4, 16, 37, 48));
    });

    test('ô trống hoặc sai định dạng trả về null', () {
      expect(DocumentRequest.parseSheetDate(''), isNull);
      expect(DocumentRequest.parseSheetDate('không rõ'), isNull);
    });
  });
}

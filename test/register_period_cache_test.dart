import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/services/database_helper.dart';

/// Bảo vệ chỗ đã gây lỗi "Học kỳ này chưa có đợt đăng ký nào": trước đây
/// `saveSemesters` bỏ hẳn `semesterRegisterPeriods` và `getSemesters` luôn trả
/// danh sách rỗng, nên sau lần khởi động thứ hai (đọc từ cache) màn hình "Đăng
/// ký môn học" không còn đợt nào để chọn.
///
/// Hai hàm dưới đây là toàn bộ phần chuyển đổi giữa model và cột `periodsJson`,
/// nên kiểm được chúng mà không cần mở SQLite thật.
void main() {
  group('Cache đợt đăng ký', () {
    test('giữ nguyên id, tên và thứ tự sau một vòng lưu - đọc', () {
      final periods = [
        SemesterRegisterPeriod(id: 83, name: 'Học kỳ chính', displayOrder: 1),
        SemesterRegisterPeriod(id: 84, name: 'Học kỳ phụ', displayOrder: 2),
        SemesterRegisterPeriod(
          id: 85,
          name: 'Tiếng Anh tăng cường',
          displayOrder: 3,
        ),
      ];

      final restored = DatabaseHelper.decodeRegisterPeriods(
        DatabaseHelper.encodeRegisterPeriods(periods),
      );

      expect(restored.map((p) => p.id), [83, 84, 85]);
      expect(restored.map((p) => p.name), [
        'Học kỳ chính',
        'Học kỳ phụ',
        'Tiếng Anh tăng cường',
      ]);
      expect(restored.map((p) => p.displayOrder), [1, 2, 3]);
    });

    test('kỳ không có đợt nào được lưu thành null', () {
      expect(DatabaseHelper.encodeRegisterPeriods(const []), isNull);
    });

    test('dòng cũ (chưa có cột) và dòng hỏng đọc ra danh sách rỗng', () {
      // Bản ghi được ghi trước migration v7 không có `periodsJson`.
      expect(DatabaseHelper.decodeRegisterPeriods(null), isEmpty);
      expect(DatabaseHelper.decodeRegisterPeriods(''), isEmpty);
      // JSON hỏng chỉ được làm mất đợt của một kỳ, không được ném lỗi ra cả
      // lần đọc cache.
      expect(DatabaseHelper.decodeRegisterPeriods('{['), isEmpty);
      expect(DatabaseHelper.decodeRegisterPeriods('{"id":83}'), isEmpty);
    });
  });
}

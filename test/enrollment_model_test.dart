import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/models/enrollment.dart';

/// Fixture dựng theo **đúng tên và kiểu trường** quan sát được từ response thật
/// của `GET /api/cs_reg_mongo/findByPeriod/74053/83` (môn Học máy, đợt "Học kỳ
/// chính" kỳ 1_2026_2027).
///
/// Những chỗ dễ đoán nhầm đã được giữ nguyên như cổng trả về:
/// - `subjectName`, `teacherName`, `totalFee` của lớp là `null`;
/// - số tín chỉ là `0`, không phải giá trị thật;
/// - buổi học dùng `startDate`/`endDate` (epoch ms) chứ không phải chuỗi ngày,
///   còn `fromWeekStr`/`toWeekStr` thì luôn `null`;
/// - `startHour`/`endHour` là object có `name`;
/// - `weekIndex` là thứ trong tuần theo quy ước 2..8.
Map<String, dynamic> _fixture() => {
  'studentId': 74053,
  'periodId': 83,
  'courseRegisterViewObject': {
    'allowRegister': true,
    // Cổng trả false ngay cả khi vẫn cho hủy - xem ghi chú ở test bên dưới.
    'isAllowUnRegister': false,
    'startDateString': '24-08-2026 10:00:00',
    'endDateString': '27-08-2026 23:00:00',
    'startUnDateString': null,
    'endUnDateString': null,
    'listSubjectRegistrationDtos': [
      {
        'subjectName': 'Học máy',
        'registerPeriodId': 83,
        'hasParaSubject': false,
        'isForcedRegType': false,
        'paraSubjects': null,
        'dependSubjectNames': null,
        'isAllowSubjectUnRegister': true,
        'hasSubjectReg': null,
        'isUpgradeMark': null,
        'id': 975,
        'courseSubjectDtos': [
          {
            'id': 57219,
            'code': '261052_CSE445_S27-66TTNT',
            'shortCode': '261052_CSE445_S27-66TTNT',
            'displayName': 'Học máy-1-26 (S27-66TTNT)',
            'subjectId': 975,
            'subjectName': null,
            'voided': false,
            'isFullClass': false,
            'maxStudent': 30,
            'numberStudent': 10,
            'isSelected': false,
            'isOvelapTime': false,
            'numberOfCredit': 0,
            'totalFee': null,
            'feePerCredit': null,
            'teacherName': null,
            'timetables': [
              {
                'id': 1,
                'startHour': {'id': 10, 'name': 'Tiết 10', 'indexNumber': 10},
                'endHour': {'id': 12, 'name': 'Tiết 12', 'indexNumber': 12},
                'weekIndex': 4,
                'fromWeek': 11,
                'toWeek': 18,
                'fromWeekStr': null,
                'toWeekStr': null,
                'startDate': 1794182400000,
                'endDate': 1798934400000,
                'roomName': '301-PM1',
                'teacherName': 'Vũ Thị  Hạnh',
                'room': {'id': 148, 'name': '301-PM1', 'code': '301-PM1'},
              },
            ],
          },
          {
            'id': 57220,
            'code': '261052_CSE445_S27-66CNTT',
            'subjectId': 975,
            'isFullClass': true,
            'maxStudent': 40,
            'numberStudent': 40,
            'isSelected': false,
            'timetables': [],
          },
        ],
      },
    ],
  },
};

void main() {
  group('EnrollmentView.fromJson', () {
    test('đọc được mốc thời gian và danh sách môn của đợt', () {
      final view = EnrollmentView.fromJson(_fixture());

      expect(view.studentId, 74053);
      expect(view.periodId, 83);
      expect(view.allowRegister, isTrue);
      expect(view.subjects, hasLength(1));
      expect(view.windowLabel, '24-08-2026 10:00:00 → 27-08-2026 23:00:00');
    });

    test('mốc hủy null không làm vỡ parser', () {
      final view = EnrollmentView.fromJson(_fixture());
      expect(view.startUnDateString, isEmpty);
      expect(view.endUnDateString, isEmpty);
    });

    test('dependSubjectNames null trở thành danh sách rỗng', () {
      final subject = EnrollmentView.fromJson(_fixture()).subjects.first;
      expect(subject.dependSubjectNames, isEmpty);
      expect(subject.hasSubjectReg, isFalse);
    });

    test('cờ cho phép hủy lấy theo môn, không theo đợt', () {
      final json = _fixture();
      final view = EnrollmentView.fromJson(json);

      // Cổng trả `isAllowUnRegister: false` ở cấp đợt, nhưng thao tác hủy thật
      // vẫn thành công. Cờ đúng để khóa nút là cờ theo môn.
      expect(view.isAllowUnRegister, isFalse);
      expect(view.subjects.first.isAllowSubjectUnRegister, isTrue);
    });
  });

  group('CourseClass', () {
    test('đọc đúng mã lớp và sĩ số', () {
      final classes = EnrollmentView.fromJson(_fixture()).subjects.first.classes;
      expect(classes, hasLength(2));

      final ttnt = classes.first;
      expect(ttnt.id, 57219);
      expect(ttnt.code, '261052_CSE445_S27-66TTNT');
      expect(ttnt.capacityLabel, '10/30');
      expect(ttnt.isFull, isFalse);
      expect(ttnt.isSelected, isFalse);
    });

    test('lớp đủ sĩ số bị coi là đã đầy', () {
      final full = EnrollmentView.fromJson(_fixture()).subjects.first.classes[1];
      expect(full.isFull, isTrue);
      expect(full.capacityLabel, '40/40');
    });

    test('subjectName null thì rơi về displayName', () {
      final ttnt = EnrollmentView.fromJson(
        _fixture(),
      ).subjects.first.classes.first;
      expect(ttnt.subjectName, 'Học máy-1-26 (S27-66TTNT)');
    });

    test('teacherName null thì lấy giảng viên từ buổi học', () {
      final ttnt = EnrollmentView.fromJson(
        _fixture(),
      ).subjects.first.classes.first;
      expect(ttnt.teacherName, isEmpty);
      expect(ttnt.displayTeacher, 'Vũ Thị  Hạnh');
    });

    test('giữ nguyên map gốc để gửi lại khi đăng ký', () {
      final ttnt = EnrollmentView.fromJson(
        _fixture(),
      ).subjects.first.classes.first;

      // Body của POST add-register là chính map này, nên các trường phụ trợ
      // phải còn nguyên chứ không được rút gọn.
      expect(ttnt.raw['shortCode'], '261052_CSE445_S27-66TTNT');
      expect(ttnt.raw['voided'], false);
      expect(ttnt.raw.containsKey('timetables'), isTrue);
    });
  });

  group('ClassTimetable', () {
    test('dựng nhãn thứ, tiết, tuần từ dữ liệu thật', () {
      final tt = EnrollmentView.fromJson(
        _fixture(),
      ).subjects.first.classes.first.timetables.single;

      expect(tt.dayLabel, 'Thứ 4');
      expect(tt.hourLabel, 'Tiết 10 → Tiết 12');
      expect(tt.roomName, '301-PM1');
      // Ngày lấy từ epoch ms chứ không phải chuỗi có sẵn.
      expect(tt.weekLabel, contains('Tuần 11 → 18'));
      expect(tt.weekLabel, contains('/2026'));
      expect(tt.weekLabel, contains('/2027'));
    });

    test('chủ nhật là weekIndex 8', () {
      final tt = ClassTimetable.fromJson({
        'weekIndex': 8,
        'fromWeek': 1,
        'toWeek': 1,
        'startHour': {'name': 'Tiết 1'},
        'endHour': {'name': 'Tiết 1'},
      });
      expect(tt.dayLabel, 'Chủ nhật');
      // Cùng một tiết thì không lặp lại hai lần.
      expect(tt.hourLabel, 'Tiết 1');
    });

    test('thiếu mốc ngày thì chỉ hiện khoảng tuần', () {
      final tt = ClassTimetable.fromJson({
        'weekIndex': 2,
        'fromWeek': 3,
        'toWeek': 5,
        'startDate': null,
        'endDate': null,
      });
      expect(tt.weekLabel, 'Tuần 3 → 5');
    });
  });

  test('EnrollmentView rỗng khi payload không có gì', () {
    final view = EnrollmentView.fromJson({});
    expect(view.isEmpty, isTrue);
    expect(view.allowRegister, isFalse);
    expect(view.registeredCount, 0);
    expect(view.windowLabel, isEmpty);
  });
}

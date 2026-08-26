/// Models cho tính năng "Đăng ký môn học" (`#/enrollment_newreg` trên cổng SV).
///
/// Nguồn dữ liệu: `GET /api/cs_reg_mongo/findByPeriod/{studentId}/{periodId}`.
/// Xem `docs/enrollment_feature.md` để biết chi tiết truy vết API.
///
/// Nguyên tắc quan trọng: khi đăng ký / hủy, body gửi lên server phải là
/// **nguyên object lớp học phần** nhận từ `findByPeriod`. Vì vậy mọi model ở
/// đây đều giữ lại [raw] - map JSON gốc - thay vì dựng lại object rút gọn.
library;

/// Một buổi học trong thời khóa biểu của lớp học phần.
class ClassTimetable {
  final int fromWeek;
  final int toWeek;

  /// Mốc đầu/cuối của khoảng tuần, tính bằng milli giây epoch.
  ///
  /// Cổng trả `startDate`/`endDate` dạng số - `fromWeekStr`/`toWeekStr` tồn tại
  /// nhưng thực tế luôn null, nên không dựa vào chúng được.
  final int startDate;
  final int endDate;

  /// API trả 2 = Thứ 2 ... 8 = Chủ nhật.
  final int dayOfWeek;
  final String startHourName; // "Tiết 1"
  final String endHourName; // "Tiết 3"
  final String roomName;
  final String teacherName;

  const ClassTimetable({
    required this.fromWeek,
    required this.toWeek,
    required this.startDate,
    required this.endDate,
    required this.dayOfWeek,
    required this.startHourName,
    required this.endHourName,
    required this.roomName,
    required this.teacherName,
  });

  factory ClassTimetable.fromJson(Map<String, dynamic> json) {
    // Tên phòng và giảng viên nằm ở nhiều nhánh khác nhau tùy loại lớp, nên
    // thử lần lượt thay vì tin vào một đường dẫn duy nhất.
    String pickRoom() {
      final direct = json['roomName'] ?? json['room'];
      if (direct is String && direct.isNotEmpty) return direct;
      final room = json['roomDto'] ?? json['classRoom'];
      if (room is Map) return (room['name'] ?? room['code'] ?? '').toString();
      return '';
    }

    String pickTeacher() {
      final direct = json['teacherName'];
      if (direct is String && direct.isNotEmpty) return direct;
      final t = json['teacher'];
      if (t is Map) {
        return (t['displayName'] ?? t['name'] ?? t['fullName'] ?? '').toString();
      }
      return '';
    }

    String hourName(Object? value) {
      if (value is Map) return (value['name'] ?? '').toString();
      return value?.toString() ?? '';
    }

    return ClassTimetable(
      fromWeek: _asInt(json['fromWeek']) ?? 0,
      toWeek: _asInt(json['toWeek']) ?? 0,
      startDate: _asInt(json['startDate']) ?? 0,
      endDate: _asInt(json['endDate']) ?? 0,
      dayOfWeek: _asInt(json['weekIndex'] ?? json['dayOfWeek']) ?? 0,
      startHourName: hourName(json['startHour'] ?? json['startCourseHour']),
      endHourName: hourName(json['endHour'] ?? json['endCourseHour']),
      roomName: pickRoom(),
      teacherName: pickTeacher(),
    );
  }

  /// "Thứ 2" ... "Chủ nhật" theo quy ước 2..8 của cổng.
  String get dayLabel {
    if (dayOfWeek >= 2 && dayOfWeek <= 7) return 'Thứ $dayOfWeek';
    if (dayOfWeek == 8) return 'Chủ nhật';
    return '';
  }

  /// "Tiết 1 → Tiết 3", rút gọn khi chỉ có một tiết.
  String get hourLabel {
    if (startHourName.isEmpty && endHourName.isEmpty) return '';
    if (startHourName == endHourName) return startHourName;
    return '$startHourName → $endHourName';
  }

  /// "Tuần 11 → 18 (09/11/2026 → 03/01/2027)".
  String get weekLabel {
    final weeks = fromWeek == 0 && toWeek == 0
        ? ''
        : 'Tuần $fromWeek → $toWeek';
    final from = _formatDate(startDate);
    final to = _formatDate(endDate);
    if (from.isEmpty) return weeks;
    final dates = '$from → $to';
    return weeks.isEmpty ? dates : '$weeks ($dates)';
  }

  /// Epoch milli giây -> "09/11/2026". Trả chuỗi rỗng khi không có mốc.
  static String _formatDate(int millis) {
    if (millis <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }
}

/// Một lớp học phần - đơn vị mà sinh viên thực sự đăng ký.
///
/// Tương ứng `courseSubjectDto` trong response.
class CourseClass {
  /// Map JSON gốc. **Bắt buộc** giữ lại: đây chính là body của request
  /// đăng ký / hủy đăng ký.
  final Map<String, dynamic> raw;

  final int id;
  final String code;
  final String subjectName;
  final int subjectId;
  final bool isFullClass;
  final int maxStudent;
  final int numberStudent;

  /// Sinh viên đã đăng ký lớp này chưa.
  final bool isSelected;

  final bool isOverlapTime;
  final double numberOfCredit;
  final double totalFee;
  final String teacherName;
  final List<ClassTimetable> timetables;

  const CourseClass({
    required this.raw,
    required this.id,
    required this.code,
    required this.subjectName,
    required this.subjectId,
    required this.isFullClass,
    required this.maxStudent,
    required this.numberStudent,
    required this.isSelected,
    required this.isOverlapTime,
    required this.numberOfCredit,
    required this.totalFee,
    required this.teacherName,
    required this.timetables,
  });

  factory CourseClass.fromJson(Map<String, dynamic> json) {
    final tts = json['timetables'];
    return CourseClass(
      raw: json,
      id: _asInt(json['id']) ?? 0,
      code: (json['code'] ?? json['shortCode'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? json['displayName'] ?? '').toString(),
      subjectId: _asInt(json['subjectId']) ?? 0,
      isFullClass: json['isFullClass'] == true,
      maxStudent: _asInt(json['maxStudent']) ?? 0,
      numberStudent: _asInt(json['numberStudent']) ?? 0,
      isSelected: json['isSelected'] == true,
      isOverlapTime: json['isOvelapTime'] == true || json['isOverlapTime'] == true,
      numberOfCredit: _asDouble(json['numberOfCredit']) ?? 0,
      totalFee: _asDouble(json['totalFee']) ?? 0,
      teacherName: (json['teacherName'] ?? '').toString(),
      timetables: tts is List
          ? tts
                .whereType<Map>()
                .map((e) => ClassTimetable.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  /// Lớp đã hết chỗ. Kiểm tra cả sĩ số vì `isFullClass` có thể chưa kịp cập nhật.
  bool get isFull =>
      isFullClass || (maxStudent > 0 && numberStudent >= maxStudent);

  /// "11/30"
  String get capacityLabel => '$numberStudent/$maxStudent';

  /// Giảng viên lấy từ lớp, nếu trống thì lấy từ buổi học đầu tiên.
  String get displayTeacher {
    if (teacherName.isNotEmpty) return teacherName;
    for (final t in timetables) {
      if (t.teacherName.isNotEmpty) return t.teacherName;
    }
    return '';
  }
}

/// Một môn học có thể đăng ký, chứa nhiều lớp học phần.
///
/// Tương ứng `SubjectRegistrationDto`.
class EnrollmentSubject {
  final String subjectName;
  final int registerPeriodId;
  final bool isAllowSubjectUnRegister;
  final bool hasSubjectReg;

  /// Tên các môn tiên quyết chưa đạt (nếu có).
  final List<String> dependSubjectNames;

  final List<CourseClass> classes;

  const EnrollmentSubject({
    required this.subjectName,
    required this.registerPeriodId,
    required this.isAllowSubjectUnRegister,
    required this.hasSubjectReg,
    required this.dependSubjectNames,
    required this.classes,
  });

  factory EnrollmentSubject.fromJson(Map<String, dynamic> json) {
    final cs = json['courseSubjectDtos'];
    final deps = json['dependSubjectNames'];
    return EnrollmentSubject(
      subjectName: (json['subjectName'] ?? '').toString(),
      registerPeriodId: _asInt(json['registerPeriodId']) ?? 0,
      isAllowSubjectUnRegister: json['isAllowSubjectUnRegister'] != false,
      hasSubjectReg: json['hasSubjectReg'] == true,
      dependSubjectNames: deps is List
          ? deps.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      classes: cs is List
          ? cs
                .whereType<Map>()
                .map((e) => CourseClass.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  /// Sinh viên đã đăng ký ít nhất một lớp của môn này.
  bool get isRegistered => classes.any((c) => c.isSelected);

  /// Lớp đang được đăng ký, nếu có.
  CourseClass? get registeredClass {
    for (final c in classes) {
      if (c.isSelected) return c;
    }
    return null;
  }
}

/// Toàn bộ dữ liệu màn hình đăng ký của một đợt.
///
/// Tương ứng response của `findByPeriod`, phần `courseRegisterViewObject`.
class EnrollmentView {
  final int studentId;
  final int periodId;

  /// Đợt có đang cho phép đăng ký không.
  final bool allowRegister;

  /// Đợt có cho phép hủy không.
  final bool isAllowUnRegister;

  final String startDateString;
  final String endDateString;
  final String startUnDateString;
  final String endUnDateString;

  final List<EnrollmentSubject> subjects;

  const EnrollmentView({
    required this.studentId,
    required this.periodId,
    required this.allowRegister,
    required this.isAllowUnRegister,
    required this.startDateString,
    required this.endDateString,
    required this.startUnDateString,
    required this.endUnDateString,
    required this.subjects,
  });

  static const EnrollmentView empty = EnrollmentView(
    studentId: 0,
    periodId: 0,
    allowRegister: false,
    isAllowUnRegister: false,
    startDateString: '',
    endDateString: '',
    startUnDateString: '',
    endUnDateString: '',
    subjects: [],
  );

  factory EnrollmentView.fromJson(Map<String, dynamic> json) {
    final view = json['courseRegisterViewObject'];
    final v = view is Map ? view.cast<String, dynamic>() : <String, dynamic>{};
    final list = v['listSubjectRegistrationDtos'];

    return EnrollmentView(
      studentId: _asInt(json['studentId']) ?? 0,
      periodId: _asInt(json['periodId']) ?? 0,
      allowRegister: v['allowRegister'] == true,
      isAllowUnRegister: v['isAllowUnRegister'] == true,
      startDateString: (v['startDateString'] ?? '').toString(),
      endDateString: (v['endDateString'] ?? '').toString(),
      startUnDateString: (v['startUnDateString'] ?? '').toString(),
      endUnDateString: (v['endUnDateString'] ?? '').toString(),
      subjects: list is List
          ? list
                .whereType<Map>()
                .map(
                  (e) => EnrollmentSubject.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : const [],
    );
  }

  bool get isEmpty => subjects.isEmpty;

  /// Tổng số tín chỉ sinh viên đã đăng ký trong đợt này.
  double get registeredCredits {
    double total = 0;
    for (final s in subjects) {
      for (final c in s.classes) {
        if (c.isSelected) total += c.numberOfCredit;
      }
    }
    return total;
  }

  /// Số môn đã đăng ký.
  int get registeredCount => subjects.where((s) => s.isRegistered).length;

  /// "24-08-2026 10:00:00 → 27-08-2026 23:00:00"
  String get windowLabel {
    if (startDateString.isEmpty && endDateString.isEmpty) return '';
    return '$startDateString → $endDateString';
  }
}

// --- Tiện ích parse phòng thủ -------------------------------------------
// Backend trả số khi thì int, khi thì double, đôi khi là chuỗi. Ép kiểu thẳng
// sẽ ném lỗi và làm trắng màn hình, nên luôn đi qua hai hàm này.

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

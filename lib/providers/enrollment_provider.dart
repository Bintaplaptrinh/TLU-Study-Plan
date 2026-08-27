import 'package:flutter/foundation.dart';

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/models/enrollment.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/services/enrollment_service.dart';
import 'package:tlustudy_planner/services/log_service.dart';

/// State của màn hình "Đăng ký môn học".
///
/// Ba lựa chọn lồng nhau dẫn tới dữ liệu: **năm học** → **học kỳ** (giai đoạn
/// trong năm) → **đợt đăng ký** ("Học kỳ chính", "Học kỳ phụ", "Tiếng Anh tăng
/// cường"...). Chỉ đợt cuối cùng mới sinh ra lời gọi mạng; đổi năm hay kỳ chỉ
/// lọc lại danh sách bên dưới rồi tự chọn mục đầu tiên.
class EnrollmentProvider extends ChangeNotifier {
  EnrollmentProvider(this._userProvider);

  final UserProvider _userProvider;
  final EnrollmentService _service = EnrollmentService();
  final LogService _log = LogService();

  // --- Lựa chọn -----------------------------------------------------------
  int? _selectedYearId;
  int? _selectedSemesterId;
  int? _selectedPeriodId;

  // --- Dữ liệu ------------------------------------------------------------
  int? _studentId;
  EnrollmentView _view = EnrollmentView.empty;

  /// Môn đang mở ở cột/danh sách bên phải. `null` = chưa chọn môn nào.
  String? _selectedSubjectName;

  // --- Trạng thái ---------------------------------------------------------
  bool _isLoading = false;
  String? _error;

  /// Id của lớp đang có thao tác đăng ký/hủy chạy dở, để chỉ ô đó hiện spinner
  /// thay vì khóa cả màn hình.
  int? _busyClassId;

  // --- Getters ------------------------------------------------------------
  int? get selectedYearId => _selectedYearId;
  int? get selectedSemesterId => _selectedSemesterId;
  int? get selectedPeriodId => _selectedPeriodId;
  EnrollmentView get view => _view;
  String? get selectedSubjectName => _selectedSubjectName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get busyClassId => _busyClassId;

  /// Danh sách năm học, mới nhất lên đầu.
  List<SchoolYear> get schoolYears {
    final years = _userProvider.schoolYears?.content;
    if (years == null || years.isEmpty) return const [];
    final sorted = [...years]..sort((a, b) => b.year.compareTo(a.year));
    return sorted;
  }

  /// Các học kỳ của năm đang chọn, sắp theo thứ tự trong năm.
  List<Semester> get semesters {
    final year = _currentYear;
    if (year == null) return const [];
    final list = [...year.semesters]
      ..sort(
        (a, b) => (a.ordinalNumbers ?? a.id).compareTo(b.ordinalNumbers ?? b.id),
      );
    return list;
  }

  /// Các đợt đăng ký của kỳ đang chọn: Học kỳ chính, Học kỳ phụ, Tiếng Anh
  /// tăng cường, Học phần tốt nghiệp, Chuẩn đầu ra ngoại ngữ, Ôn thi...
  List<SemesterRegisterPeriod> get periods {
    final semester = _currentSemester;
    if (semester == null) return const [];
    final list = [...semester.semesterRegisterPeriods]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  SchoolYear? get _currentYear {
    final years = schoolYears;
    if (years.isEmpty) return null;
    for (final y in years) {
      if (y.id == _selectedYearId) return y;
    }
    return years.first;
  }

  Semester? get _currentSemester {
    final list = semesters;
    if (list.isEmpty) return null;
    for (final s in list) {
      if (s.id == _selectedSemesterId) return s;
    }
    return list.first;
  }

  /// Môn đang mở, hoặc `null` nếu chưa chọn / môn đã biến mất sau khi tải lại.
  EnrollmentSubject? get selectedSubject {
    final name = _selectedSubjectName;
    if (name == null) return null;
    for (final s in _view.subjects) {
      if (s.subjectName == name) return s;
    }
    return null;
  }

  /// Đợt có đang mở để thao tác không. Ngoài đợt thì mọi ô chọn đều bị khóa.
  bool get canRegister => _view.allowRegister;

  // --- Khởi tạo -----------------------------------------------------------

  /// Chọn sẵn năm/kỳ/đợt hợp lý rồi nạp dữ liệu.
  ///
  /// Ưu tiên kỳ mà [UserProvider] đang chọn (kỳ hiện hành), vì gần như luôn là
  /// kỳ sinh viên muốn đăng ký.
  Future<void> initialize() async {
    if (_isLoading) return;

    // Cây năm học có thể đến từ cache, mà cache của bản cũ không giữ đợt đăng
    // ký - xin cổng một bản mới trước khi kết luận là "không có đợt nào".
    var toppedUp = false;
    if (schoolYears.isEmpty || !_userProvider.hasRegisterPeriods) {
      // Bật cờ chờ quanh đúng lời gọi mạng này thôi: các nhánh phía dưới vẫn
      // giả định `_isLoading == false` như trước.
      _isLoading = true;
      notifyListeners();
      toppedUp = await _userProvider.refreshSchoolYears();
      _isLoading = false;
    }

    final years = schoolYears;
    if (years.isEmpty) {
      _error = 'Chưa có dữ liệu năm học. Hãy tải lại dữ liệu ở màn hình chính.';
      notifyListeners();
      return;
    }

    // Bám theo kỳ đang chọn của app nếu tìm được nó trong cây năm học.
    final preferred = _userProvider.selectedSemester;
    SchoolYear? year;
    Semester? semester;

    if (preferred != null) {
      for (final y in years) {
        for (final s in y.semesters) {
          if (s.id == preferred.id) {
            year = y;
            semester = s;
            break;
          }
        }
        if (year != null) break;
      }
    }

    year ??= years.first;
    semester ??= _pickDefaultSemester(year);

    _selectedYearId = year.id;
    _selectedSemesterId = semester?.id;
    _selectedPeriodId = _pickDefaultPeriod(semester);

    // Không có đợt nào mà cũng chưa hỏi lại cổng lần nào: hỏi một lần rồi chọn
    // lại, thay vì để màn hình đứng ở "Học kỳ này chưa có đợt đăng ký nào" cho
    // tới lần đồng bộ đầy đủ tiếp theo.
    if (_selectedPeriodId == null && !toppedUp) {
      _isLoading = true;
      notifyListeners();
      final ok = await _userProvider.refreshSchoolYears();
      _isLoading = false;

      if (ok) {
        final refreshedYear = _currentYear;
        if (refreshedYear != null) {
          _selectedYearId = refreshedYear.id;
          final refreshedSemester = _currentSemester;
          _selectedSemesterId = refreshedSemester?.id;
          _selectedPeriodId = _pickDefaultPeriod(refreshedSemester);
        }
      }
    }

    await refresh();
  }

  /// Kỳ đang diễn ra, nếu không có thì kỳ đầu tiên.
  Semester? _pickDefaultSemester(SchoolYear year) {
    if (year.semesters.isEmpty) return null;
    for (final s in year.semesters) {
      if (s.isCurrent || s.isActive()) return s;
    }
    final sorted = [...year.semesters]
      ..sort(
        (a, b) => (a.ordinalNumbers ?? a.id).compareTo(b.ordinalNumbers ?? b.id),
      );
    return sorted.first;
  }

  /// "Học kỳ chính" là đợt sinh viên cần đến trong hầu hết trường hợp.
  int? _pickDefaultPeriod(Semester? semester) {
    if (semester == null || semester.semesterRegisterPeriods.isEmpty) {
      return null;
    }
    final list = [...semester.semesterRegisterPeriods]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    for (final p in list) {
      if (p.name.toLowerCase().contains('chính')) return p.id;
    }
    return list.first.id;
  }

  // --- Thay đổi lựa chọn --------------------------------------------------

  Future<void> selectYear(int yearId) async {
    if (_selectedYearId == yearId) return;
    _selectedYearId = yearId;

    // Kỳ và đợt cũ thuộc năm khác nên không còn nghĩa - chọn lại từ đầu.
    final semester = _pickDefaultSemester(_currentYear!);
    _selectedSemesterId = semester?.id;
    _selectedPeriodId = _pickDefaultPeriod(semester);
    _selectedSubjectName = null;
    notifyListeners();

    await refresh();
  }

  Future<void> selectSemester(int semesterId) async {
    if (_selectedSemesterId == semesterId) return;
    _selectedSemesterId = semesterId;
    _selectedPeriodId = _pickDefaultPeriod(_currentSemester);
    _selectedSubjectName = null;
    notifyListeners();

    await refresh();
  }

  Future<void> selectPeriod(int periodId) async {
    if (_selectedPeriodId == periodId) return;
    _selectedPeriodId = periodId;
    _selectedSubjectName = null;
    notifyListeners();

    await refresh();
  }

  /// Mở / đóng danh sách lớp của một môn.
  void selectSubject(String? subjectName) {
    _selectedSubjectName = _selectedSubjectName == subjectName
        ? null
        : subjectName;
    notifyListeners();
  }

  // --- Nạp dữ liệu --------------------------------------------------------

  /// Tải lại dữ liệu của đợt đang chọn.
  Future<void> refresh() async {
    final periodId = _selectedPeriodId;
    if (periodId == null) {
      _view = EnrollmentView.empty;
      _error = 'Học kỳ này chưa có đợt đăng ký nào.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _userProvider.ensureValidToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }

      // studentId không đổi trong một phiên nên chỉ hỏi cổng một lần.
      _studentId ??= await _service.getStudentId(token);
      final studentId = _studentId;
      if (studentId == null) {
        throw Exception('Không lấy được mã sinh viên từ cổng đào tạo.');
      }

      _view = await _service.findByPeriod(token, studentId, periodId);

      // Môn đang mở có thể không còn trong đợt mới - bỏ chọn để tránh trỏ vào
      // dữ liệu cũ.
      if (selectedSubject == null) _selectedSubjectName = null;

      _error = _view.isEmpty ? 'Đợt này chưa có môn nào để đăng ký.' : null;
    } catch (e) {
      _view = EnrollmentView.empty;
      _error = _readable(e);
      _log.log('Đăng ký học: $e', level: LogLevel.error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Đăng ký / hủy ------------------------------------------------------

  /// Đăng ký [courseClass]. Trả về `null` khi thành công, ngược lại là lý do
  /// thất bại để màn hình hiển thị.
  Future<String?> register(CourseClass courseClass) {
    return _mutate(
      courseClass,
      (token, studentId, periodId) =>
          _service.register(token, studentId, periodId, courseClass.raw),
    );
  }

  /// Hủy đăng ký [courseClass]. Màn hình phải hỏi xác nhận trước khi gọi.
  Future<String?> unregister(CourseClass courseClass) {
    return _mutate(
      courseClass,
      (token, studentId, periodId) =>
          _service.unregister(token, studentId, periodId, courseClass.raw),
    );
  }

  /// Thân chung của đăng ký và hủy.
  ///
  /// Luôn nạp lại dữ liệu sau khi ghi thành công: sĩ số và cờ `isSelected` do
  /// server quyết định, đoán ở phía app sẽ sai ngay khi có người khác vừa
  /// đăng ký cùng lớp.
  Future<String?> _mutate(
    CourseClass courseClass,
    Future<void> Function(String token, int studentId, int periodId) action,
  ) async {
    final periodId = _selectedPeriodId;
    if (periodId == null) return 'Chưa chọn đợt đăng ký.';
    if (_busyClassId != null) return null; // Đang có thao tác khác chạy dở.

    _busyClassId = courseClass.id;
    notifyListeners();

    try {
      final token = await _userProvider.ensureValidToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      final studentId = _studentId ??= await _service.getStudentId(token);
      if (studentId == null) {
        throw Exception('Không lấy được mã sinh viên từ cổng đào tạo.');
      }

      await action(token, studentId, periodId);

      _busyClassId = null;
      await refresh();
      return null;
    } catch (e) {
      _busyClassId = null;
      notifyListeners();
      return _readable(e);
    }
  }

  /// Bỏ tiền tố "Exception: " để thông điệp đọc được như một câu tiếng Việt.
  String _readable(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

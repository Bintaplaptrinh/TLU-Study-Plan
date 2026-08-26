import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/models/user.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/services/auth_service.dart';
import 'package:tlustudy_planner/services/credential_store.dart';
import 'package:tlustudy_planner/services/daily_notification_service.dart';
import 'package:tlustudy_planner/services/database_helper.dart';
import 'package:tlustudy_planner/services/log_service.dart';
import 'package:tlustudy_planner/services/notification_service.dart';
import 'package:tlustudy_planner/services/widget_service.dart';
import 'package:tlustudy_planner/utils/notification_helper.dart';

/// Central provider for authentication, the logged-in student's academic data
/// (school years, semesters, course hours, timetable) and notification
/// preferences.
///
/// Everything it fetches from the TLU API is mirrored into the local SQLite
/// database via [DatabaseHelper], so the app stays usable offline. On start-up
/// [init] restores from that cache first and only then tries the network.
class UserProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------
  final AuthService _authService = AuthService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  final WidgetService _widgetService = WidgetService();
  final LogService _log = LogService();

  SharedPreferences? _prefs;
  ExamProvider? _examProvider;

  // ---------------------------------------------------------------------------
  // SharedPreferences keys
  // ---------------------------------------------------------------------------
  static const String _kAccessToken = 'accessToken';
  static const String _kRefreshToken = 'refreshToken';
  static const String _kTokenExpiry = 'tokenExpiry';
  static const String _kStudentCode = 'studentCode';
  static const String _kSelectedSemesterId = 'selectedSemesterId';
  static const String _kLastDataReload = 'lastDataReload';
  static const String _kNotificationsEnabled = 'notificationsEnabled';
  static const String _kDailyNotificationsEnabled = 'dailyNotificationsEnabled';

  /// Data older than this triggers the "should refresh" hint in Settings.
  static const Duration _autoReloadAfter = Duration(days: 7);

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------
  String? _accessToken;
  String? _refreshToken;
  int? _tokenExpiryMs;
  String? _studentCode;
  TluUser? _tluUser;

  // ---------------------------------------------------------------------------
  // Academic data
  // ---------------------------------------------------------------------------
  SchoolYearResponse? _schoolYears;
  Semester? _selectedSemester;
  Map<int, CourseHour> _courseHours = <int, CourseHour>{};
  List<StudentCourseSubject> _courses = <StudentCourseSubject>[];
  bool _isLoadingCourses = false;

  /// The student's education program (chương trình đào tạo), flattened from
  /// the portal's knowledge-block tree.
  List<ProgramSubject> _educationProgram = <ProgramSubject>[];

  /// Tiện ích data, hydrated from SQLite at start-up and refreshed on sync.
  Map<int, List<StudentSubjectMark>> _marksBySemester =
      <int, List<StudentSubjectMark>>{};
  List<StudentBehaviorMark> _behaviorMarks = <StudentBehaviorMark>[];
  StudentTuition _tuition = StudentTuition.empty;
  bool _isSyncingUtilities = false;
  bool _isLoadingEducationProgram = false;

  // ---------------------------------------------------------------------------
  // Login / reload progress
  // ---------------------------------------------------------------------------
  String _loginProgress = '';
  double _loginProgressPercent = 0.0;
  DateTime? _lastDataReload;

  // ---------------------------------------------------------------------------
  // Notification preferences
  // ---------------------------------------------------------------------------
  bool _notificationsEnabled = false;
  bool _hasNotificationPermission = false;
  bool _dailyNotificationsEnabled = false;

  // ===========================================================================
  // Getters
  // ===========================================================================
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  TluUser? get tluUser => _tluUser;

  /// A lightweight, never-null view of the signed-in student, used by screens
  /// that only need a name / id / email.
  User get currentUser => User(
    studentId: _tluUser?.username ?? _studentCode ?? '',
    fullName: _tluUser?.displayName ?? _studentCode ?? '',
    email: _tluUser?.email ?? '',
  );

  SchoolYearResponse? get schoolYears => _schoolYears;

  Semester? get selectedSemester => _selectedSemester;

  Map<int, CourseHour> get courseHours => _courseHours;

  List<StudentCourseSubject> get courses => List.unmodifiable(_courses);

  bool get isLoadingCourses => _isLoadingCourses;

  List<ProgramSubject> get educationProgram =>
      List.unmodifiable(_educationProgram);

  bool get isLoadingEducationProgram => _isLoadingEducationProgram;

  /// Total credits the program requires, across every knowledge block.
  int get educationProgramCredits => totalProgramCredits(_educationProgram);

  /// Cached marks, keyed by semester id.
  Map<int, List<StudentSubjectMark>> get marksBySemester =>
      Map.unmodifiable(_marksBySemester);

  List<StudentSubjectMark> get allMarks =>
      _marksBySemester.values.expand((m) => m).toList();

  List<StudentBehaviorMark> get behaviorMarks =>
      List.unmodifiable(_behaviorMarks);

  StudentTuition get tuition => _tuition;

  bool get isSyncingUtilities => _isSyncingUtilities;

  /// Cumulative GPA on the 4-point scale, over courses the portal counts.
  double? get gpa4 {
    final counted = allMarks.where(
      (m) => m.isCounted && m.mark4 != null && m.credits > 0,
    );
    if (counted.isEmpty) return null;
    final credits = counted.fold<int>(0, (sum, m) => sum + m.credits);
    if (credits == 0) return null;
    final points = counted.fold<double>(
      0,
      (sum, m) => sum + (m.mark4! * m.credits),
    );
    return points / credits;
  }

  /// Credits actually earned.
  int get earnedCredits => allMarks
      .where((m) => m.isCounted && m.isPassed)
      .fold<int>(0, (sum, m) => sum + m.credits);

  /// Program courses grouped by knowledge block, preserving the portal's
  /// ordering of both blocks and courses within them.
  Map<String, List<ProgramSubject>> get educationProgramByBlock {
    final grouped = <String, List<ProgramSubject>>{};
    for (final subject in _educationProgram) {
      final block = subject.knowledgeBlock.isEmpty
          ? 'Khác'
          : subject.knowledgeBlock;
      grouped.putIfAbsent(block, () => <ProgramSubject>[]).add(subject);
    }
    return grouped;
  }

  String get loginProgress => _loginProgress;

  double get loginProgressPercent => _loginProgressPercent;

  DateTime? get lastDataReload => _lastDataReload;

  /// True when the cached data is stale enough that Settings should nudge the
  /// user to refresh.
  bool get shouldAutoReload {
    if (!isLoggedIn) return false;
    final last = _lastDataReload;
    if (last == null) return true;
    return DateTime.now().difference(last) > _autoReloadAfter;
  }

  bool get notificationsEnabled => _notificationsEnabled;

  bool get hasNotificationPermission => _hasNotificationPermission;

  bool get dailyNotificationsEnabled => _dailyNotificationsEnabled;

  /// All semesters known from the cached / fetched school years, newest first.
  List<Semester> get allSemesters {
    final years = _schoolYears;
    if (years == null) return const <Semester>[];
    final semesters = years.content.expand((y) => y.semesters).toList();
    semesters.sort((a, b) => b.startDate.compareTo(a.startDate));
    return semesters;
  }

  // ===========================================================================
  // Wiring
  // ===========================================================================

  /// Lets [ExamProvider] be driven from here (pre-caching after login, clearing
  /// on logout) without creating a circular dependency in `main.dart`.
  void setExamProvider(ExamProvider examProvider) {
    _examProvider = examProvider;
  }

  // ===========================================================================
  // Start-up
  // ===========================================================================

  /// Restores the session and every cached bit of academic data. Safe to call
  /// before `runApp` — it never throws.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      _accessToken = _prefs?.getString(_kAccessToken);
      _refreshToken = _prefs?.getString(_kRefreshToken);
      _tokenExpiryMs = _prefs?.getInt(_kTokenExpiry);
      _studentCode = _prefs?.getString(_kStudentCode);

      _notificationsEnabled = _prefs?.getBool(_kNotificationsEnabled) ?? false;
      _dailyNotificationsEnabled =
          _prefs?.getBool(_kDailyNotificationsEnabled) ?? false;

      final lastReloadMs = _prefs?.getInt(_kLastDataReload);
      if (lastReloadMs != null) {
        _lastDataReload = DateTime.fromMillisecondsSinceEpoch(lastReloadMs);
      }

      // An expired token is recoverable: spend the refresh token (or the
      // stored credentials) before falling back to the login screen.
      if (_accessToken != null && _isTokenExpired()) {
        _log.log(
          'Access token đã hết hạn, đang thử làm mới',
          level: LogLevel.warning,
        );
        if (!await _renewSession()) {
          _log.log(
            'Không làm mới được phiên, cần đăng nhập lại',
            level: LogLevel.warning,
          );
          await _clearSession();
        }
      }

      await _loadFromCache();

      // Best effort — never blocks start-up.
      await checkNotificationPermission();

      notifyListeners();

      // Refresh in the background once the app is running.
      if (isLoggedIn) {
        unawaited(_refreshInBackground());
      }
    } catch (e, stack) {
      _log.log('UserProvider.init failed: $e', level: LogLevel.error);
      debugPrint('UserProvider.init failed: $e\n$stack');
    }
  }

  /// True when the token is gone, expired, or about to expire.
  ///
  /// The 60s skew stops a request being sent with a token that dies
  /// mid-flight, which used to surface as a bare 401 on the live screens.
  bool _needsRenewal() {
    if (_accessToken == null || _accessToken!.isEmpty) return true;
    final expiry = _tokenExpiryMs;
    if (expiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch >=
        expiry - const Duration(seconds: 60).inMilliseconds;
  }

  /// Only one renewal runs at a time; the marks screen fires nine semester
  /// requests at once and they must not each start their own login.
  Future<bool>? _renewal;

  Future<bool> _renewSession() {
    return _renewal ??= _doRenewSession().whenComplete(() => _renewal = null);
  }

  Future<bool> _doRenewSession() async {
    // Preferred: spend the refresh token the portal already gave us.
    final refresh = _refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        final response = await _authService.refreshAccessToken(refresh);
        await _storeSession(response);
        return true;
      } catch (e) {
        _log.log('Refresh token không dùng được: $e', level: LogLevel.warning);
      }
    }

    // Fallback: replay the stored credentials.
    final saved = await CredentialStore.instance.read();
    if (saved == null) return false;

    try {
      final response = await _authService.login(
        saved.studentCode,
        saved.password,
      );
      await _storeSession(response);
      _log.log(
        'Đã đăng nhập lại bằng thông tin đã lưu',
        level: LogLevel.success,
      );
      return true;
    } catch (e) {
      _log.log('Đăng nhập lại thất bại: $e', level: LogLevel.error);
      return false;
    }
  }

  Future<void> _storeSession(LoginResponse response) async {
    _accessToken = response.accessToken;
    if (response.refreshToken.isNotEmpty) {
      _refreshToken = response.refreshToken;
    }
    _tokenExpiryMs = DateTime.now()
        .add(Duration(seconds: response.expiresIn))
        .millisecondsSinceEpoch;

    await _prefs?.setString(_kAccessToken, _accessToken!);
    if (_refreshToken != null) {
      await _prefs?.setString(_kRefreshToken, _refreshToken!);
    }
    await _prefs?.setInt(_kTokenExpiry, _tokenExpiryMs!);
    notifyListeners();
  }

  /// Returns a usable access token, renewing first when necessary.
  ///
  /// Every live fetch goes through this. Without it the app happily sent a
  /// dead token and reported an empty screen.
  Future<String?> ensureValidToken() async {
    if (!_needsRenewal()) return _accessToken;
    if (await _renewSession()) return _accessToken;
    return null;
  }

  /// Runs [action] with a valid token, retrying once if the portal still
  /// answers "session expired" - which happens when the server invalidated the
  /// token earlier than its stated lifetime.
  Future<T> _withValidToken<T>(
    String label,
    Future<T> Function(String token) action,
    T fallback,
  ) async {
    final token = await ensureValidToken();
    if (token == null) {
      _log.log(
        '$label: không có phiên đăng nhập hợp lệ',
        level: LogLevel.warning,
      );
      return fallback;
    }

    try {
      return await action(token);
    } catch (e) {
      if (!e.toString().contains('hết hạn')) {
        _log.log('$label: $e', level: LogLevel.warning);
        return fallback;
      }

      _log.log(
        '$label: token bị từ chối, thử làm mới rồi gọi lại',
        level: LogLevel.warning,
      );
      if (!await _renewSession()) return fallback;
      final retryToken = _accessToken;
      if (retryToken == null) return fallback;
      try {
        return await action(retryToken);
      } catch (e2) {
        _log.log('$label: vẫn lỗi sau khi làm mới: $e2', level: LogLevel.error);
        return fallback;
      }
    }
  }

  bool _isTokenExpired() {
    final expiry = _tokenExpiryMs;
    if (expiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiry;
  }

  /// Rehydrates user, course hours, school years, semesters and the timetable
  /// of the last selected semester from SQLite.
  Future<void> _loadFromCache() async {
    try {
      _tluUser = await _db.getTluUser();
      _courseHours = await _db.getCourseHours();

      final cachedYears = await _db.getSchoolYears();
      final cachedSemesters = await _db.getSemesters();
      _schoolYears = _composeSchoolYears(cachedYears, cachedSemesters);

      final savedSemesterId = _prefs?.getInt(_kSelectedSemesterId);
      _selectedSemester = _pickSemester(preferredId: savedSemesterId);

      final semester = _selectedSemester;
      if (semester != null) {
        _courses = await _db.getStudentCourses(semester.id);
      }

      _educationProgram = await _db.getEducationProgram();

      final cachedMarks = await _db.getAllMarks();
      _marksBySemester = <int, List<StudentSubjectMark>>{};
      for (final mark in cachedMarks) {
        _marksBySemester.putIfAbsent(mark.semesterId, () => []).add(mark);
      }
      _behaviorMarks = await _db.getBehaviorMarks();
      _tuition = await _db.getTuition() ?? StudentTuition.empty;

      _log.log(
        'Loaded from cache: ${_courseHours.length} course hours, '
        '${allSemesters.length} semesters, ${_courses.length} courses, '
        '${_educationProgram.length} program subjects',
        level: LogLevel.info,
      );
    } catch (e) {
      _log.log('Failed to load cached data: $e', level: LogLevel.error);
    }
  }

  /// The cache stores school years and semesters in separate tables, so the
  /// semesters have to be re-attached to the year whose date range covers them.
  SchoolYearResponse? _composeSchoolYears(
    List<SchoolYear> years,
    List<Semester> semesters,
  ) {
    if (years.isEmpty && semesters.isEmpty) return null;

    if (years.isEmpty) {
      // No years cached but we do have semesters — wrap them in a synthetic year
      // so the semester pickers still work.
      final sorted = [...semesters]
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      return SchoolYearResponse(
        content: [
          SchoolYear(
            id: 0,
            name: 'Đã lưu',
            code: 'CACHED',
            year: DateTime.now().year,
            current: true,
            startDate: sorted.last.startDate,
            endDate: sorted.first.endDate,
            displayName: 'Đã lưu',
            semesters: sorted,
          ),
        ],
        last: true,
        totalElements: 1,
        totalPages: 1,
      );
    }

    final unassigned = <Semester>[...semesters];
    final composed = <SchoolYear>[];

    for (final year in years) {
      final owned =
          unassigned
              .where(
                (s) =>
                    s.startDate >= year.startDate &&
                    s.startDate <= year.endDate,
              )
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
      unassigned.removeWhere(owned.contains);

      composed.add(
        SchoolYear(
          id: year.id,
          name: year.name,
          code: year.code,
          year: year.year,
          current: year.current,
          startDate: year.startDate,
          endDate: year.endDate,
          displayName: year.displayName,
          semesters: owned,
        ),
      );
    }

    // Anything that didn't fall inside a year range goes to the newest year so
    // it is still reachable from the dropdowns.
    if (unassigned.isNotEmpty && composed.isNotEmpty) {
      final newest = composed.first;
      final merged = [...newest.semesters, ...unassigned]
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      composed[0] = SchoolYear(
        id: newest.id,
        name: newest.name,
        code: newest.code,
        year: newest.year,
        current: newest.current,
        startDate: newest.startDate,
        endDate: newest.endDate,
        displayName: newest.displayName,
        semesters: merged,
      );
    }

    return SchoolYearResponse(
      content: composed,
      last: true,
      totalElements: composed.length,
      totalPages: 1,
    );
  }

  /// Chooses which semester to show: the previously selected one, else the one
  /// flagged current by the API, else the one covering today, else the newest.
  Semester? _pickSemester({int? preferredId}) {
    final semesters = allSemesters;
    if (semesters.isEmpty) return null;

    if (preferredId != null) {
      for (final s in semesters) {
        if (s.id == preferredId) return s;
      }
    }

    for (final s in semesters) {
      if (s.isCurrent) return s;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final s in semesters) {
      if (nowMs >= s.startDate && nowMs <= s.endDate) return s;
    }

    return semesters.first;
  }

  Future<void> _refreshInBackground() async {
    final token = _accessToken;
    if (token == null) return;

    try {
      final valid = await _authService.isTokenValid(token);
      if (!valid) {
        _log.log(
          'Token rejected by server — signing out',
          level: LogLevel.warning,
        );
        await logout();
        return;
      }

      // Silent top-up of the timetable so a returning user sees fresh data.
      final semester = _selectedSemester;
      if (semester != null) {
        await _fetchCoursesForSemester(semester, notify: true);
      }
    } catch (e) {
      // Offline is fine — the cached data is already on screen.
      _log.log('Background refresh skipped: $e', level: LogLevel.debug);
    }
  }

  // ===========================================================================
  // Login / logout
  // ===========================================================================

  void _setProgress(String message, double percent) {
    _loginProgress = message;
    _loginProgressPercent = percent.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Full login against the TLU API followed by a first sync of every piece of
  /// data the app needs. Throws with a user-facing Vietnamese message on
  /// failure.
  Future<void> loginWithApi(String studentCode, String password) async {
    _setProgress('Đang đăng nhập...', 0.05);

    try {
      final loginResponse = await _authService.login(studentCode, password);

      _accessToken = loginResponse.accessToken;
      _refreshToken = loginResponse.refreshToken;
      _tokenExpiryMs = DateTime.now()
          .add(Duration(seconds: loginResponse.expiresIn))
          .millisecondsSinceEpoch;
      _studentCode = studentCode;

      await _prefs?.setString(_kAccessToken, _accessToken!);
      await _prefs?.setString(_kRefreshToken, _refreshToken!);
      await _prefs?.setInt(_kTokenExpiry, _tokenExpiryMs!);
      await _prefs?.setString(_kStudentCode, studentCode);
      // Kept in the keystore so the live screens can re-authenticate silently
      // once the refresh token itself expires.
      await CredentialStore.instance.save(studentCode, password);

      _log.log('Login successful for $studentCode', level: LogLevel.info);

      await _syncAllData(isInitialLogin: true);
    } catch (e) {
      _setProgress('', 0.0);
      _log.log('Login failed: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Fetches user profile, course hours, school years, the current semester and
  /// its timetable, persisting each step to the local database as it goes.
  Future<void> _syncAllData({bool isInitialLogin = false}) async {
    final token = _accessToken;
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    // 1. Student profile
    _setProgress('Đang tải thông tin sinh viên...', 0.20);
    try {
      _tluUser = await _authService.getCurrentUser(token);
      await _db.saveTluUser(_tluUser!);
    } catch (e) {
      _log.log('Could not load user profile: $e', level: LogLevel.warning);
      if (isInitialLogin) rethrow;
    }

    // 2. Course hours (Tiết 1-15)
    _setProgress('Đang tải khung giờ học...', 0.35);
    try {
      final hours = await _authService.getCourseHours(token);
      if (hours.isNotEmpty) {
        _courseHours = hours;
        await _db.saveCourseHours(hours);
      }
    } catch (e) {
      _log.log('Could not load course hours: $e', level: LogLevel.warning);
    }

    // 3. School years + semesters
    _setProgress('Đang tải danh sách học kỳ...', 0.50);
    try {
      final years = await _authService.getSchoolYears(token);
      _schoolYears = years;
      await _db.saveSchoolYears(years.content);
    } catch (e) {
      _log.log('Could not load school years: $e', level: LogLevel.warning);
      if (_schoolYears == null && isInitialLogin) rethrow;
    }

    // 4. Which semester are we in?
    _setProgress('Đang xác định học kỳ hiện tại...', 0.65);
    int? currentSemesterId;
    try {
      final info = await _authService.getSemesterInfo(token);
      currentSemesterId = info.id;
    } catch (e) {
      _log.log(
        'Could not resolve current semester: $e',
        level: LogLevel.warning,
      );
    }

    final savedSemesterId = isInitialLogin
        ? null
        : _prefs?.getInt(_kSelectedSemesterId);
    _selectedSemester = _pickSemester(
      preferredId: currentSemesterId ?? savedSemesterId,
    );

    if (_selectedSemester != null) {
      await _persistSemesters();
      await _prefs?.setInt(_kSelectedSemesterId, _selectedSemester!.id);
    }

    // 5. Timetable for that semester
    _setProgress('Đang tải lịch học...', 0.80);
    final semester = _selectedSemester;
    if (semester != null) {
      await _fetchCoursesForSemester(semester, notify: false);
    }

    // 6. Education program - two extra round-trips, and the program rarely
    // changes, so a failure here must not fail the whole sync.
    _setProgress('Đang tải chương trình đào tạo...', 0.92);
    try {
      await fetchEducationProgram(forceRefresh: true);
    } catch (e) {
      _log.log('Could not load education program: $e', level: LogLevel.warning);
    }

    // 7. Tiện ích data (điểm, rèn luyện, học phí). Cached like the timetable
    // so the screens open instantly and still work offline.
    _setProgress('Đang tải điểm và học phí...', 0.96);
    await syncUtilitiesData();

    // 8. Wrap up
    _setProgress('Hoàn tất', 1.0);
    _lastDataReload = DateTime.now();
    await _prefs?.setInt(
      _kLastDataReload,
      _lastDataReload!.millisecondsSinceEpoch,
    );

    await _afterCoursesChanged();

    _setProgress('', 0.0);
  }

  /// Persists all known semesters, marking only the selected one as current so
  /// the background daily-notification worker (which reads `isCurrent` straight
  /// from SQLite) targets the right semester.
  Future<void> _persistSemesters() async {
    final semesters = allSemesters;
    if (semesters.isEmpty) return;

    final selectedId = _selectedSemester?.id;
    final toSave = semesters
        .map(
          (s) => Semester(
            id: s.id,
            semesterCode: s.semesterCode,
            semesterName: s.semesterName,
            startDate: s.startDate,
            endDate: s.endDate,
            isCurrent: s.id == selectedId,
            ordinalNumbers: s.ordinalNumbers,
            semesterRegisterPeriods: s.semesterRegisterPeriods,
          ),
        )
        .toList();

    await _db.saveSemesters(toSave);
  }

  /// Clears tokens and cached credentials but leaves the SQLite cache intact
  /// until [logout] wipes it.
  Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    // The keystore copy has to go with the session, or "sign out" would not
    // actually sign the student out.
    unawaited(CredentialStore.instance.clear());
    _tokenExpiryMs = null;

    await _prefs?.remove(_kAccessToken);
    await _prefs?.remove(_kRefreshToken);
    await _prefs?.remove(_kTokenExpiry);
  }

  /// Signs the student out and removes every locally cached record.
  Future<void> logout() async {
    _log.log('Logging out', level: LogLevel.info);

    await _clearSession();

    _studentCode = null;
    _tluUser = null;
    _schoolYears = null;
    _selectedSemester = null;
    _courseHours = <int, CourseHour>{};
    _courses = <StudentCourseSubject>[];
    _educationProgram = <ProgramSubject>[];
    _marksBySemester = <int, List<StudentSubjectMark>>{};
    _behaviorMarks = <StudentBehaviorMark>[];
    _tuition = StudentTuition.empty;
    _lastDataReload = null;
    _loginProgress = '';
    _loginProgressPercent = 0.0;

    await _prefs?.remove(_kStudentCode);
    await _prefs?.remove(_kSelectedSemesterId);
    await _prefs?.remove(_kLastDataReload);

    try {
      await _db.clearAllData();
      await _db.resetCacheProgress();
    } catch (e) {
      _log.log('Failed clearing local database: $e', level: LogLevel.error);
    }

    try {
      await NotificationHelper.cancelAllNotifications();
      await DailyNotificationService.cancelDailyCheck();
    } catch (e) {
      _log.log('Failed cancelling notifications: $e', level: LogLevel.warning);
    }

    try {
      _examProvider?.clear();
    } catch (e) {
      _log.log('Failed clearing exam provider: $e', level: LogLevel.warning);
    }

    try {
      await _widgetService.updateWidget(courses: const []);
    } catch (e) {
      _log.log('Failed clearing widget: $e', level: LogLevel.warning);
    }

    notifyListeners();
  }

  // ===========================================================================
  // Semesters & timetable
  // ===========================================================================

  /// Switches the active semester, loading its timetable from cache first and
  /// then refreshing from the API when a connection is available.
  Future<void> selectSemester(Semester semester) async {
    if (_selectedSemester?.id == semester.id && _courses.isNotEmpty) {
      return;
    }

    _selectedSemester = semester;
    await _prefs?.setInt(_kSelectedSemesterId, semester.id);
    await _persistSemesters();

    _isLoadingCourses = true;
    notifyListeners();

    try {
      _courses = await _db.getStudentCourses(semester.id);
      notifyListeners();
    } catch (e) {
      _log.log(
        'No cached courses for semester ${semester.id}: $e',
        level: LogLevel.debug,
      );
    }

    await _fetchCoursesForSemester(semester, notify: false);

    _isLoadingCourses = false;
    notifyListeners();

    await _afterCoursesChanged();
  }

  /// Fetches the timetable for [semester] from the API and caches it. Falls
  /// back to whatever is already cached when the request fails.
  Future<void> _fetchCoursesForSemester(
    Semester semester, {
    bool notify = true,
  }) async {
    final token = await ensureValidToken();
    if (token == null) return;

    if (notify) {
      _isLoadingCourses = true;
      notifyListeners();
    }

    try {
      final courses = await _authService.getStudentCourseSubject(
        token,
        semester.id,
      );

      _courses = courses;
      await _db.saveStudentCourses(semester.id, courses);

      _log.log(
        'Loaded ${courses.length} courses for semester ${semester.semesterName}',
        level: LogLevel.info,
      );
    } catch (e) {
      _log.log('Could not load courses from API: $e', level: LogLevel.warning);

      if (_courses.isEmpty) {
        try {
          _courses = await _db.getStudentCourses(semester.id);
        } catch (_) {
          // Nothing cached either — leave the list empty.
        }
      }
    } finally {
      if (notify) {
        _isLoadingCourses = false;
        notifyListeners();
      }
    }
  }

  /// Courses that actually take place on [date], honouring each course's
  /// start/end date range. Callers still filter by `dayOfWeek`.
  List<StudentCourseSubject> getActiveCourses(DateTime date) {
    final semester = _selectedSemester;
    if (semester == null || _courses.isEmpty) {
      return const <StudentCourseSubject>[];
    }

    final semesterStart = DateTime.fromMillisecondsSinceEpoch(
      semester.startDate,
    );

    return _courses
        .where((course) => course.isActiveOn(date, semesterStart))
        .toList();
  }

  /// Re-downloads everything for the signed-in student. Used by the "Cập nhật
  /// dữ liệu" button in Settings.
  Future<void> reloadAllData() async {
    if (!isLoggedIn) {
      throw Exception('Chưa đăng nhập');
    }

    _log.log('Reloading all data', level: LogLevel.info);
    // A manual refresh is the moment someone is diagnosing a problem, so let
    // the endpoint probing describe itself in full again.
    AuthService.resetProbeLogging();
    await _syncAllData();

    // Refresh exam data too, so the exam tab isn't left stale.
    final semester = _selectedSemester;
    final token = _accessToken;
    if (semester != null && token != null && _examProvider != null) {
      try {
        await _examProvider!.fetchExamSchedule(token, semester.id);
      } catch (e) {
        _log.log('Exam refresh failed: $e', level: LogLevel.warning);
      }
    }

    notifyListeners();
  }

  /// Reschedules class notifications and refreshes the home-screen widget after
  /// the timetable changed.
  Future<void> _afterCoursesChanged() async {
    try {
      await _scheduleClassNotifications();
    } catch (e) {
      _log.log(
        'Failed scheduling class notifications: $e',
        level: LogLevel.warning,
      );
    }

    try {
      await _widgetService.updateWidget(
        courses: _courses,
        semesterId: _selectedSemester?.id,
      );
    } catch (e) {
      _log.log('Failed updating widget: $e', level: LogLevel.warning);
    }
  }

  // ===========================================================================
  // Education program (chương trình đào tạo)
  // ===========================================================================

  /// Loads the education program, preferring the local cache.
  ///
  /// The program is fixed for a student's whole degree, so it is fetched once
  /// and then served from SQLite. Pass [forceRefresh] to re-fetch from the API
  /// (done automatically during a full sync).
  Future<List<ProgramSubject>> fetchEducationProgram({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _educationProgram.isNotEmpty) {
      return _educationProgram;
    }

    if (!forceRefresh) {
      final cached = await _db.getEducationProgram();
      if (cached.isNotEmpty) {
        _educationProgram = cached;
        notifyListeners();
        return _educationProgram;
      }
    }

    final token = await ensureValidToken();
    if (token == null) {
      _log.log(
        'Chương trình đào tạo: không có phiên đăng nhập hợp lệ',
        level: LogLevel.warning,
      );
      return _educationProgram;
    }

    _isLoadingEducationProgram = true;
    notifyListeners();

    try {
      final subjects = await _authService.getEducationProgram(token);

      if (subjects.isNotEmpty) {
        _educationProgram = subjects;
        await _db.saveEducationProgram(subjects);
        _log.log(
          'Education program: ${subjects.length} subjects, '
          '$educationProgramCredits credits',
          level: LogLevel.success,
        );
      } else {
        _log.log('Education program came back empty', level: LogLevel.warning);
      }
    } catch (e) {
      _log.log('Could not load education program: $e', level: LogLevel.warning);

      // Fall back to whatever is cached so the screen still shows something.
      if (_educationProgram.isEmpty) {
        _educationProgram = await _db.getEducationProgram();

        final cachedMarks = await _db.getAllMarks();
        _marksBySemester = <int, List<StudentSubjectMark>>{};
        for (final mark in cachedMarks) {
          _marksBySemester.putIfAbsent(mark.semesterId, () => []).add(mark);
        }
        _behaviorMarks = await _db.getBehaviorMarks();
        _tuition = await _db.getTuition() ?? StudentTuition.empty;
      }
    } finally {
      _isLoadingEducationProgram = false;
      notifyListeners();
    }

    return _educationProgram;
  }

  // ===========================================================================
  // Marks, behaviour scores and tuition
  // ===========================================================================

  /// Pulls điểm, rèn luyện and học phí and writes them to SQLite.
  ///
  /// Called from [_syncAllData] at login and on a manual refresh, so the
  /// Tiện ích screens read from the cache instead of hitting four endpoints
  /// every time they are opened. Each part is independent: a failure in one
  /// leaves the others - and the previous cache - intact.
  Future<void> syncUtilitiesData() async {
    if (_isSyncingUtilities) return;
    _isSyncingUtilities = true;
    notifyListeners();

    try {
      final token = await ensureValidToken();
      if (token == null) {
        _log.log(
          'Tiện ích: không có phiên hợp lệ, giữ dữ liệu đã lưu',
          level: LogLevel.warning,
        );
        return;
      }

      // Marks, one request per semester the student has actually studied.
      final semesters = allSemesters;
      if (semesters.isNotEmpty) {
        final collected = <int, List<StudentSubjectMark>>{};
        for (final semester in semesters) {
          try {
            final marks = await _withValidToken(
              'Điểm kỳ ${semester.id}',
              (t) => _authService.getStudentMarks(t, semester.id),
              const <StudentSubjectMark>[],
            );
            if (marks.isNotEmpty) {
              collected[semester.id] = marks;
              await _db.saveMarksForSemester(semester.id, marks);
            }
          } catch (e) {
            _log.log('Điểm kỳ ${semester.id}: $e', level: LogLevel.warning);
          }
        }
        if (collected.isNotEmpty) {
          _marksBySemester = collected;
          _log.log(
            'Đã lưu điểm: ${collected.length} kỳ, '
            '${allMarks.length} học phần',
            level: LogLevel.success,
          );
        }
      }

      try {
        final behavior = await _withValidToken(
          'Điểm rèn luyện',
          _authService.getBehaviorMarks,
          const <StudentBehaviorMark>[],
        );
        if (behavior.isNotEmpty) {
          _behaviorMarks = behavior;
          await _db.saveBehaviorMarks(behavior);
          _log.log(
            'Đã lưu ${behavior.length} kỳ điểm rèn luyện',
            level: LogLevel.success,
          );
        }
      } catch (e) {
        _log.log('Điểm rèn luyện: $e', level: LogLevel.warning);
      }

      try {
        final tuition = await _withValidToken(
          'Học phí',
          _authService.getStudentPayable,
          StudentTuition.empty,
        );
        if (!tuition.isEmpty) {
          _tuition = tuition;
          await _db.saveTuition(tuition);
          _log.log(
            'Đã lưu học phí: ${tuition.fees.length} khoản, '
            '${tuition.payments.length} biên lai',
            level: LogLevel.success,
          );
        }
      } catch (e) {
        _log.log('Học phí: $e', level: LogLevel.warning);
      }
    } finally {
      _isSyncingUtilities = false;
      notifyListeners();
    }
  }

  /// Marks for one semester, straight from the cache.
  ///
  /// Kept as a Future so existing callers do not have to change; it no longer
  /// touches the network - [syncUtilitiesData] owns that.
  Future<List<StudentSubjectMark>> fetchStudentMarks(int semesterId) async {
    final cached = _marksBySemester[semesterId];
    if (cached != null) return cached;

    final fromDb = await _db.getMarksForSemester(semesterId);
    if (fromDb.isNotEmpty) {
      _marksBySemester[semesterId] = fromDb;
    }
    return fromDb;
  }

  /// Conduct scores from the cache.
  Future<List<StudentBehaviorMark>> fetchBehaviorMarks() async {
    if (_behaviorMarks.isNotEmpty) return _behaviorMarks;
    _behaviorMarks = await _db.getBehaviorMarks();
    return _behaviorMarks;
  }

  /// Tuition from the cache.
  Future<StudentTuition> fetchStudentPayable() async {
    if (!_tuition.isEmpty) return _tuition;
    _tuition = await _db.getTuition() ?? StudentTuition.empty;
    return _tuition;
  }

  // ===========================================================================
  // Notifications
  // ===========================================================================

  /// Refreshes [hasNotificationPermission] from the OS.
  Future<void> checkNotificationPermission() async {
    try {
      final granted = await _notificationService.areNotificationsEnabled();
      if (granted != _hasNotificationPermission) {
        _hasNotificationPermission = granted;
        notifyListeners();
      }

      // The OS permission can be revoked from system settings while the app is
      // installed — keep our own switch honest about that.
      if (!granted && _notificationsEnabled) {
        _notificationsEnabled = false;
        await _prefs?.setBool(_kNotificationsEnabled, false);
        notifyListeners();
      }
    } catch (e) {
      _log.log(
        'Could not read notification permission: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Turns class/exam notifications on or off.
  ///
  /// Returns `false` when enabling was refused because the OS permission is not
  /// granted, so the caller can prompt the user to open system settings.
  Future<bool> toggleNotifications(bool value) async {
    if (value) {
      var granted = await _notificationService.areNotificationsEnabled();

      if (!granted) {
        granted = await _notificationService.requestPermissions();
      }

      _hasNotificationPermission = granted;

      if (!granted) {
        _notificationsEnabled = false;
        await _prefs?.setBool(_kNotificationsEnabled, false);
        notifyListeners();
        return false;
      }

      _notificationsEnabled = true;
      await _prefs?.setBool(_kNotificationsEnabled, true);
      notifyListeners();

      await _scheduleClassNotifications();
      return true;
    }

    _notificationsEnabled = false;
    await _prefs?.setBool(_kNotificationsEnabled, false);

    try {
      await NotificationHelper.cancelAllNotifications();
    } catch (e) {
      _log.log('Failed cancelling notifications: $e', level: LogLevel.warning);
    }

    // Daily summaries are a sub-setting of notifications — turn them off too.
    if (_dailyNotificationsEnabled) {
      _dailyNotificationsEnabled = false;
      await _prefs?.setBool(_kDailyNotificationsEnabled, false);
      try {
        await DailyNotificationService.cancelDailyCheck();
      } catch (e) {
        _log.log('Failed cancelling daily check: $e', level: LogLevel.warning);
      }
    }

    notifyListeners();
    return true;
  }

  /// Turns the 7:00 AM daily summary on or off.
  Future<void> toggleDailyNotifications(bool value) async {
    _dailyNotificationsEnabled = value;
    await _prefs?.setBool(_kDailyNotificationsEnabled, value);
    notifyListeners();

    try {
      if (value) {
        await DailyNotificationService.scheduleDailyCheck();
        _log.log('Daily summary scheduled', level: LogLevel.info);
      } else {
        await DailyNotificationService.cancelDailyCheck();
        _log.log('Daily summary cancelled', level: LogLevel.info);
      }
    } catch (e) {
      _log.log(
        'Failed toggling daily notifications: $e',
        level: LogLevel.error,
      );
    }
  }

  /// (Re)schedules reminders for this week's classes.
  Future<void> _scheduleClassNotifications() async {
    if (!_notificationsEnabled) return;

    final semester = _selectedSemester;
    if (semester == null || _courses.isEmpty || _courseHours.isEmpty) return;

    final semesterStart = DateTime.fromMillisecondsSinceEpoch(
      semester.startDate,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    await NotificationHelper.scheduleWeekClassNotifications(
      courses: _courses,
      courseHours: _courseHours,
      weekStartDate: weekStart,
      semesterStartDate: semesterStart,
    );
  }
}

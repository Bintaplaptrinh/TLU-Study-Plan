import 'dart:convert';
import 'dart:io';

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/services/log_service.dart';

class AuthService {
  static final LogService _log = LogService();

  /// Labels whose full probe detail has already been logged once.
  ///
  /// Marks are fetched per semester, so without this the log would repeat the
  /// same six candidate paths nine times over and bury everything else.
  static final Set<String> _probeLogged = <String>{};

  /// Forget what has been logged, so the next probe reports in full again.
  static void resetProbeLogging() => _probeLogged.clear();

  /// Tries [endpoints] in order and returns the first 200 response's decoded
  /// body, logging what happened at each step.
  ///
  /// The portal does not document these paths, so the app probes a list of
  /// candidates. Previously every failure was swallowed by a bare `continue`,
  /// which meant a wrong path, an auth error and a parse error all looked
  /// identical: an empty screen. Now each attempt is recorded, so a mismatch
  /// can be diagnosed from Cài đặt -> Nhật ký.
  Future<dynamic> _probeEndpoints(
    String accessToken,
    String label,
    List<String> endpoints,
  ) async {
    final verbose = _probeLogged.add(label);

    for (final endpoint in endpoints) {
      try {
        final httpClient = HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

        final request = await httpClient.getUrl(Uri.parse('$baseUrl$endpoint'));
        request.headers.add('Authorization', 'Bearer $accessToken');
        request.headers.add('Accept', 'application/json');

        final response = await request.close().timeout(apiTimeout);
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          dynamic decoded;
          try {
            decoded = jsonDecode(body);
          } catch (_) {
            if (verbose) {
              _log.log(
                '$label: $endpoint trả 200 nhưng không phải JSON',
                level: LogLevel.warning,
              );
            }
            continue;
          }

          _log.log(
            '$label: OK $endpoint (${body.length} bytes)',
            level: LogLevel.success,
          );
          if (verbose) _logShape(label, decoded);
          return decoded;
        }

        if (verbose) {
          _log.log(
            '$label: $endpoint -> ${response.statusCode}',
            level: response.statusCode == 404
                ? LogLevel.info
                : LogLevel.warning,
          );
        }

        // 401/403 mean the token is the problem, not the path - stop probing.
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception(
            'Phiên đăng nhập đã hết hạn (${response.statusCode})',
          );
        }
      } on Exception catch (e) {
        if (e.toString().contains('hết hạn')) rethrow;
        if (verbose) {
          _log.log('$label: $endpoint lỗi: $e', level: LogLevel.warning);
        }
      }
    }

    _log.log('$label: KHÔNG endpoint nào trả dữ liệu', level: LogLevel.error);
    return null;
  }

  /// Records the *shape* of a successful response: the envelope key and the
  /// field names of the first row.
  ///
  /// Only names are written, never values - the log is meant to be shareable
  /// for debugging without leaking grades, fees or personal details.
  void _logShape(String label, dynamic decoded) {
    try {
      String envelope;
      List<dynamic> rows;

      if (decoded is List) {
        envelope = 'mảng gốc';
        rows = decoded;
      } else if (decoded is Map) {
        // A plain loop rather than firstWhere: the map's value type is
        // dynamic here, and an orElse sentinel trips Dart's runtime check on
        // the closure's return type - which would throw inside the very
        // diagnostic meant to explain a failure.
        String? listKey;
        for (final entry in decoded.entries) {
          if (entry.value is List) {
            listKey = entry.key.toString();
            break;
          }
        }
        envelope = listKey == null
            ? 'object: ${decoded.keys.take(12).join(", ")}'
            : 'object.$listKey';
        rows = listKey == null ? const [] : decoded[listKey] as List;
      } else {
        _log.log(
          '$label: kiểu dữ liệu lạ ${decoded.runtimeType}',
          level: LogLevel.warning,
        );
        return;
      }

      _log.log(
        '$label: envelope=$envelope, ${rows.length} bản ghi',
        level: LogLevel.info,
      );

      final first = rows.isEmpty ? null : rows.first;
      if (first is Map) {
        _log.log(
          '$label: trường = ${first.keys.join(", ")}',
          level: LogLevel.info,
        );
        // One level of nesting matters for these endpoints (semester.id,
        // subject.subjectCode), so nested object keys are listed too.
        for (final entry in first.entries) {
          if (entry.value is Map) {
            final nested = (entry.value as Map).keys.take(15).join(", ");
            _log.log(
              '$label:   ${entry.key}.{ $nested }',
              level: LogLevel.info,
            );
          }
        }
      } else if (rows.isNotEmpty) {
        _log.log(
          '$label: bản ghi đầu không phải object '
          '(${first.runtimeType})',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      _log.log('$label: không đọc được cấu trúc: $e', level: LogLevel.warning);
    }
  }

  /// Pulls the row list out of whichever envelope the portal used.
  List<dynamic> _rowsOf(dynamic decoded, {List<String> extraKeys = const []}) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['content', ...extraKeys, 'data', 'items', 'rows']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  static const String baseUrl = 'https://sinhvien1.tlu.edu.vn/education';
  static const String tokenEndpoint = '/oauth/token';
  static const String userEndpoint = '/api/users/getCurrentUser';

  // OAuth credentials (fixed by TLU)
  static const String clientId = 'education_client';
  static const String clientSecret = 'password';
  static const String grantType = 'password';

  // Timeout optimized for faster parallel execution
  static const Duration apiTimeout = Duration(seconds: 10);

  /// Authenticate user with student code and password
  /// Exchanges a refresh token for a fresh access token.
  ///
  /// The portal's OAuth server issues a refresh token alongside every login,
  /// and the app already stored it - it just never spent it. Without this the
  /// access token simply died after `expires_in`, which is why the cached
  /// screens kept working while anything live (điểm, rèn luyện, học phí,
  /// CTĐT) started failing.
  Future<LoginResponse> refreshAccessToken(String refreshToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.postUrl(
        Uri.parse('$baseUrl$tokenEndpoint'),
      );
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      request.headers.add('Accept', 'application/json');
      request.write(
        'client_id=$clientId&client_secret=$clientSecret'
        '&grant_type=refresh_token'
        '&refresh_token=${Uri.encodeQueryComponent(refreshToken)}',
      );

      final response = await request.close().timeout(apiTimeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        _log.log('Đã làm mới access token', level: LogLevel.success);
        return LoginResponse.fromJson(jsonDecode(body));
      }

      _log.log(
        'Làm mới token thất bại (${response.statusCode})',
        level: LogLevel.warning,
      );
      throw Exception(
        'Không làm mới được phiên đăng nhập '
        '(${response.statusCode})',
      );
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      rethrow;
    }
  }

  Future<LoginResponse> login(String studentCode, String password) async {
    try {
      // Use dart:io HttpClient with SSL verification disabled
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.postUrl(
        Uri.parse('$baseUrl$tokenEndpoint'),
      );
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      request.headers.add('Accept', 'application/json');

      // Add form data
      request.write(
        'client_id=$clientId&client_secret=$clientSecret&grant_type=$grantType&username=$studentCode&password=$password',
      );

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return LoginResponse.fromJson(jsonResponse);
      } else {
        try {
          final errorBody = jsonDecode(responseBody);
          final errorDesc =
              errorBody['error_description'] ?? 'Đăng nhập thất bại';
          throw Exception(errorDesc);
        } catch (e) {
          throw Exception('Đăng nhập thất bại: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Không thể kết nối. Kiểm tra internet của bạn.');
      } else if (e.toString().contains('timed out')) {
        throw Exception('Timeout kết nối. Vui lòng kiểm tra internet.');
      }
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  /// Fetch current user information using access token
  Future<TluUser> getCurrentUser(String accessToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl$userEndpoint'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return TluUser.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Không thể lấy dữ liệu người dùng (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy dữ liệu: $e');
    }
  }

  /// Check if access token is still valid
  Future<bool> isTokenValid(String accessToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl$userEndpoint'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch school years and semesters
  /// Endpoint: GET /api/schoolyear/1/10000
  Future<SchoolYearResponse> getSchoolYears(String accessToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/schoolyear/1/10000'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return SchoolYearResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Không thể lấy dữ liệu năm học (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy dữ liệu năm học: $e');
    }
  }

  /// Fetch current semester information
  /// Endpoint: GET /api/semester/semester_info
  /// Returns: Detailed semester with registration periods and exam schedules
  Future<SemesterInfo> getSemesterInfo(String accessToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/semester/semester_info'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return SemesterInfo.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Không thể lấy dữ liệu kỳ học (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy dữ liệu kỳ học: $e');
    }
  }

  /// Fetch course hours (time slots: Tiết 1-15)
  /// Endpoint: GET /api/coursehour/1/1000
  /// Returns: Map of CourseHour objects by ID
  Future<Map<int, CourseHour>> getCourseHours(String accessToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/coursehour/1/1000'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);

        final Map<int, CourseHour> courseHours = {};

        // Handle paginated response with 'content' field
        if (jsonResponse is Map && jsonResponse.containsKey('content')) {
          final List contentList = jsonResponse['content'] ?? [];

          for (var item in contentList) {
            final courseHour = CourseHour.fromJson(item);
            courseHours[courseHour.id] = courseHour;
          }
        }

        return courseHours;
      } else {
        throw Exception(
          'Không thể lấy dữ liệu tiết học (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy dữ liệu tiết học: $e');
    }
  }

  /// Fetch student's courses for a specific semester
  /// Endpoint: GET /api/StudentCourseSubject/studentLoginUser/{semesterId}
  /// Parameter: semesterId - from Semester.id (e.g., 11, 12, 13, 14)
  /// Returns: List of StudentCourseSubject objects
  Future<List<StudentCourseSubject>> getStudentCourseSubject(
    String accessToken,
    int semesterId,
  ) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse(
          '$baseUrl/api/StudentCourseSubject/studentLoginUser/$semesterId',
        ),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);

        // Handle both array and object responses
        List<dynamic> rawCourses = [];
        if (jsonResponse is List) {
          rawCourses = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('content')) {
          rawCourses = jsonResponse['content'] ?? [];
        }

        // Expand courses: create one entry per timetable
        List<StudentCourseSubject> expandedCourses = [];
        for (var courseJson in rawCourses) {
          // Check if courseSubject has multiple timetables
          if (courseJson['courseSubject'] is Map) {
            final courseSubject = courseJson['courseSubject'];
            final timetables = courseSubject['timetables'];

            if (timetables is List && timetables.isNotEmpty) {
              // Create one StudentCourseSubject per timetable
              for (var timetable in timetables) {
                // Create a modified JSON with only this timetable
                final modifiedJson = Map<String, dynamic>.from(courseJson);
                final modifiedCourseSubject = Map<String, dynamic>.from(
                  courseSubject,
                );
                modifiedCourseSubject['timetables'] = [timetable];
                modifiedJson['courseSubject'] = modifiedCourseSubject;

                expandedCourses.add(
                  StudentCourseSubject.fromJson(modifiedJson),
                );
              }
            } else {
              // No timetables, add as is
              expandedCourses.add(StudentCourseSubject.fromJson(courseJson));
            }
          } else {
            // No courseSubject, add as is
            expandedCourses.add(StudentCourseSubject.fromJson(courseJson));
          }
        }

        return expandedCourses;
      } else {
        throw Exception(
          'Không thể lấy dữ liệu học phần (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy dữ liệu học phần: $e');
    }
  }

  /// Fetch register periods (exam periods) for a specific semester
  /// Endpoint: GET /api/registerperiod/find/{semesterId}
  /// Parameter: semesterId - from Semester.id (e.g., 11, 12, 13)
  /// Returns: List of RegisterPeriod objects containing exam information
  Future<List<RegisterPeriod>> getRegisterPeriods(
    String accessToken,
    int semesterId,
  ) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/registerperiod/find/$semesterId'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);

        // Response is an array of register periods
        if (jsonResponse is List) {
          return jsonResponse
              .map((item) => RegisterPeriod.fromJson(item))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Không thể lấy dữ liệu lịch thi (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy dữ liệu lịch thi: $e');
    }
  }

  /// Fetch all semesters with pagination
  /// Endpoint: GET /api/semester/{page}/{size}
  Future<SemesterListResponse> getAllSemesters(
    String accessToken, {
    int page = 1,
    int size = 100,
  }) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/semester/$page/$size'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return SemesterListResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Không thể lấy danh sách học kỳ (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy danh sách học kỳ: $e');
    }
  }

  /// Fetch student exam room details by semester, register period, and exam round
  /// Endpoint: GET /api/semestersubjectexamroom/getListRoomByStudentByLoginUser/{semesterId}/{registerPeriodId}/{examRound}
  Future<List<StudentExamRoom>> getStudentExamRooms(
    String accessToken,
    int semesterId,
    int registerPeriodId,
    int examRound,
  ) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse(
          '$baseUrl/api/semestersubjectexamroom/getListRoomByStudentByLoginUser/$semesterId/$registerPeriodId/$examRound',
        ),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);

        // Response is an array of student exam rooms
        if (jsonResponse is List) {
          return jsonResponse
              .map((item) => StudentExamRoom.fromJson(item))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Không thể lấy thông tin phòng thi (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy thông tin phòng thi: $e');
    }
  }

  /// Fetch student subject marks for a specific semester
  /// Tries multiple endpoints to find the correct one
  /// Returns: List of StudentSubjectMark objects (điểm sinh viên)
  /// Note: This is real-time data, should NOT be cached
  /// Course results for one semester.
  ///
  /// Endpoint confirmed against a live account; the alternatives that used to
  /// be probed all answer 404, so they are gone.
  Future<List<StudentSubjectMark>> getStudentMarks(
    String accessToken,
    int semesterId,
  ) async {
    final decoded = await _probeEndpoints(accessToken, 'Điểm học phần', [
      '/api/studentsubjectmark/getListStudentMarkBySemesterByLoginUser/$semesterId',
    ]);

    return _rowsOf(decoded)
        .whereType<Map>()
        .map(
          (row) => StudentSubjectMark.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  /// Conduct scores across every semester.
  ///
  /// The response is a single object whose semesters sit two levels down, so
  /// the flattening lives in [StudentBehaviorMark.listFromResponse].
  Future<List<StudentBehaviorMark>> getBehaviorMarks(String accessToken) async {
    final decoded = await _probeEndpoints(accessToken, 'Điểm rèn luyện', [
      '/api/student_semester_behavior_mark/viewStudentBehaviorMarkByLoginUser',
    ]);

    return StudentBehaviorMark.listFromResponse(decoded);
  }

  /// Tuition: totals, what is owed per semester, and the receipts.
  ///
  /// Returns a summary object rather than a list - the old model mapped over a
  /// list that was never there, which is why the screen showed nothing.
  Future<StudentTuition> getStudentPayable(String accessToken) async {
    final decoded = await _probeEndpoints(accessToken, 'Học phí', [
      '/api/student/viewstudentpayablebyLoginUser',
    ]);

    if (decoded is Map) {
      return StudentTuition.fromJson(Map<String, dynamic>.from(decoded));
    }
    return StudentTuition.empty;
  }

  /// Fetch the student record tied to the logged-in account.
  ///
  /// Endpoint: GET /api/student/getstudentbylogin
  ///
  /// Richer than `getCurrentUser` - notably it carries the education program
  /// id needed by [getProgramSubjectTree]. Returned raw because the shape
  /// varies by student type and only a few fields are used.
  Future<Map<String, dynamic>> getStudentByLogin(String accessToken) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/student/getstudentbylogin'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) return decoded;
        throw Exception('Dữ liệu sinh viên không hợp lệ');
      } else {
        throw Exception(
          'Không thể lấy thông tin sinh viên (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy thông tin sinh viên: $e');
    }
  }

  /// Fetch the education program tree for [programId].
  ///
  /// Endpoint: GET /api/programsubject/tree/{programId}/1/1000
  ///
  /// Inner nodes are knowledge blocks, leaves are courses - see
  /// [ProgramSubject.fromTree].
  Future<dynamic> getProgramSubjectTree(
    String accessToken,
    int programId,
  ) async {
    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(
        Uri.parse('$baseUrl/api/programsubject/tree/$programId/1/1000'),
      );
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.add('Accept', 'application/json');

      final response = await request.close().timeout(apiTimeout);
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception(
          'Không thể lấy chương trình đào tạo (${response.statusCode})',
        );
      }
    } catch (e) {
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Lỗi chứng chỉ SSL. Vui lòng thử lại.');
      }
      throw Exception('Lỗi lấy chương trình đào tạo: $e');
    }
  }

  /// Resolve the student's program id, then fetch and flatten its course tree.
  ///
  /// Two round-trips because the program id only comes back from the student
  /// record; the id is stable, so callers should cache the result rather than
  /// repeat this on every screen open.
  Future<List<ProgramSubject>> getEducationProgram(String accessToken) async {
    final student = await getStudentByLogin(accessToken);

    final programId = _findProgramId(student);
    if (programId == null) {
      _log.log(
        'Không tìm thấy programId. Các trường có trong hồ sơ sinh viên: '
        '${student.keys.join(", ")}',
        level: LogLevel.error,
      );
      throw Exception('Không tìm thấy mã chương trình đào tạo của sinh viên');
    }

    final tree = await getProgramSubjectTree(accessToken, programId);
    _logShape('Chương trình đào tạo', tree);

    final subjects = ProgramSubject.fromTree(tree);

    final blocks = subjects.map((s) => s.knowledgeBlock).toSet();
    _log.log(
      'Chương trình đào tạo: programId=$programId, '
      '${subjects.length} học phần, ${blocks.length} khối kiến thức',
      level: subjects.isEmpty ? LogLevel.warning : LogLevel.info,
    );
    if (subjects.isNotEmpty && blocks.length <= 1) {
      // One block for the whole program means the response shape was not
      // recognised - worth flagging rather than silently showing "Khác".
      _log.log(
        'Chương trình đào tạo chỉ có 1 khối kiến thức - '
        'nhiều khả năng cấu trúc dữ liệu chưa được nhận diện đúng',
        level: LogLevel.warning,
      );
    }
    return subjects;
  }

  /// Digs the education program id out of a student record.
  ///
  /// The portal nests it differently depending on the account, so each known
  /// location is tried in turn.
  int? _findProgramId(Map<String, dynamic> student) {
    const paths = [
      // Confirmed on a live account: this is where TLU keeps it.
      ['enrollmentClass', 'program', 'id'],
      ['programs', '0', 'program', 'id'],
      ['program', 'id'],
      ['educationProgram', 'id'],
      ['programId'],
      ['course', 'program', 'id'],
      ['studentProgram', 'program', 'id'],
      ['trainingProgram', 'id'],
      // Seen on TLU accounts where the program hangs off the class or major
      // rather than the student record itself.
      ['studentClass', 'program', 'id'],
      ['major', 'program', 'id'],
      ['specialization', 'program', 'id'],
      ['enrollmentProgram', 'id'],
      ['programBySemester', 'id'],
      ['student', 'program', 'id'],
    ];

    for (final path in paths) {
      dynamic current = student;
      var ok = true;

      for (final key in path) {
        final index = int.tryParse(key);
        if (index != null && current is List) {
          if (index >= current.length) {
            ok = false;
            break;
          }
          current = current[index];
          continue;
        }
        if (current is Map && current[key] != null) {
          current = current[key];
        } else {
          ok = false;
          break;
        }
      }

      if (!ok || current == null) continue;
      if (current is int) return current;
      if (current is num) return current.toInt();
      final parsed = int.tryParse(current.toString());
      if (parsed != null) return parsed;
    }

    return null;
  }
}

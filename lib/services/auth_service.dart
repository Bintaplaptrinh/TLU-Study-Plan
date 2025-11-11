import 'dart:convert';
import 'dart:io';
import 'package:tlustudy_planner/models/api_response.dart';

class AuthService {
  static const String baseUrl = 'https://sinhvien1.tlu.edu.vn/education';
  static const String tokenEndpoint = '/oauth/token';
  static const String userEndpoint = '/api/users/getCurrentUser';

  // OAuth credentials (fixed by TLU)
  static const String clientId = 'education_client';
  static const String clientSecret = 'password';
  static const String grantType = 'password';

  /// Authenticate user with student code and password
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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
}

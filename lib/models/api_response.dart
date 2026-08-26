class LoginResponse {
  final String accessToken;
  final String tokenType;
  final String refreshToken;
  final int expiresIn;
  final String scope;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.refreshToken,
    required this.expiresIn,
    required this.scope,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
      scope: json['scope'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'scope': scope,
    };
  }
}

class TluUser {
  final int id;
  final String displayName;
  final String username;
  final String email;
  final bool active;
  final Person? person;
  final List<UserRole> roles;

  TluUser({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    required this.active,
    this.person,
    required this.roles,
  });

  factory TluUser.fromJson(Map<String, dynamic> json) {
    return TluUser(
      id: json['id'] ?? 0,
      displayName: json['displayName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      active: json['active'] ?? false,
      person: json['person'] != null ? Person.fromJson(json['person']) : null,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((r) => UserRole.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class Person {
  final int id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String? birthDateString;
  final String birthPlace;
  final String gender;
  final String phoneNumber;
  final String idNumber;
  final String email;
  final List<Address> address;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.birthDateString,
    required this.birthPlace,
    required this.gender,
    required this.phoneNumber,
    required this.idNumber,
    required this.email,
    required this.address,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      displayName: json['displayName'] ?? '',
      birthDateString: json['birthDateString'],
      birthPlace: json['birthPlace'] ?? '',
      gender: json['gender'] ?? 'M',
      phoneNumber: json['phoneNumber'] ?? '',
      idNumber: json['idNumber'] ?? '',
      email: json['email'] ?? '',
      address:
          (json['address'] as List<dynamic>?)
              ?.map((a) => Address.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class Address {
  final int id;
  final String address;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class UserRole {
  final int id;
  final String name;
  final String authority;

  UserRole({required this.id, required this.name, required this.authority});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      authority: json['authority'] ?? '',
    );
  }
}

// School Year / Semester Response
class SchoolYearResponse {
  final List<SchoolYear> content;
  final bool last;
  final int totalElements;
  final int totalPages;

  SchoolYearResponse({
    required this.content,
    required this.last,
    required this.totalElements,
    required this.totalPages,
  });

  factory SchoolYearResponse.fromJson(Map<String, dynamic> json) {
    var contentList = json['content'] as List;
    return SchoolYearResponse(
      content: contentList.map((item) => SchoolYear.fromJson(item)).toList(),
      last: json['last'] ?? true,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class SchoolYear {
  final int id;
  final String name;
  final String code;
  final int year;
  final bool current;
  final int startDate;
  final int endDate;
  final String displayName;
  final List<Semester> semesters;

  SchoolYear({
    required this.id,
    required this.name,
    required this.code,
    required this.year,
    required this.current,
    required this.startDate,
    required this.endDate,
    required this.displayName,
    required this.semesters,
  });

  factory SchoolYear.fromJson(Map<String, dynamic> json) {
    var semestersList = json['semesters'] as List?;
    return SchoolYear(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      year: json['year'] ?? 0,
      current: json['current'] ?? false,
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'] ?? 0,
      displayName: json['displayName'] ?? '',
      semesters: semestersList != null
          ? semestersList.map((item) => Semester.fromJson(item)).toList()
          : [],
    );
  }
}

class Semester {
  final int id;
  final String semesterCode;
  final String semesterName;
  final int startDate;
  final int endDate;
  final bool isCurrent;
  final int? ordinalNumbers; // For sorting semesters
  final List<SemesterRegisterPeriod> semesterRegisterPeriods;

  Semester({
    required this.id,
    required this.semesterCode,
    required this.semesterName,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    this.ordinalNumbers,
    required this.semesterRegisterPeriods,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    var periodsList = json['semesterRegisterPeriods'] as List?;
    return Semester(
      id: json['id'] ?? 0,
      semesterCode: json['semesterCode'] ?? '',
      semesterName: json['semesterName'] ?? '',
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'] ?? 0,
      isCurrent: json['isCurrent'] ?? false,
      ordinalNumbers: json['ordinalNumbers'],
      semesterRegisterPeriods: periodsList != null
          ? periodsList
                .map((item) => SemesterRegisterPeriod.fromJson(item))
                .toList()
          : [],
    );
  }

  /// Check if today's date falls within this semester
  bool isActive() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return startDate <= now && now <= endDate;
  }

  /// Get formatted semester display name
  String getDisplayName() {
    return semesterName;
  }
}

class SemesterRegisterPeriod {
  final int id;
  final String name;
  final int displayOrder;

  SemesterRegisterPeriod({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  factory SemesterRegisterPeriod.fromJson(Map<String, dynamic> json) {
    return SemesterRegisterPeriod(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}

// Detailed Semester Info Response
class SemesterInfo {
  final int id;
  final String semesterCode;
  final String semesterName;
  final SchoolYearBasic? schoolYear;
  final int startDate;
  final int endDate;
  final bool isCurrent;
  final int ordinalNumbers;
  final List<SemesterRegisterPeriodDetail> semesterRegisterPeriods;
  final List<ExamRegisterPeriod> examRegisterPeriods;
  final int typeMarkRecognition;

  SemesterInfo({
    required this.id,
    required this.semesterCode,
    required this.semesterName,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.ordinalNumbers,
    required this.semesterRegisterPeriods,
    required this.examRegisterPeriods,
    required this.typeMarkRecognition,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    var periodsList = json['semesterRegisterPeriods'] as List?;
    var examList = json['examRegisterPeriods'] as List?;

    return SemesterInfo(
      id: json['id'] ?? 0,
      semesterCode: json['semesterCode'] ?? '',
      semesterName: json['semesterName'] ?? '',
      schoolYear: json['schoolYear'] != null
          ? SchoolYearBasic.fromJson(json['schoolYear'])
          : null,
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'] ?? 0,
      isCurrent: json['isCurrent'] ?? false,
      ordinalNumbers: json['ordinalNumbers'] ?? 0,
      semesterRegisterPeriods: periodsList != null
          ? periodsList
                .map((item) => SemesterRegisterPeriodDetail.fromJson(item))
                .toList()
          : [],
      examRegisterPeriods: examList != null
          ? examList.map((item) => ExamRegisterPeriod.fromJson(item)).toList()
          : [],
      typeMarkRecognition: json['typeMarkRecognition'] ?? 0,
    );
  }
}

class SchoolYearBasic {
  final int id;
  final String name;
  final String code;
  final int year;
  final int startDate;
  final int endDate;

  SchoolYearBasic({
    required this.id,
    required this.name,
    required this.code,
    required this.year,
    required this.startDate,
    required this.endDate,
  });

  factory SchoolYearBasic.fromJson(Map<String, dynamic> json) {
    return SchoolYearBasic(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      year: json['year'] ?? 0,
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'] ?? 0,
    );
  }
}

class SemesterRegisterPeriodDetail {
  final int id;
  final String name;
  final int displayOrder;
  final int? startRegisterTime;
  final int? endRegisterTime;
  final int? endUnRegisterTime;
  final List<dynamic> examPeriods;

  SemesterRegisterPeriodDetail({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.startRegisterTime,
    required this.endRegisterTime,
    required this.endUnRegisterTime,
    required this.examPeriods,
  });

  factory SemesterRegisterPeriodDetail.fromJson(Map<String, dynamic> json) {
    var examList = json['examPeriods'] as List?;

    return SemesterRegisterPeriodDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      startRegisterTime: json['startRegisterTime'],
      endRegisterTime: json['endRegisterTime'],
      endUnRegisterTime: json['endUnRegisterTime'],
      examPeriods: examList ?? [],
    );
  }
}

class ExamRegisterPeriod {
  final int id;
  final String name;
  final String code;
  final int startDate;
  final int endDate;
  final bool isPublished;

  ExamRegisterPeriod({
    required this.id,
    required this.name,
    required this.code,
    required this.startDate,
    required this.endDate,
    required this.isPublished,
  });

  factory ExamRegisterPeriod.fromJson(Map<String, dynamic> json) {
    return ExamRegisterPeriod(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      startDate: json['start'] ?? json['fromDate'] ?? 0,
      endDate: json['end'] ?? json['toDate'] ?? 0,
      isPublished: json['isPublished'] ?? false,
    );
  }
}

// Course Hour (Class Time Slot)
class CourseHour {
  final int id;
  final String name; // "Tiết 1", "Tiết 2", etc.
  final int start; // Milliseconds (unused, for reference)
  final String startString; // "07:00"
  final int end; // Milliseconds (unused, for reference)
  final String endString; // "07:50"
  final int indexNumber; // Slot number 1-15
  final int type; // 1=Morning, 2=Afternoon, 3=Evening

  CourseHour({
    required this.id,
    required this.name,
    required this.start,
    required this.startString,
    required this.end,
    required this.endString,
    required this.indexNumber,
    required this.type,
  });

  factory CourseHour.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to string
    String _toString(dynamic value, {String defaultValue = '00:00'}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    return CourseHour(
      id: json['id'] ?? 0,
      name: _toString(json['name'], defaultValue: ''),
      start: json['start'] ?? 0,
      startString: _toString(json['startString'], defaultValue: '00:00'),
      end: json['end'] ?? 0,
      endString: _toString(json['endString'], defaultValue: '00:00'),
      indexNumber: json['indexNumber'] ?? 0,
      type: json['type'] ?? 1,
    );
  }
}

// Student Course Subject (Schedule)
class StudentCourseSubject {
  final int id;
  final String courseCode;
  final String courseName;
  final String classCode;
  final String className;
  final LecturerInfo? lecturer;
  final int dayOfWeek; // API returns 2=Monday, 3=Tuesday, ..., 8=Sunday
  final int startCourseHour; // Course hour ID (reference to CourseHour)
  final int endCourseHour; // Course hour ID (reference to CourseHour)
  final String room;
  final String building;
  final String campus;
  final int credits;
  final int startDate; // Milliseconds (timetable start date)
  final int endDate; // Milliseconds (timetable end date)
  final int fromWeek; // Week number (1-based) when this schedule starts
  final int toWeek; // Week number (1-based) when this schedule ends
  final String status; // "registered", "completed", "pending"
  final double? grade;

  StudentCourseSubject({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.classCode,
    required this.className,
    required this.lecturer,
    required this.dayOfWeek,
    required this.startCourseHour,
    required this.endCourseHour,
    required this.room,
    required this.building,
    required this.campus,
    required this.credits,
    required this.startDate,
    required this.endDate,
    required this.fromWeek,
    required this.toWeek,
    required this.status,
    required this.grade,
  });

  /// Check if this course schedule is active for a given date
  /// Takes into account the fromWeek-toWeek range and startDate-endDate
  bool isActiveOn(DateTime date, DateTime semesterStartDate) {
    // Convert all dates to date-only (midnight) for comparison
    // This is necessary because course dates may have time components (e.g., 07:00:00)
    // but we want to check if a calendar date falls within the course period
    final checkDate = DateTime(date.year, date.month, date.day);
    final courseStart = DateTime.fromMillisecondsSinceEpoch(startDate);
    final courseStartDate = DateTime(
      courseStart.year,
      courseStart.month,
      courseStart.day,
    );
    final courseEnd = DateTime.fromMillisecondsSinceEpoch(endDate);
    final courseEndDate = DateTime(
      courseEnd.year,
      courseEnd.month,
      courseEnd.day,
    );

    // Check if date falls within the course's date range (ignoring time-of-day)
    if (checkDate.isBefore(courseStartDate) ||
        checkDate.isAfter(courseEndDate)) {
      return false;
    }

    // Date is within the course's active period
    return true;
  }

  factory StudentCourseSubject.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from various types
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Helper to safely convert any value to string
    String _toString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    // Extract data from nested courseSubject if it exists
    Map<String, dynamic> courseSubjectData = {};
    if (json['courseSubject'] is Map) {
      courseSubjectData = json['courseSubject'];
    }

    // Parse course hour info from courseSubject or timetables
    int startHour = 0;
    int endHour = 0;
    int dayOfWeek = -1;
    String room = '';
    String building = '';
    String campus = '';
    int fromWeek = 1;
    int toWeek = 1;
    int timetableStartDate = 0;
    int timetableEndDate = 0;

    // Try to get schedule from timetables array (first entry if exists)
    if (courseSubjectData['timetables'] is List &&
        (courseSubjectData['timetables'] as List).isNotEmpty) {
      final timetable = courseSubjectData['timetables'][0];

      if (timetable is Map) {
        // Parse course hours from timetable
        // In the API, startHour and endHour are objects with id field
        var startHourObj = timetable['startHour'];
        var endHourObj = timetable['endHour'];

        if (startHourObj is Map) {
          startHour = parseInt(startHourObj['id']);
        } else if (timetable['startCourseHour'] is Map) {
          startHour = parseInt(timetable['startCourseHour']['id']);
        } else {
          startHour = parseInt(startHourObj ?? timetable['startTime']);
        }

        if (endHourObj is Map) {
          endHour = parseInt(endHourObj['id']);
        } else if (timetable['endCourseHour'] is Map) {
          endHour = parseInt(timetable['endCourseHour']['id']);
        } else {
          endHour = parseInt(endHourObj ?? timetable['endTime']);
        }

        // weekIndex is the day of week (0=Monday, 1=Tuesday, etc.)
        dayOfWeek = parseInt(timetable['weekIndex']);

        // Week range (fromWeek - toWeek)
        fromWeek = parseInt(timetable['fromWeek'], defaultValue: 1);
        toWeek = parseInt(timetable['toWeek'], defaultValue: 1);

        // Date range for this specific timetable
        timetableStartDate = parseInt(timetable['startDate']);
        timetableEndDate = parseInt(timetable['endDate']);

        // Room information is in a nested object
        if (timetable['room'] is Map) {
          room = _toString(timetable['room']['name']);
          building = _toString(timetable['room']['building']);
        } else {
          room = _toString(timetable['room']);
          building = _toString(timetable['building']);
        }

        campus = _toString(timetable['campus']);
      }
    }

    // Fallback to direct courseSubject fields if timetable didn't work
    if (startHour == 0 && courseSubjectData['startCourseHour'] != null) {
      var startHourObj = courseSubjectData['startCourseHour'];
      if (startHourObj is Map) {
        startHour = parseInt(startHourObj['id']);
      } else {
        startHour = parseInt(startHourObj);
      }
    }

    if (endHour == 0 && courseSubjectData['endCourseHour'] != null) {
      var endHourObj = courseSubjectData['endCourseHour'];
      if (endHourObj is Map) {
        endHour = parseInt(endHourObj['id']);
      } else {
        endHour = parseInt(endHourObj);
      }
    }

    if (dayOfWeek == -1 && courseSubjectData['dayOfWeek'] != null) {
      dayOfWeek = parseInt(courseSubjectData['dayOfWeek']);
    }

    if (room.isEmpty && courseSubjectData['room'] != null) {
      room = _toString(courseSubjectData['room']);
    }

    if (building.isEmpty && courseSubjectData['building'] != null) {
      building = _toString(courseSubjectData['building']);
    }

    if (campus.isEmpty && courseSubjectData['campus'] != null) {
      campus = _toString(courseSubjectData['campus']);
    }

    final credits = parseInt(
      json['numberOfCredit'] ?? json['credits'] ?? json['credit'],
    );
    final courseName = _toString(json['subjectName'] ?? json['courseName']);
    final courseCode = _toString(json['subjectCode'] ?? json['courseCode']);

    return StudentCourseSubject(
      id: parseInt(json['id']),
      courseCode: courseCode,
      courseName: courseName,
      classCode: _toString(courseSubjectData['classCode']),
      className: _toString(courseSubjectData['className']),
      lecturer: courseSubjectData['lecturer'] != null
          ? LecturerInfo.fromJson(courseSubjectData['lecturer'])
          : null,
      dayOfWeek: dayOfWeek,
      startCourseHour: startHour,
      endCourseHour: endHour,
      room: room,
      building: building,
      campus: campus,
      credits: credits,
      startDate: timetableStartDate > 0
          ? timetableStartDate
          : parseInt(courseSubjectData['startDate']),
      endDate: timetableEndDate > 0
          ? timetableEndDate
          : parseInt(courseSubjectData['endDate']),
      fromWeek: fromWeek,
      toWeek: toWeek,
      status: _toString(
        json['status'] ?? courseSubjectData['status'],
        defaultValue: 'registered',
      ),
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
    );
  }
}

class LecturerInfo {
  final int id;
  final String name;
  final String email;

  LecturerInfo({required this.id, required this.name, required this.email});

  factory LecturerInfo.fromJson(Map<String, dynamic> json) {
    return LecturerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

/// RegisterPeriod represents an exam registration period
class RegisterPeriod {
  final int id;
  final bool voided;
  final Semester semester;
  final String name;
  final int displayOrder;
  final List<ExamPeriod> examPeriods;

  RegisterPeriod({
    required this.id,
    required this.voided,
    required this.semester,
    required this.name,
    required this.displayOrder,
    required this.examPeriods,
  });

  factory RegisterPeriod.fromJson(Map<String, dynamic> json) {
    return RegisterPeriod(
      id: json['id'] ?? 0,
      voided: json['voided'] ?? false,
      semester: Semester.fromJson(json['semester'] ?? {}),
      name: json['name'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      examPeriods:
          (json['examPeriods'] as List<dynamic>?)
              ?.map((e) => ExamPeriod.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// ExamPeriod represents a specific exam within a registration period
class ExamPeriod {
  final int id;
  final String courseCode;
  final String courseName;
  final String classCode;
  final int credits;
  final String? examDate; // Date string from API
  final int? examDateTimestamp; // Timestamp if available
  final String examShift; // e.g., "10-12"
  final String timeSlot; // e.g., "15:40 - 18:20"
  final int numberOfStudents;
  final String room;

  ExamPeriod({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.classCode,
    required this.credits,
    this.examDate,
    this.examDateTimestamp,
    required this.examShift,
    required this.timeSlot,
    required this.numberOfStudents,
    required this.room,
  });

  factory ExamPeriod.fromJson(Map<String, dynamic> json) {
    return ExamPeriod(
      id: json['id'] ?? 0,
      courseCode: json['courseCode'] ?? json['subjectCode'] ?? '',
      courseName: json['courseName'] ?? json['subjectName'] ?? '',
      classCode: json['classCode'] ?? '',
      credits: json['credits'] ?? json['numberOfCredit'] ?? 0,
      examDate: json['examDate'],
      examDateTimestamp: json['examDateTimestamp'],
      examShift: json['examShift'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      numberOfStudents: json['numberOfStudents'] ?? 0,
      room: json['room'] ?? '',
    );
  }
}

/// SemesterListResponse represents a paginated list of semesters
class SemesterListResponse {
  final List<Semester> content;
  final bool last;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final int numberOfElements;

  SemesterListResponse({
    required this.content,
    required this.last,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.numberOfElements,
  });

  factory SemesterListResponse.fromJson(Map<String, dynamic> json) {
    return SemesterListResponse(
      content:
          (json['content'] as List<dynamic>?)
              ?.map((item) => Semester.fromJson(item))
              .toList() ??
          [],
      last: json['last'] ?? false,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      first: json['first'] ?? false,
      numberOfElements: json['numberOfElements'] ?? 0,
    );
  }
}

/// StudentExamRoom represents a student's exam room assignment
/// Returns the first usable value found by walking [paths] (dot-separated)
/// through [json].
///
/// The TLU portal moves fields between nesting levels between endpoints and
/// releases - `subjectName` may sit at the root, under `subject`, or under
/// `semesterSubject.subject`. Listing the known shapes here keeps a row
/// populated instead of silently rendering blank when the API shifts.
dynamic _dig(Map<String, dynamic>? json, List<String> paths) {
  if (json == null) return null;

  for (final path in paths) {
    dynamic current = json;
    var ok = true;

    for (final key in path.split('.')) {
      if (current is Map && current[key] != null) {
        current = current[key];
      } else {
        ok = false;
        break;
      }
    }

    if (ok && current != null && current != '') return current;
  }
  return null;
}

/// [_dig] coerced to a String, falling back to [defaultValue].
String _digString(
  Map<String, dynamic>? json,
  List<String> paths, {
  String defaultValue = '',
}) {
  final value = _dig(json, paths);
  if (value == null) return defaultValue;
  return value is String ? value : value.toString();
}

/// [_dig] coerced to a String or null (no empty-string placeholder).
String? _digStringOrNull(Map<String, dynamic>? json, List<String> paths) {
  final value = _dig(json, paths);
  if (value == null) return null;
  return value is String ? value : value.toString();
}

/// [_dig] coerced to an int, tolerating numeric strings and doubles.
int? _digInt(Map<String, dynamic>? json, List<String> paths) {
  final value = _dig(json, paths);
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// [_dig] coerced to a double, tolerating numeric strings.
double? _digDouble(Map<String, dynamic>? json, List<String> paths) {
  final value = _dig(json, paths);
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', ''));
}

/// Reads a nested object at the first path that holds a Map.
Map<String, dynamic>? _digMap(Map<String, dynamic>? json, List<String> paths) {
  final value = _dig(json, paths);
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class StudentExamRoom {
  final int id;
  final int status;
  final String? examCode;
  final int? examCodeNumber;
  final String? markingCode;
  final String examPeriodCode;
  final String subjectName;
  final String? studentCode;
  final int? examRound;
  final ExamRoomDetail? examRoom;

  StudentExamRoom({
    required this.id,
    required this.status,
    this.examCode,
    this.examCodeNumber,
    this.markingCode,
    required this.examPeriodCode,
    required this.subjectName,
    this.studentCode,
    this.examRound,
    this.examRoom,
  });

  factory StudentExamRoom.fromJson(Map<String, dynamic> json) {
    final examRoom = _digMap(json, [
      'examRoom',
      'semesterSubjectExamRoom',
      'room',
    ]);

    return StudentExamRoom(
      id: _digInt(json, ['id']) ?? 0,
      status: _digInt(json, ['status']) ?? 0,
      examCode: _digStringOrNull(json, [
        'examCode',
        'studentExamCode',
        'candidateNumber',
        'soBaoDanh',
      ]),
      examCodeNumber: _digInt(json, ['examCodeNumber', 'examCodeNo']),
      markingCode: _digStringOrNull(json, ['markingCode', 'markCode']),
      examPeriodCode: _digString(json, [
        'examPeriodCode',
        'examPeriod.code',
        'examPeriod.name',
        'semesterSubjectExam.name',
        'examPeriodName',
      ]),
      subjectName: _digString(json, [
        'subjectName',
        'subject.subjectName',
        'semesterSubject.subject.subjectName',
        'courseSubject.subjectName',
        'subject.name',
      ]),
      studentCode: _digStringOrNull(json, [
        'studentCode',
        'student.studentCode',
        'student.code',
      ]),
      examRound: _digInt(json, ['examRound', 'round', 'examTime']),
      examRoom: examRoom != null ? ExamRoomDetail.fromJson(examRoom) : null,
    );
  }
}

/// ExamRoomDetail represents detailed exam room information
class ExamRoomDetail {
  final int id;
  final String roomCode;
  final int? duration;
  final int? examDate;
  final String? examDateString;
  final int? numberExpectedStudent;
  final String? semesterName;
  final String? courseYearName;
  final String? registerPeriodName;
  final ExamHour? examHour;
  final Room? room;

  ExamRoomDetail({
    required this.id,
    required this.roomCode,
    this.duration,
    this.examDate,
    this.examDateString,
    this.numberExpectedStudent,
    this.semesterName,
    this.courseYearName,
    this.registerPeriodName,
    this.examHour,
    this.room,
  });

  factory ExamRoomDetail.fromJson(Map<String, dynamic> json) {
    final examHour = _digMap(json, [
      'examHour',
      'examCourseHour',
      'courseHour',
    ]);
    final room = _digMap(json, ['room', 'roomInfo']);

    return ExamRoomDetail(
      id: _digInt(json, ['id']) ?? 0,
      // Fall back to the room's own code/name so a row never renders
      // room-less just because the portal dropped the flattened field.
      roomCode: _digString(json, [
        'roomCode',
        'room.code',
        'room.name',
        'roomName',
      ]),
      duration: _digInt(json, ['duration', 'examDuration']),
      examDate: _digInt(json, ['examDate', 'dateExam', 'examRoom.examDate']),
      examDateString: _digStringOrNull(json, ['examDateString', 'examDateStr']),
      numberExpectedStudent: _digInt(json, [
        'numberExpectedStudent',
        'numberOfStudent',
      ]),
      semesterName: _digStringOrNull(json, [
        'semesterName',
        'semester.semesterName',
      ]),
      courseYearName: _digStringOrNull(json, [
        'courseYearName',
        'schoolYear.name',
      ]),
      registerPeriodName: _digStringOrNull(json, [
        'registerPeriodName',
        'registerPeriod.name',
      ]),
      examHour: examHour != null ? ExamHour.fromJson(examHour) : null,
      room: room != null ? Room.fromJson(room) : null,
    );
  }
}

/// ExamHour represents exam time slot
class ExamHour {
  final int id;
  final String? startString;
  final String? endString;
  final String? name;
  final String? code;

  ExamHour({
    required this.id,
    this.startString,
    this.endString,
    this.name,
    this.code,
  });

  factory ExamHour.fromJson(Map<String, dynamic> json) {
    return ExamHour(
      id: _digInt(json, ['id']) ?? 0,
      startString: _digStringOrNull(json, ['startString', 'start', 'gioThi']),
      endString: _digStringOrNull(json, ['endString', 'end']),
      name: _digStringOrNull(json, ['name', 'caThi']),
      code: _digStringOrNull(json, ['code']),
    );
  }
}

/// Room represents a physical room/location
class Room {
  final int id;
  final String name;
  final String code;

  Room({required this.id, required this.name, required this.code});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: _digInt(json, ['id']) ?? 0,
      name: _digString(json, ['name', 'roomName', 'code']),
      code: _digString(json, ['code', 'roomCode', 'name']),
    );
  }
}

/// StudentSubjectMark represents student's mark for a subject
/// One course result (điểm học phần).
///
/// Shape confirmed against
/// `GET /api/studentsubjectmark/getListStudentMarkBySemesterByLoginUser/{id}`,
/// which answers with a bare list. The course and semester are nested objects,
/// not flat fields - reading them as flat was why the marks screen stayed
/// empty even when the request succeeded.
class StudentSubjectMark {
  final int id;
  final String subjectCode;
  final String subjectName;
  final int credits;
  final int semesterId;
  final String semesterName;

  /// Final course mark on the 10-point scale (TKHP).
  final double? mark10;

  /// Same result on the 4-point scale.
  final double? mark4;

  /// Letter grade (A, B+, ...).
  final String? markLetter;

  /// Component marks: continuous assessment and the exam itself.
  final double? markProcess;
  final double? markExam;

  /// "ĐẠT" / "KHÔNG ĐẠT" style verdict from the portal.
  final String? result;

  /// Which attempt this row represents.
  final int examRound;
  final int studyTime;

  /// Whether the course counts toward the GPA, and whether the portal has
  /// published the result yet.
  final bool isCounted;
  final bool isPublished;

  const StudentSubjectMark({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    required this.semesterId,
    required this.semesterName,
    this.mark10,
    this.mark4,
    this.markLetter,
    this.markProcess,
    this.markExam,
    this.result,
    this.examRound = 1,
    this.studyTime = 1,
    this.isCounted = true,
    this.isPublished = true,
  });

  /// True when there is a passing letter grade or a numeric pass.
  bool get isPassed {
    final letter = (markLetter ?? '').toUpperCase();
    if (letter.isNotEmpty) return letter != 'F' && letter != 'D-';
    final verdict = (result ?? '').toUpperCase();
    if (verdict.contains('KHÔNG')) return false;
    if (verdict.contains('ĐẠT')) return true;
    final m = mark10;
    return m != null && m >= 4;
  }

  factory StudentSubjectMark.fromJson(Map<String, dynamic> json) {
    final subject = _digMap(json, ['subject']) ?? const <String, dynamic>{};
    final semester = _digMap(json, ['semester']) ?? const <String, dynamic>{};

    return StudentSubjectMark(
      id: _digInt(json, ['id']) ?? 0,
      subjectCode: _digString(json, [
        'subject.subjectCode',
        'subjectCode',
        'equivalentSubjectCode',
      ]),
      subjectName: _digString(json, [
        'subject.subjectName',
        'subjectName',
        'equivalentSubjectName',
      ]),
      credits: _digInt(json, ['subject.numberOfCredit', 'numberOfCredit']) ?? 0,
      semesterId: _digInt(json, ['semesterId', 'semester.id']) ?? 0,
      semesterName: _digString(json, [
        'semester.semesterName',
        'semester.semesterCode',
        'semesterName',
      ]),
      mark10: _digDouble(json, ['mark']),
      mark4: _digDouble(json, ['mark4']),
      markLetter: _digStringOrNull(json, ['charMark']),
      markProcess: _digDouble(json, ['markQT']),
      markExam: _digDouble(json, ['markTHI']),
      result: _digStringOrNull(json, ['result', 'status']),
      examRound: _digInt(json, ['examRound']) ?? 1,
      studyTime: _digInt(json, ['studyTime']) ?? 1,
      isCounted: json['isCounted'] != false,
      isPublished: json['isPublished'] != false,
      // Referenced so the analyzer keeps the locals meaningful even when the
      // portal omits the nested objects entirely.
    )._withFallback(subject, semester);
  }

  /// Fills code/name/credits from the nested objects when the flat lookup
  /// found nothing (some rows carry only one of the two forms).
  StudentSubjectMark _withFallback(
    Map<String, dynamic> subject,
    Map<String, dynamic> semester,
  ) {
    if (subjectCode.isNotEmpty && semesterName.isNotEmpty) return this;
    return StudentSubjectMark(
      id: id,
      subjectCode: subjectCode.isNotEmpty
          ? subjectCode
          : (subject['subjectCode']?.toString() ?? ''),
      subjectName: subjectName.isNotEmpty
          ? subjectName
          : (subject['subjectName']?.toString() ?? ''),
      credits: credits != 0
          ? credits
          : ((subject['numberOfCredit'] as num?)?.toInt() ?? 0),
      semesterId: semesterId,
      semesterName: semesterName.isNotEmpty
          ? semesterName
          : (semester['semesterName']?.toString() ?? ''),
      mark10: mark10,
      mark4: mark4,
      markLetter: markLetter,
      markProcess: markProcess,
      markExam: markExam,
      result: result,
      examRound: examRound,
      studyTime: studyTime,
      isCounted: isCounted,
      isPublished: isPublished,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'credits': credits,
    'semesterId': semesterId,
    'semesterName': semesterName,
    'mark10': mark10,
    'mark4': mark4,
    'markLetter': markLetter,
    'markProcess': markProcess,
    'markExam': markExam,
    'result': result,
    'examRound': examRound,
    'studyTime': studyTime,
    'isCounted': isCounted,
    'isPublished': isPublished,
  };

  factory StudentSubjectMark.fromCache(Map<String, dynamic> json) {
    return StudentSubjectMark(
      id: _digInt(json, ['id']) ?? 0,
      subjectCode: _digString(json, ['subjectCode']),
      subjectName: _digString(json, ['subjectName']),
      credits: _digInt(json, ['credits']) ?? 0,
      semesterId: _digInt(json, ['semesterId']) ?? 0,
      semesterName: _digString(json, ['semesterName']),
      mark10: _digDouble(json, ['mark10']),
      mark4: _digDouble(json, ['mark4']),
      markLetter: _digStringOrNull(json, ['markLetter']),
      markProcess: _digDouble(json, ['markProcess']),
      markExam: _digDouble(json, ['markExam']),
      result: _digStringOrNull(json, ['result']),
      examRound: _digInt(json, ['examRound']) ?? 1,
      studyTime: _digInt(json, ['studyTime']) ?? 1,
      isCounted: json['isCounted'] != false && json['isCounted'] != 0,
      isPublished: json['isPublished'] != false && json['isPublished'] != 0,
    );
  }
}

/// One semester's conduct score (điểm rèn luyện).
///
/// `GET /api/student_semester_behavior_mark/viewStudentBehaviorMarkByLoginUser`
/// returns a single object, not a list: the semesters sit two levels down at
/// `schoolYearBehaviorMarks[].semesterMarks[]`. [listFromResponse] does that
/// walk so callers get the flat list they expect.
class StudentBehaviorMark {
  final int id;
  final int semesterId;
  final String semesterName;
  final String schoolYearName;
  final int mark;
  final String classification;

  const StudentBehaviorMark({
    required this.id,
    required this.semesterId,
    required this.semesterName,
    required this.schoolYearName,
    required this.mark,
    required this.classification,
  });

  /// Flattens the nested response into one row per semester, newest first.
  static List<StudentBehaviorMark> listFromResponse(dynamic decoded) {
    final results = <StudentBehaviorMark>[];

    void addSemester(Map<String, dynamic> row, String schoolYear) {
      final mark = _digInt(row, ['mark', 'totalMarkStudent']) ?? 0;

      // The readable grade sits in `sort` ("Khá"). `classification` is an
      // object whose own name field comes back empty, and `code` is a criteria
      // number like "2.3" - neither is usable, so both are skipped.
      var grade = _digString(row, [
        'sort',
        'classification.classificationName',
        'classification.name',
        'classificationName',
        'level.name',
      ]);
      if (grade.isEmpty) grade = classifyBehaviorMark(mark);

      results.add(
        StudentBehaviorMark(
          id: _digInt(row, ['id']) ?? 0,
          semesterId: _digInt(row, ['semester.id', 'semesterId']) ?? 0,
          semesterName: _digString(row, [
            'semester.semesterName',
            'semester.semesterCode',
            'semesterName',
          ]),
          schoolYearName: schoolYear,
          mark: mark,
          classification: grade,
        ),
      );
    }

    void walkYear(dynamic year) {
      if (year is! Map) return;
      final map = Map<String, dynamic>.from(year);
      final name = _digString(map, [
        'schoolYear.name',
        'schoolYear.displayName',
        'schoolYearName',
      ]);
      final semesters = map['semesterMarks'];
      if (semesters is List && semesters.isNotEmpty) {
        for (final row in semesters) {
          if (row is Map) addSemester(Map<String, dynamic>.from(row), name);
        }
      } else {
        // A year with no per-semester breakdown still carries its own score.
        addSemester(map, name);
      }
    }

    if (decoded is Map) {
      final years = decoded['schoolYearBehaviorMarks'];
      if (years is List) {
        for (final year in years) {
          walkYear(year);
        }
      }
    } else if (decoded is List) {
      for (final year in decoded) {
        walkYear(year);
      }
    }

    results.sort((a, b) => b.semesterId.compareTo(a.semesterId));
    return results;
  }

  factory StudentBehaviorMark.fromJson(Map<String, dynamic> json) {
    final mark = _digInt(json, ['mark']) ?? 0;
    var grade = _digString(json, ['classification', 'sort']);
    if (grade.isEmpty) grade = classifyBehaviorMark(mark);

    return StudentBehaviorMark(
      id: _digInt(json, ['id']) ?? 0,
      semesterId: _digInt(json, ['semesterId', 'semester.id']) ?? 0,
      semesterName: _digString(json, ['semesterName', 'semester.semesterName']),
      schoolYearName: _digString(json, ['schoolYearName', 'schoolYear.name']),
      mark: mark,
      classification: grade,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'semesterId': semesterId,
    'semesterName': semesterName,
    'schoolYearName': schoolYearName,
    'mark': mark,
    'classification': classification,
  };
}

/// Vietnamese conduct grade for a score out of 100.
///
/// Only used as a fallback: the portal normally supplies the label itself.
String classifyBehaviorMark(int mark) {
  if (mark >= 90) return 'Xuất sắc';
  if (mark >= 80) return 'Tốt';
  if (mark >= 65) return 'Khá';
  if (mark >= 50) return 'Trung bình';
  if (mark >= 35) return 'Yếu';
  return 'Kém';
}

/// One tuition line: either an amount owed for a semester, or a payment made.
class TuitionEntry {
  final int id;
  final String semesterName;
  final double amount;
  final double amountPaid;
  final String? dateString;
  final String? note;

  /// True for a receipt (đã nộp), false for an amount still payable.
  final bool isPayment;

  const TuitionEntry({
    required this.id,
    required this.semesterName,
    required this.amount,
    required this.amountPaid,
    required this.isPayment,
    this.dateString,
    this.note,
  });

  double get outstanding => (amount - amountPaid).clamp(0, double.infinity);

  factory TuitionEntry.fromReceivable(Map<String, dynamic> json) {
    return TuitionEntry(
      id: _digInt(json, ['id']) ?? 0,
      semesterName: _digString(json, [
        'semester.semesterName',
        'semester.semesterCode',
        'semesterName',
      ]),
      amount: _digDouble(json, ['amount', 'calculateAmount']) ?? 0,
      amountPaid: _digDouble(json, ['amountReceived', 'amountDone']) ?? 0,
      isPayment: false,
      note: _digStringOrNull(json, ['note', 'type']),
    );
  }

  factory TuitionEntry.fromReceipt(Map<String, dynamic> json) {
    return TuitionEntry(
      id: _digInt(json, ['id']) ?? 0,
      semesterName: _digString(json, [
        'semester.semesterName',
        'semester.semesterCode',
        'semesterName',
      ]),
      amount: _digDouble(json, ['totalRecivedAmount', 'totalAmount']) ?? 0,
      amountPaid: _digDouble(json, ['totalRecivedAmount', 'totalAmount']) ?? 0,
      isPayment: true,
      dateString: _digStringOrNull(json, ['voucherDate', 'createDate']),
      note: _digStringOrNull(json, ['note', 'paymentMethod', 'code']),
    );
  }

  factory TuitionEntry.fromCache(Map<String, dynamic> json) {
    return TuitionEntry(
      id: _digInt(json, ['id']) ?? 0,
      semesterName: _digString(json, ['semesterName']),
      amount: _digDouble(json, ['amount']) ?? 0,
      amountPaid: _digDouble(json, ['amountPaid']) ?? 0,
      isPayment: json['isPayment'] == true || json['isPayment'] == 1,
      dateString: _digStringOrNull(json, ['dateString']),
      note: _digStringOrNull(json, ['note']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'semesterName': semesterName,
    'amount': amount,
    'amountPaid': amountPaid,
    'isPayment': isPayment,
    'dateString': dateString,
    'note': note,
  };
}

/// The whole học phí picture for the signed-in student.
///
/// `GET /api/student/viewstudentpayablebyLoginUser` answers with a summary
/// object - totals plus two lists - rather than the flat list the old model
/// expected, so every row was being discarded.
class StudentTuition {
  final double totalReceivable;
  final double totalReceived;
  final double totalOutstanding;

  /// Amounts owed, one per semester.
  final List<TuitionEntry> fees;

  /// Receipts, newest last as the portal returns them.
  final List<TuitionEntry> payments;

  const StudentTuition({
    required this.totalReceivable,
    required this.totalReceived,
    required this.totalOutstanding,
    required this.fees,
    required this.payments,
  });

  static const StudentTuition empty = StudentTuition(
    totalReceivable: 0,
    totalReceived: 0,
    totalOutstanding: 0,
    fees: <TuitionEntry>[],
    payments: <TuitionEntry>[],
  );

  bool get isEmpty => fees.isEmpty && payments.isEmpty;

  static List<TuitionEntry> _entries(
    dynamic list,
    TuitionEntry Function(Map<String, dynamic>) build,
  ) {
    if (list is! List) return const <TuitionEntry>[];
    return list
        .whereType<Map>()
        .map((row) => build(Map<String, dynamic>.from(row)))
        .toList();
  }

  factory StudentTuition.fromJson(Map<String, dynamic> json) {
    final fees = _entries(json['receiveAbleDtos'], TuitionEntry.fromReceivable);
    final payments = _entries(json['receivedDtos'], TuitionEntry.fromReceipt);

    final receivable =
        _digDouble(json, ['totalReceiveAble']) ??
        fees.fold<double>(0, (sum, e) => sum + e.amount);
    final received =
        _digDouble(json, ['totalReceived']) ??
        payments.fold<double>(0, (sum, e) => sum + e.amount);

    return StudentTuition(
      totalReceivable: receivable,
      totalReceived: received,
      totalOutstanding:
          _digDouble(json, ['totalReceiveAbleNotComplete']) ??
          (receivable - received).clamp(0, double.infinity),
      fees: fees,
      payments: payments,
    );
  }

  factory StudentTuition.fromCache(Map<String, dynamic> json) {
    List<TuitionEntry> read(String key) {
      final list = json[key];
      if (list is! List) return const <TuitionEntry>[];
      return list
          .whereType<Map>()
          .map((e) => TuitionEntry.fromCache(Map<String, dynamic>.from(e)))
          .toList();
    }

    return StudentTuition(
      totalReceivable: _digDouble(json, ['totalReceivable']) ?? 0,
      totalReceived: _digDouble(json, ['totalReceived']) ?? 0,
      totalOutstanding: _digDouble(json, ['totalOutstanding']) ?? 0,
      fees: read('fees'),
      payments: read('payments'),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalReceivable': totalReceivable,
    'totalReceived': totalReceived,
    'totalOutstanding': totalOutstanding,
    'fees': fees.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
  };
}

/// One course in the student's education program (chương trình đào tạo).
///
/// The portal returns the program as a tree: inner nodes are knowledge blocks
/// (khối kiến thức) and leaves are the actual courses. [fromTree] flattens
/// that into a list, carrying each leaf's block name down with it.
class ProgramSubject {
  /// Knowledge block this course belongs to, e.g. "Kiến thức cơ sở ngành".
  final String knowledgeBlock;
  final String subjectCode;
  final String subjectName;
  final int credits;

  /// Which term the program schedules this course in. The portal is
  /// inconsistent here (sometimes "1", sometimes "Học kỳ 1", sometimes
  /// absent), so it stays a display string rather than an int.
  final String semesterLabel;

  /// False when the program marks the course as elective (tự chọn).
  final bool isRequired;

  const ProgramSubject({
    required this.knowledgeBlock,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    required this.semesterLabel,
    required this.isRequired,
  });

  /// Requirement category the portal appends to the block label, e.g.
  /// "Kiến thức ngành (Bắt buộc)" -> "Bắt buộc". Empty when absent.
  String get category => _blockCategory(knowledgeBlock);

  /// The block name with its "(Bắt buộc)" / "(Tự chọn)" suffix stripped, so
  /// the category can be rendered as its own badge instead of inline text.
  String get blockTitle {
    final stripped = knowledgeBlock.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
    return stripped.isEmpty ? knowledgeBlock : stripped;
  }

  static String _blockCategory(String block) {
    final match = RegExp(r'\(([^)]*)\)\s*$').firstMatch(block);
    return match?.group(1)?.trim() ?? '';
  }

  factory ProgramSubject.fromJson(Map<String, dynamic> json) {
    return ProgramSubject(
      knowledgeBlock: json['knowledgeBlock'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      semesterLabel: json['semesterLabel'] as String? ?? '',
      isRequired: json['isRequired'] == true || json['isRequired'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'knowledgeBlock': knowledgeBlock,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'credits': credits,
    'semesterLabel': semesterLabel,
    'isRequired': isRequired,
  };

  /// Flattens the `programsubject/tree` response into a list of courses.
  ///
  /// The portal answers this endpoint in two different shapes depending on the
  /// program, and the earlier version only understood the first:
  ///
  ///  * **Nested** - inner nodes are knowledge blocks and leaves are courses.
  ///  * **Flat** - a plain list where each entry names its own block in a
  ///    field (and may point at a parent by id).
  ///
  /// On the flat shape every entry looks like a leaf with no ancestor, so the
  /// block came out empty for all of them and the Chương trình đào tạo screen
  /// collapsed into a single "Khác" group. Both shapes are handled now.
  static List<ProgramSubject> fromTree(dynamic tree) {
    final root = tree is Map && tree['content'] != null
        ? tree['content']
        : tree;

    // Blocks are also resolvable by id, for flat responses that only carry a
    // parent reference rather than a name.
    final blockNamesById = <String, String>{};
    void indexBlocks(dynamic node) {
      if (node is List) {
        for (final child in node) {
          indexBlocks(child);
        }
        return;
      }
      if (node is! Map) return;
      final map = Map<String, dynamic>.from(node);
      final id = _digString(map, ['id', 'programSubjectId']);
      final name = _digString(map, ['name', 'displayName', 'groupName']);
      final hasCode = _digString(map, [
        'subject.subjectCode',
        'subjectCode',
        'code',
      ]).isNotEmpty;
      // A named node without its own course code is a block heading.
      if (id.isNotEmpty && name.isNotEmpty && !hasCode) {
        blockNamesById[id] = name;
      }
      final children = _dig(map, ['children', 'nodes', 'subNodes', 'items']);
      if (children != null) indexBlocks(children);
    }

    indexBlocks(root);

    final results = <ProgramSubject>[];
    final seen = <String>{};

    void walk(dynamic node, String inheritedBlock) {
      if (node is List) {
        for (final child in node) {
          walk(child, inheritedBlock);
        }
        return;
      }
      if (node is! Map) return;

      final map = Map<String, dynamic>.from(node);

      final name = _digString(map, [
        'subject.subjectName',
        'displaySubjectName',
        'subjectName',
        'name',
        'displayName',
      ]);

      final code = _digString(map, [
        'subject.subjectCode',
        'displaySubjectCode',
        'subjectCode',
        'code',
      ]);

      // The block this entry belongs to, in order of trustworthiness: a name
      // carried on the entry itself, a parent it points at by id, then
      // whatever the enclosing node passed down.
      final ownBlock = _digString(map, [
        // Confirmed against programsubject/tree: the block name lives here.
        'knowledgeProgram.knowledgeBlock.name',
        'knowledgeProgram.displayName',
        'knowledgeBlock.name',
        'knowledgeBlock',
        'subjectGroup.name',
        'programSubjectGroup.name',
        'subjectGroupName',
        'groupName',
        'blockName',
        'parent.name',
        'khoiKienThuc',
      ]);
      final parentId = _digString(map, ['parentId', 'parent.id']);
      final block = ownBlock.isNotEmpty
          ? ownBlock
          : (blockNamesById[parentId] ?? inheritedBlock);

      final children = _dig(map, ['children', 'nodes', 'subNodes', 'items']);
      final hasChildren = children is List && children.isNotEmpty;

      // A node can be both a course and a heading, so recurse first and still
      // fall through to record this entry when it carries a course code.
      if (hasChildren) {
        walk(children, name.isNotEmpty ? name : block);
        if (code.isEmpty) return;
      }

      // Entries with neither a code nor a subject payload are empty groups.
      if (code.isEmpty && name.isEmpty) return;
      if (code.isEmpty && _dig(map, ['subject']) == null) return;

      // The same course can appear under multiple blocks; keep the first.
      final key = '$block|$code|$name';
      if (!seen.add(key)) return;

      final compulsory = _dig(map, [
        'isRequired',
        'required',
        'compulsory',
        'isCompulsory',
      ]);

      // knowledgeProgram.blockType is the portal's own classification:
      //   1 = compulsory, 2 = elective, 3 = certificate-style requirement.
      final blockType = _digInt(map, ['knowledgeProgram.blockType']);

      // Falls back to the label, which some programs write as
      // "Kiến thức tự chọn (Tự chọn)".
      final blockSaysElective =
          _blockCategory(block).toLowerCase().contains('tự chọn') ||
          block.toLowerCase().contains('tự chọn');

      results.add(
        ProgramSubject(
          knowledgeBlock: block,
          subjectCode: code,
          subjectName: name,
          credits:
              _digInt(map, [
                'subject.numberOfCredit',
                'numberOfCredit',
                'credits',
                'credit',
                'soTinChi',
              ]) ??
              0,
          semesterLabel: _digString(map, [
            'semesterIndex',
            'semester.semesterName',
            'semester',
            'semesterName',
            'termNumber',
            'hocKy',
            'studySemester',
          ]),
          isRequired: compulsory != null
              ? (compulsory == true || compulsory == 1)
              : (blockType != null ? blockType != 2 : !blockSaysElective),
        ),
      );
    }

    walk(root, '');
    return results;
  }
}

/// Total credits across [subjects].
int totalProgramCredits(List<ProgramSubject> subjects) =>
    subjects.fold(0, (sum, s) => sum + s.credits);

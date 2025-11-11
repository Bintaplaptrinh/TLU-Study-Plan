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
/// Each period has a type (e.g., "Học kỳ chính", "Chuẩn đầu ra ngoại ngữ")
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
    return StudentExamRoom(
      id: json['id'] ?? 0,
      status: json['status'] ?? 0,
      examCode: json['examCode'],
      examCodeNumber: json['examCodeNumber'],
      markingCode: json['markingCode'],
      examPeriodCode: json['examPeriodCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      studentCode: json['studentCode'],
      examRound: json['examRound'],
      examRoom: json['examRoom'] != null
          ? ExamRoomDetail.fromJson(json['examRoom'])
          : null,
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
    return ExamRoomDetail(
      id: json['id'] ?? 0,
      roomCode: json['roomCode'] ?? '',
      duration: json['duration'],
      examDate: json['examDate'],
      examDateString: json['examDateString'],
      numberExpectedStudent: json['numberExpectedStudent'],
      semesterName: json['semesterName'],
      courseYearName: json['courseYearName'],
      registerPeriodName: json['registerPeriodName'],
      examHour: json['examHour'] != null
          ? ExamHour.fromJson(json['examHour'])
          : null,
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
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
      id: json['id'] ?? 0,
      startString: json['startString'],
      endString: json['endString'],
      name: json['name'],
      code: json['code'],
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

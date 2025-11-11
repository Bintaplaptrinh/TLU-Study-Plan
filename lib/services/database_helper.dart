import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/api_response.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tlu_calendar.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Version 4: Add exam_round_cache_metadata table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add exam-related tables
      await db.execute('''
        CREATE TABLE register_periods (
          id INTEGER PRIMARY KEY,
          semesterId INTEGER NOT NULL,
          name TEXT NOT NULL,
          displayOrder INTEGER NOT NULL,
          lastUpdated INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE exam_rooms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          semesterId INTEGER NOT NULL,
          registerPeriodId INTEGER NOT NULL,
          examRound INTEGER NOT NULL,
          examRoomId INTEGER NOT NULL,
          status INTEGER NOT NULL,
          examCode TEXT,
          examCodeNumber INTEGER,
          markingCode TEXT,
          examPeriodCode TEXT NOT NULL,
          subjectName TEXT NOT NULL,
          studentCode TEXT,
          roomCode TEXT NOT NULL,
          duration INTEGER,
          examDate INTEGER,
          examDateString TEXT,
          numberExpectedStudent INTEGER,
          semesterName TEXT,
          courseYearName TEXT,
          registerPeriodName TEXT,
          examHourJson TEXT,
          roomJson TEXT,
          lastUpdated INTEGER NOT NULL,
          UNIQUE(examRoomId, semesterId, registerPeriodId, examRound)
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add cache progress tracking table
      await db.execute('''
        CREATE TABLE cache_progress (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          isComplete INTEGER NOT NULL DEFAULT 0,
          totalSemesters INTEGER NOT NULL DEFAULT 0,
          cachedSemesters INTEGER NOT NULL DEFAULT 0,
          currentSemesterId INTEGER,
          currentSemesterName TEXT,
          lastUpdated INTEGER NOT NULL
        )
      ''');
      
      // Insert initial row
      await db.insert('cache_progress', {
        'id': 1,
        'isComplete': 0,
        'totalSemesters': 0,
        'cachedSemesters': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    }
    
    if (oldVersion < 4) {
      // Add exam round cache metadata table
      // This tracks which semester+period+round combinations have been cached,
      // even if they returned empty results
      await db.execute('''
        CREATE TABLE exam_round_cache_metadata (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          semesterId INTEGER NOT NULL,
          registerPeriodId INTEGER NOT NULL,
          examRound INTEGER NOT NULL,
          roomCount INTEGER NOT NULL DEFAULT 0,
          lastCached INTEGER NOT NULL,
          UNIQUE(semesterId, registerPeriodId, examRound)
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        displayName TEXT NOT NULL,
        email TEXT NOT NULL,
        personJson TEXT,
        rolesJson TEXT,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Course hours table (Tiết 1-15)
    await db.execute('''
      CREATE TABLE course_hours (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        startString TEXT NOT NULL,
        endString TEXT NOT NULL,
        indexNumber INTEGER NOT NULL,
        type INTEGER,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Semesters table
    await db.execute('''
      CREATE TABLE semesters (
        id INTEGER PRIMARY KEY,
        semesterCode TEXT NOT NULL,
        semesterName TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        isCurrent INTEGER NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Student courses table
    await db.execute('''
      CREATE TABLE student_courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        semesterId INTEGER NOT NULL,
        courseCode TEXT NOT NULL,
        courseName TEXT NOT NULL,
        classCode TEXT,
        className TEXT,
        lecturerJson TEXT,
        dayOfWeek INTEGER NOT NULL,
        startCourseHour INTEGER NOT NULL,
        endCourseHour INTEGER NOT NULL,
        room TEXT NOT NULL,
        building TEXT,
        campus TEXT,
        credits INTEGER NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        fromWeek INTEGER NOT NULL,
        toWeek INTEGER NOT NULL,
        status TEXT NOT NULL,
        grade REAL,
        lastUpdated INTEGER NOT NULL,
        UNIQUE(courseId, semesterId, dayOfWeek, fromWeek, toWeek)
      )
    ''');

    // School years table
    await db.execute('''
      CREATE TABLE school_years (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        year INTEGER NOT NULL,
        current INTEGER NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        displayName TEXT NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Register periods table (for exams)
    await db.execute('''
      CREATE TABLE register_periods (
        id INTEGER PRIMARY KEY,
        semesterId INTEGER NOT NULL,
        name TEXT NOT NULL,
        displayOrder INTEGER NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Exam rooms table
    await db.execute('''
      CREATE TABLE exam_rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semesterId INTEGER NOT NULL,
        registerPeriodId INTEGER NOT NULL,
        examRound INTEGER NOT NULL,
        examRoomId INTEGER NOT NULL,
        status INTEGER NOT NULL,
        examCode TEXT,
        examCodeNumber INTEGER,
        markingCode TEXT,
        examPeriodCode TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        studentCode TEXT,
        roomCode TEXT NOT NULL,
        duration INTEGER,
        examDate INTEGER,
        examDateString TEXT,
        numberExpectedStudent INTEGER,
        semesterName TEXT,
        courseYearName TEXT,
        registerPeriodName TEXT,
        examHourJson TEXT,
        roomJson TEXT,
        lastUpdated INTEGER NOT NULL,
        UNIQUE(examRoomId, semesterId, registerPeriodId, examRound)
      )
    ''');

    // Cache progress tracking table
    await db.execute('''
      CREATE TABLE cache_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        isComplete INTEGER NOT NULL DEFAULT 0,
        totalSemesters INTEGER NOT NULL DEFAULT 0,
        cachedSemesters INTEGER NOT NULL DEFAULT 0,
        currentSemesterId INTEGER,
        currentSemesterName TEXT,
        lastUpdated INTEGER NOT NULL
      )
    ''');
    
    // Insert initial row
    await db.insert('cache_progress', {
      'id': 1,
      'isComplete': 0,
      'totalSemesters': 0,
      'cachedSemesters': 0,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Exam round cache metadata table
    // Tracks which semester+period+round combinations have been cached,
    // even if they returned empty results
    await db.execute('''
      CREATE TABLE exam_round_cache_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semesterId INTEGER NOT NULL,
        registerPeriodId INTEGER NOT NULL,
        examRound INTEGER NOT NULL,
        roomCount INTEGER NOT NULL DEFAULT 0,
        lastCached INTEGER NOT NULL,
        UNIQUE(semesterId, registerPeriodId, examRound)
      )
    ''');
  }

  // Save TLU user
  Future<void> saveTluUser(TluUser user) async {
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'displayName': user.displayName,
      'email': user.email,
      'personJson': user.person != null
          ? jsonEncode(_personToMap(user.person!))
          : null,
      'rolesJson': jsonEncode(
        user.roles
            .map((r) => {'id': r.id, 'name': r.name, 'authority': r.authority})
            .toList(),
      ),
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Map<String, dynamic> _personToMap(Person person) {
    return {
      'id': person.id,
      'firstName': person.firstName,
      'lastName': person.lastName,
      'displayName': person.displayName,
      'birthDateString': person.birthDateString,
      'birthPlace': person.birthPlace,
      'gender': person.gender,
      'phoneNumber': person.phoneNumber,
      'idNumber': person.idNumber,
      'email': person.email,
    };
  }

  // Get TLU user
  Future<TluUser?> getTluUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);

    if (maps.isEmpty) return null;

    final map = maps.first;
    return TluUser(
      id: map['id'] as int,
      username: map['username'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      active: true,
      person: map['personJson'] != null
          ? _mapToPerson(jsonDecode(map['personJson'] as String))
          : null,
      roles: (jsonDecode(map['rolesJson'] as String) as List)
          .map(
            (r) => UserRole(
              id: r['id'],
              name: r['name'],
              authority: r['authority'],
            ),
          )
          .toList(),
    );
  }

  Person _mapToPerson(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      displayName: map['displayName'] ?? '',
      birthDateString: map['birthDateString'],
      birthPlace: map['birthPlace'] ?? '',
      gender: map['gender'] ?? 'M',
      phoneNumber: map['phoneNumber'] ?? '',
      idNumber: map['idNumber'] ?? '',
      email: map['email'] ?? '',
      address: [],
    );
  }

  // Save course hours
  Future<void> saveCourseHours(Map<int, CourseHour> courseHours) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var hour in courseHours.values) {
      batch.insert('course_hours', {
        'id': hour.id,
        'name': hour.name,
        'startString': hour.startString,
        'endString': hour.endString,
        'indexNumber': hour.indexNumber,
        'type': hour.type,
        'lastUpdated': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // Get course hours
  Future<Map<int, CourseHour>> getCourseHours() async {
    final db = await database;
    final maps = await db.query('course_hours');

    final courseHours = <int, CourseHour>{};
    for (var map in maps) {
      final hour = CourseHour(
        id: map['id'] as int,
        name: map['name'] as String,
        start: 0,
        startString: map['startString'] as String,
        end: 0,
        endString: map['endString'] as String,
        indexNumber: map['indexNumber'] as int,
        type: (map['type'] as int?) ?? 0,
      );
      courseHours[hour.id] = hour;
    }

    return courseHours;
  }

  // Save semesters
  Future<void> saveSemesters(List<Semester> semesters) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var semester in semesters) {
      batch.insert('semesters', {
        'id': semester.id,
        'semesterCode': semester.semesterCode,
        'semesterName': semester.semesterName,
        'startDate': semester.startDate,
        'endDate': semester.endDate,
        'isCurrent': semester.isCurrent ? 1 : 0,
        'lastUpdated': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // Get semesters
  Future<List<Semester>> getSemesters() async {
    final db = await database;
    final maps = await db.query('semesters', orderBy: 'startDate DESC');

    return maps
        .map(
          (map) => Semester(
            id: map['id'] as int,
            semesterCode: map['semesterCode'] as String,
            semesterName: map['semesterName'] as String,
            startDate: map['startDate'] as int,
            endDate: map['endDate'] as int,
            isCurrent: (map['isCurrent'] as int) == 1,
            semesterRegisterPeriods: [],
          ),
        )
        .toList();
  }

  // Save student courses
  Future<void> saveStudentCourses(
    int semesterId,
    List<StudentCourseSubject> courses,
  ) async {
    final db = await database;

    // Delete old courses for this semester
    await db.delete(
      'student_courses',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
    );

    // Insert new courses
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var course in courses) {
      batch.insert('student_courses', {
        'courseId': course.id,
        'semesterId': semesterId,
        'courseCode': course.courseCode,
        'courseName': course.courseName,
        'classCode': course.classCode,
        'className': course.className,
        'lecturerJson': course.lecturer != null
            ? jsonEncode({
                'id': course.lecturer!.id,
                'name': course.lecturer!.name,
                'email': course.lecturer!.email,
              })
            : null,
        'dayOfWeek': course.dayOfWeek,
        'startCourseHour': course.startCourseHour,
        'endCourseHour': course.endCourseHour,
        'room': course.room,
        'building': course.building,
        'campus': course.campus,
        'credits': course.credits,
        'startDate': course.startDate,
        'endDate': course.endDate,
        'fromWeek': course.fromWeek,
        'toWeek': course.toWeek,
        'status': course.status,
        'grade': course.grade,
        'lastUpdated': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // Get student courses for a semester
  Future<List<StudentCourseSubject>> getStudentCourses(int semesterId) async {
    final db = await database;
    final maps = await db.query(
      'student_courses',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
      orderBy: 'dayOfWeek, startCourseHour',
    );

    return maps.map((map) {
      LecturerInfo? lecturer;
      if (map['lecturerJson'] != null) {
        final lecturerMap = jsonDecode(map['lecturerJson'] as String);
        lecturer = LecturerInfo(
          id: lecturerMap['id'],
          name: lecturerMap['name'],
          email: lecturerMap['email'],
        );
      }

      return StudentCourseSubject(
        id: map['courseId'] as int,
        courseCode: map['courseCode'] as String,
        courseName: map['courseName'] as String,
        classCode: map['classCode'] as String? ?? '',
        className: map['className'] as String? ?? '',
        lecturer: lecturer,
        dayOfWeek: map['dayOfWeek'] as int,
        startCourseHour: map['startCourseHour'] as int,
        endCourseHour: map['endCourseHour'] as int,
        room: map['room'] as String,
        building: map['building'] as String? ?? '',
        campus: map['campus'] as String? ?? '',
        credits: map['credits'] as int,
        startDate: map['startDate'] as int,
        endDate: map['endDate'] as int,
        fromWeek: map['fromWeek'] as int,
        toWeek: map['toWeek'] as int,
        status: map['status'] as String,
        grade: map['grade'] as double?,
      );
    }).toList();
  }

  // Save school years
  Future<void> saveSchoolYears(List<SchoolYear> schoolYears) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var year in schoolYears) {
      batch.insert('school_years', {
        'id': year.id,
        'name': year.name,
        'code': year.code,
        'year': year.year,
        'current': year.current ? 1 : 0,
        'startDate': year.startDate,
        'endDate': year.endDate,
        'displayName': year.displayName,
        'lastUpdated': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // Get school years
  Future<List<SchoolYear>> getSchoolYears() async {
    final db = await database;
    final maps = await db.query('school_years', orderBy: 'year DESC');

    return maps
        .map(
          (map) => SchoolYear(
            id: map['id'] as int,
            name: map['name'] as String,
            code: map['code'] as String,
            year: map['year'] as int,
            current: (map['current'] as int) == 1,
            startDate: map['startDate'] as int,
            endDate: map['endDate'] as int,
            displayName: map['displayName'] as String,
            semesters: [],
          ),
        )
        .toList();
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('course_hours');
    await db.delete('semesters');
    await db.delete('student_courses');
    await db.delete('school_years');
    await db.delete('register_periods');
    await db.delete('exam_rooms');
  }

  // Save register periods for a semester
  Future<void> saveRegisterPeriods(
    int semesterId,
    List<RegisterPeriod> periods,
  ) async {
    final db = await database;

    // Delete old periods for this semester
    await db.delete(
      'register_periods',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
    );

    // Insert new periods
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var period in periods) {
      batch.insert('register_periods', {
        'id': period.id,
        'semesterId': semesterId,
        'name': period.name,
        'displayOrder': period.displayOrder,
        'lastUpdated': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // Get register periods for a semester
  Future<List<RegisterPeriod>> getRegisterPeriods(int semesterId) async {
    final db = await database;
    final maps = await db.query(
      'register_periods',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
      orderBy: 'displayOrder',
    );

    // Get the semester for the register periods
    final semesterMaps = await db.query(
      'semesters',
      where: 'id = ?',
      whereArgs: [semesterId],
      limit: 1,
    );

    Semester semester;
    if (semesterMaps.isNotEmpty) {
      final semMap = semesterMaps.first;
      semester = Semester(
        id: semMap['id'] as int,
        semesterCode: semMap['semesterCode'] as String,
        semesterName: semMap['semesterName'] as String,
        startDate: semMap['startDate'] as int,
        endDate: semMap['endDate'] as int,
        isCurrent: (semMap['isCurrent'] as int) == 1,
        semesterRegisterPeriods: [],
      );
    } else {
      // Fallback semester if not found
      semester = Semester(
        id: semesterId,
        semesterCode: '',
        semesterName: '',
        startDate: 0,
        endDate: 0,
        isCurrent: false,
        semesterRegisterPeriods: [],
      );
    }

    return maps
        .map(
          (map) => RegisterPeriod(
            id: map['id'] as int,
            voided: false,
            semester: semester,
            name: map['name'] as String,
            displayOrder: map['displayOrder'] as int,
            examPeriods: [],
          ),
        )
        .toList();
  }

  // Save exam rooms
  Future<void> saveExamRooms(
    int semesterId,
    int registerPeriodId,
    int examRound,
    List<StudentExamRoom> examRooms,
  ) async {
    final db = await database;

    // Delete old exam rooms for this combination
    await db.delete(
      'exam_rooms',
      where: 'semesterId = ? AND registerPeriodId = ? AND examRound = ?',
      whereArgs: [semesterId, registerPeriodId, examRound],
    );

    // Insert new exam rooms
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var examRoom in examRooms) {
      batch.insert('exam_rooms', {
        'examRoomId': examRoom.id,
        'semesterId': semesterId,
        'registerPeriodId': registerPeriodId,
        'examRound': examRound,
        'status': examRoom.status,
        'examCode': examRoom.examCode,
        'examCodeNumber': examRoom.examCodeNumber,
        'markingCode': examRoom.markingCode,
        'examPeriodCode': examRoom.examPeriodCode,
        'subjectName': examRoom.subjectName,
        'studentCode': examRoom.studentCode,
        'roomCode': examRoom.examRoom?.roomCode ?? '',
        'duration': examRoom.examRoom?.duration,
        'examDate': examRoom.examRoom?.examDate,
        'examDateString': examRoom.examRoom?.examDateString,
        'numberExpectedStudent': examRoom.examRoom?.numberExpectedStudent,
        'semesterName': examRoom.examRoom?.semesterName,
        'courseYearName': examRoom.examRoom?.courseYearName,
        'registerPeriodName': examRoom.examRoom?.registerPeriodName,
        'examHourJson': examRoom.examRoom?.examHour != null
            ? jsonEncode({
                'id': examRoom.examRoom!.examHour!.id,
                'startString': examRoom.examRoom!.examHour!.startString,
                'endString': examRoom.examRoom!.examHour!.endString,
                'name': examRoom.examRoom!.examHour!.name,
                'code': examRoom.examRoom!.examHour!.code,
              })
            : null,
        'roomJson': examRoom.examRoom?.room != null
            ? jsonEncode({
                'id': examRoom.examRoom!.room!.id,
                'name': examRoom.examRoom!.room!.name,
                'code': examRoom.examRoom!.room!.code,
              })
            : null,
        'lastUpdated': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    
    // ✅ CRITICAL: Save metadata to track that this round has been cached,
    // even if it returned zero rooms
    await db.insert(
      'exam_round_cache_metadata',
      {
        'semesterId': semesterId,
        'registerPeriodId': registerPeriodId,
        'examRound': examRound,
        'roomCount': examRooms.length,
        'lastCached': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get exam rooms
  Future<List<StudentExamRoom>> getExamRooms(
    int semesterId,
    int registerPeriodId,
    int examRound,
  ) async {
    final db = await database;
    final maps = await db.query(
      'exam_rooms',
      where: 'semesterId = ? AND registerPeriodId = ? AND examRound = ?',
      whereArgs: [semesterId, registerPeriodId, examRound],
      orderBy: 'examDate, examDateString',
    );

    return maps.map((map) {
      ExamHour? examHour;
      if (map['examHourJson'] != null) {
        final hourMap = jsonDecode(map['examHourJson'] as String);
        examHour = ExamHour(
          id: hourMap['id'],
          startString: hourMap['startString'],
          endString: hourMap['endString'],
          name: hourMap['name'],
          code: hourMap['code'],
        );
      }

      Room? room;
      if (map['roomJson'] != null) {
        final roomMap = jsonDecode(map['roomJson'] as String);
        room = Room(
          id: roomMap['id'],
          name: roomMap['name'],
          code: roomMap['code'],
        );
      }

      ExamRoomDetail? examRoomDetail;
      if (map['roomCode'] != null && (map['roomCode'] as String).isNotEmpty) {
        examRoomDetail = ExamRoomDetail(
          id: 0,
          roomCode: map['roomCode'] as String,
          duration: map['duration'] as int?,
          examDate: map['examDate'] as int?,
          examDateString: map['examDateString'] as String?,
          numberExpectedStudent: map['numberExpectedStudent'] as int?,
          semesterName: map['semesterName'] as String?,
          courseYearName: map['courseYearName'] as String?,
          registerPeriodName: map['registerPeriodName'] as String?,
          examHour: examHour,
          room: room,
        );
      }

      return StudentExamRoom(
        id: map['examRoomId'] as int,
        status: map['status'] as int,
        examCode: map['examCode'] as String?,
        examCodeNumber: map['examCodeNumber'] as int?,
        markingCode: map['markingCode'] as String?,
        examPeriodCode: map['examPeriodCode'] as String,
        subjectName: map['subjectName'] as String,
        studentCode: map['studentCode'] as String?,
        examRound: examRound,
        examRoom: examRoomDetail,
      );
    }).toList();
  }

  // Check if cached exam data exists
  // ✅ NOW CHECKS METADATA TABLE - returns true even for empty rounds
  Future<bool> hasExamRoomCache(
    int semesterId,
    int registerPeriodId,
    int examRound,
  ) async {
    final db = await database;
    final result = await db.query(
      'exam_round_cache_metadata',
      where: 'semesterId = ? AND registerPeriodId = ? AND examRound = ?',
      whereArgs: [semesterId, registerPeriodId, examRound],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Check if cached register periods exist
  Future<bool> hasRegisterPeriodsCache(int semesterId) async {
    final db = await database;
    final result = await db.query(
      'register_periods',
      where: 'semesterId = ?',
      whereArgs: [semesterId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ==================== CACHE PROGRESS TRACKING ====================
  
  /// Get current cache progress status
  Future<Map<String, dynamic>> getCacheProgress() async {
    final db = await database;
    final result = await db.query('cache_progress', where: 'id = 1');
    
    if (result.isEmpty) {
      // Initialize if not exists
      await db.insert('cache_progress', {
        'id': 1,
        'isComplete': 0,
        'totalSemesters': 0,
        'cachedSemesters': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return {
        'isComplete': 0,
        'totalSemesters': 0,
        'cachedSemesters': 0,
        'currentSemesterId': null,
        'currentSemesterName': null,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
    }
    
    return result.first;
  }
  
  /// Update cache progress
  Future<void> updateCacheProgress({
    required int totalSemesters,
    required int cachedSemesters,
    required bool isComplete,
    int? currentSemesterId,
    String? currentSemesterName,
  }) async {
    final db = await database;
    await db.update(
      'cache_progress',
      {
        'isComplete': isComplete ? 1 : 0,
        'totalSemesters': totalSemesters,
        'cachedSemesters': cachedSemesters,
        'currentSemesterId': currentSemesterId,
        'currentSemesterName': currentSemesterName,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );
  }
  
  /// Reset cache progress (for resuming after app closure)
  Future<void> resetCacheProgress() async {
    final db = await database;
    await db.update(
      'cache_progress',
      {
        'isComplete': 0,
        'totalSemesters': 0,
        'cachedSemesters': 0,
        'currentSemesterId': null,
        'currentSemesterName': null,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );
  }
  
  /// Check if caching is complete
  Future<bool> isCacheComplete() async {
    final progress = await getCacheProgress();
    return progress['isComplete'] == 1;
  }
  
  /// Get list of semesters that have been cached
  Future<List<int>> getCachedSemesterIds() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT semesterId 
      FROM register_periods 
      ORDER BY semesterId DESC
    ''');
    return result.map((row) => row['semesterId'] as int).toList();
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

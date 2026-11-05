import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/models/weather_info.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/services/auth_service.dart';
import 'package:tlustudy_planner/services/database_helper.dart';
import 'package:tlustudy_planner/services/notice_service.dart';
import 'package:tlustudy_planner/utils/schedule_time.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';

StudentExamRoom exam({
  int id = 1,
  String? date = '05/11/2026',
  String? start = '08:00',
  String? end,
  int? duration = 90,
}) => StudentExamRoom(
  id: id,
  status: 1,
  examPeriodCode: 'HK1',
  subjectName: 'Toán',
  examRoom: ExamRoomDetail(
    id: id,
    roomCode: 'A101',
    examDateString: date,
    duration: duration,
    examHour: ExamHour(id: 1, startString: start, endString: end),
  ),
);

class MemoryExamCache implements DatabaseHelper {
  List<StudentExamRoom> exams = [];
  final filters = <String, List<StudentExamRoom>>{};
  Completer<List<StudentExamRoom>>? pending;
  @override
  Future<List<StudentExamRoom>> getTimetableExams() async => pending == null
      ? [...exams, ...filters.values.expand((items) => items)]
      : pending!.future;
  @override
  Future<List<RegisterPeriod>> getRegisterPeriods(int semesterId) async => [
    RegisterPeriod.fromJson({'id': 1}),
    RegisterPeriod.fromJson({'id': 2}),
  ];
  @override
  Future<void> saveRegisterPeriods(
    int semesterId,
    List<RegisterPeriod> periods,
  ) async {}
  @override
  Future<void> saveExamRooms(
    int semesterId,
    int periodId,
    int round,
    List<StudentExamRoom> rooms,
  ) async {
    filters['$semesterId:$periodId:$round'] = rooms;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TimetableApi extends AuthService {
  final calls = <String>{};
  @override
  Future<List<RegisterPeriod>> getRegisterPeriods(
    String token,
    int semesterId,
  ) => MemoryExamCache().getRegisterPeriods(semesterId);
  @override
  Future<List<StudentExamRoom>> getStudentExamRooms(
    String token,
    int semesterId,
    int periodId,
    int round,
  ) async {
    calls.add('$periodId:$round');
    return periodId == 1 && round == 1
        ? [exam()]
        : periodId == 2 && round == 5
        ? [exam(id: 2, start: '14:00')]
        : [];
  }
}

void main() {
  test(
    'calendar refresh collects every exam filter without changing the Exams tab',
    () async {
      final cache = MemoryExamCache();
      final api = TimetableApi();
      final provider = ExamProvider(database: cache, authService: api);
      await provider.loadTimetable('test-token', 1);
      expect(api.calls, hasLength(10));
      expect(provider.timetableExams, hasLength(2));
      expect(provider.examRooms, isEmpty);
      expect(provider.selectedRegisterPeriodId, isNull);
      expect(provider.isLoadingTimetable, isFalse);
      provider.dispose();
    },
  );
  test(
    'WeatherAPI uses metric units, numeric conditions, and server day/night',
    () {
      final info = WeatherInfo.fromWeatherApi({
        'location': {'name': 'Ho Chi Minh City'},
        'current': {
          'condition': {'code': 1276, 'text': 'Mưa có sấm sét'},
          'temp_c': 29.5,
          'feelslike_c': 32,
          'humidity': 80,
          'wind_kph': 18,
          'last_updated_epoch': 1793836800,
          'is_day': 0,
        },
      });
      expect(info.temperature, 29.5);
      expect(info.windSpeed, 5); // Existing card displays m/s, not km/h.
      expect(info.visual, WeatherVisual.thunder);
      expect(info.description, 'Mưa có sấm sét');
      expect(info.isNight, isTrue);
    },
  );

  test('exams merge chronologically and duplicate portal rows appear once', () {
    final later = exam(id: 2, start: '14:00');
    final slots = timetableOn([], [
      later,
      exam(),
      exam(),
      exam(date: '06/11/2026'),
    ], DateTime(2026, 11, 5));
    expect(slots, hasLength(2));
    expect(slots.first.startLabel, '08:00');
    expect(slots.first.endLabel, '09:30');
    expect(slots.first.isExam, isTrue);
    expect(
      slots.first.stateAt(DateTime(2026, 11, 5, 8, 30)),
      ClassState.current,
    );
  });

  test('missing times never claim an exam is currently in progress', () {
    final slot = ClassSlot.fromExam(exam(start: null));
    expect(slot!.startLabel, 'Chưa có');
    expect(slot.stateAt(DateTime(2026, 11, 5, 12)), ClassState.upcoming);
    expect(ClassSlot.fromExam(exam(date: null)), isNull);
    expect(ClassSlot.fromExam(exam(date: '31/02/2026')), isNull);
  });

  test(
    'cached exam timetable loads without visiting Exams or having a token',
    () async {
      final cache = MemoryExamCache()..exams = [exam()];
      final provider = ExamProvider(
        database: cache,
        authService: AuthService(),
      );
      await provider.loadTimetable(null, 1);
      expect(provider.timetableExams, hasLength(1));
      expect(provider.selectedRegisterPeriodId, isNull);
      provider.clear();
      expect(provider.timetableExams, isEmpty);
      provider.dispose();
    },
  );

  test(
    'logout prevents an in-flight cache read from restoring another session',
    () async {
      final cache = MemoryExamCache()
        ..pending = Completer<List<StudentExamRoom>>();
      final provider = ExamProvider(database: cache);
      final load = provider.loadTimetable(null, 1);
      provider.clear();
      cache.pending!.complete([exam()]);
      await load;
      expect(provider.timetableExams, isEmpty);
      expect(provider.isLoadingTimetable, isFalse);
      provider.dispose();
    },
  );

  const sourceHtml = '''
    <a href="/navigation">Menu</a>
    <h2 class="post-title is-large"><a href="/hoc-phi-7108">Học phí &amp; lịch thi</a></h2>
    <h3 class="post-title"><a href="/hoc-phi-7108">Duplicate</a></h3>
    <h3 class="post-title"><a href="javascript:alert(1)">Bad</a></h3>
    <a class="next page-numbers" href="/tin-tuc-thong-bao/thong-bao/page/2">Next</a>
  ''';

  test(
    'school notice parser decodes titles and resolves only school article URLs',
    () {
      final page = NoticeService.parsePage(sourceHtml);
      expect(page.items.single.title, 'Học phí & lịch thi');
      expect(
        page.items.single.url.toString(),
        'https://tlus.edu.vn/hoc-phi-7108',
      );
      expect(page.hasNext, isTrue);
      expect(
        () => NoticeService.parsePage('<html>Maintenance</html>'),
        throwsFormatException,
      );
    },
  );

  test(
    'notice fetch requests the selected category page and handles HTTP errors',
    () async {
      final service = NoticeService(
        MockClient((request) async {
          expect(request.url.toString(), '${NoticeService.source}/page/2');
          return http.Response(
            sourceHtml,
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      expect((await service.fetchPage(2)).items, hasLength(1));
      service.close();
      final failed = NoticeService(
        MockClient((_) async => http.Response('', 503)),
      );
      await expectLater(failed.fetchPage(), throwsException);
      failed.close();
    },
  );
}

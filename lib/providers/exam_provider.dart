import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/services/auth_service.dart';
import 'package:tlustudy_planner/services/database_helper.dart';
import 'package:tlustudy_planner/services/log_service.dart';
import 'package:tlustudy_planner/utils/notification_helper.dart';
class ExamProvider with ChangeNotifier {
  List<RegisterPeriod> _registerPeriods = [];
  List<Semester> _availableSemesters = [];
  List<StudentExamRoom> _examRooms = [];
  ExamProvider({AuthService? authService, DatabaseHelper? database})
    : _authService = authService ?? AuthService(),
      _dbHelper = database ?? DatabaseHelper.instance;

  final AuthService _authService;
  final DatabaseHelper _dbHelper;
  final _log = LogService();

  List<StudentExamRoom> _timetableExams = [];
  List<StudentExamRoom> get timetableExams =>
      List.unmodifiable(_timetableExams);
  bool _isLoadingTimetable = false;
  bool get isLoadingTimetable => _isLoadingTimetable;
  int _timetableGeneration = 0;
  int? _timetableSemester;
  Future<void>? _timetableRequest;

  /// Read cached exams immediately; refresh every period and round for this semester.
  Future<void> loadTimetable(
    String? token,
    int semesterId, {
    bool force = false,
  }) {
    if (!force &&
        _timetableSemester == semesterId &&
        _timetableRequest != null) {
      return _timetableRequest!;
    }
    _timetableSemester = semesterId;
    final generation = ++_timetableGeneration;
    return _timetableRequest = _loadTimetable(token, semesterId, generation);
  }

  Future<void> _reloadTimetableCache(int generation) async {
    final exams = await _dbHelper.getTimetableExams();
    if (generation != _timetableGeneration) return;
    _timetableExams = exams;
    notifyListeners();
  }

  Future<void> _loadTimetable(
    String? token,
    int semesterId,
    int generation,
  ) async {
    _isLoadingTimetable = true;
    notifyListeners();
    try {
      await _reloadTimetableCache(generation);
      if (token == null || token.isEmpty || generation != _timetableGeneration)
        return;
      var periods = await _dbHelper.getRegisterPeriods(semesterId);
      try {
        periods = await _authService.getRegisterPeriods(token, semesterId);
        if (generation != _timetableGeneration) return;
        await _dbHelper.saveRegisterPeriods(semesterId, periods);
      } catch (_) {
        /* Keep the cached periods when offline. */
      }
      final tasks = <Future<void> Function()>[
        for (final period in periods)
          for (final round in _examRounds)
            () async {
              if (generation != _timetableGeneration) return;
              try {
                final rooms = await _authService.getStudentExamRooms(
                  token,
                  semesterId,
                  period.id,
                  round,
                );
                if (generation != _timetableGeneration) return;
                await _dbHelper.saveExamRooms(
                  semesterId,
                  period.id,
                  round,
                  rooms,
                );
              } catch (_) {
                /* Keep this filter's cached exams. */
              }
            },
      ];
      await _runPool(tasks);
      await _reloadTimetableCache(generation);
    } catch (e) {
      _log.log('Timetable exam refresh failed: $e', level: LogLevel.warning);
    } finally {
      if (generation == _timetableGeneration) {
        _isLoadingTimetable = false;
        notifyListeners();
      }
    }
  }

  bool _isLoading = false;
  bool _isLoadingSemesters = false;
  bool _isLoadingRooms = false;
  String? _errorMessage;
  String? _roomErrorMessage;

  /// How many exam-room requests may be in flight at once during pre-caching.
  /// These are pure network waits, so a wide pool cuts the sweep from tens of
  /// minutes down to a couple.
  static const int _maxConcurrentRequests = 16;

  /// Exam rounds the portal exposes in its "số lần thi" dropdown.
  static const List<int> _examRounds = <int>[1, 2, 3, 4, 5];

  // Pre-caching progress tracking
  bool _isPreCaching = false;
  int _preCacheProgress = 0; // 0-100 percentage
  String _preCacheStatus = '';
  int _preCacheTotalSemesters = 0;
  int _preCacheCurrentSemester = 0;
  int _preCacheTotalPeriods = 0;
  int _preCacheCurrentPeriod = 0;

  // Selected filters
  int? _selectedRegisterPeriodId;
  int? _selectedSemesterId;
  int _selectedExamRound = 1; // Default to round 1

  List<RegisterPeriod> get registerPeriods => _registerPeriods;
  List<Semester> get availableSemesters => _availableSemesters;
  List<StudentExamRoom> get examRooms => _examRooms;
  bool get isLoading => _isLoading;
  bool get isLoadingSemesters => _isLoadingSemesters;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get errorMessage => _errorMessage;
  String? get roomErrorMessage => _roomErrorMessage;
  int? get selectedRegisterPeriodId => _selectedRegisterPeriodId;
  int? get selectedSemesterId => _selectedSemesterId;
  int get selectedExamRound => _selectedExamRound;

  // Pre-caching progress getters
  bool get isPreCaching => _isPreCaching;
  int get preCacheProgress => _preCacheProgress;
  String get preCacheStatus => _preCacheStatus;
  int get preCacheTotalSemesters => _preCacheTotalSemesters;
  int get preCacheCurrentSemester => _preCacheCurrentSemester;
  int get preCacheTotalPeriods => _preCacheTotalPeriods;
  int get preCacheCurrentPeriod => _preCacheCurrentPeriod;

  /// Get the currently selected register period
  RegisterPeriod? get selectedRegisterPeriod {
    if (_selectedRegisterPeriodId == null) return null;
    try {
      return _registerPeriods.firstWhere(
        (period) => period.id == _selectedRegisterPeriodId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the currently selected semester
  Semester? get selectedSemester {
    if (_selectedSemesterId == null) return null;
    try {
      return _availableSemesters.firstWhere(
        (semester) => semester.id == _selectedSemesterId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if register periods cache exists for a semester
  Future<bool> hasRegisterPeriodsCache(int semesterId) async {
    return await _dbHelper.hasRegisterPeriodsCache(semesterId);
  }

  /// Select semester from cache only (no API call)
  Future<void> selectSemesterFromCache(int semesterId) async {
    _selectedSemesterId = semesterId;
    _selectedRegisterPeriodId = null;
    _examRooms = [];
    _selectedExamRound = 1;
    notifyListeners();

    // Load register periods from cache
    _isLoading = true;
    notifyListeners();

    try {
      _registerPeriods = await _dbHelper.getRegisterPeriods(semesterId);
      _registerPeriods.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      // Auto-select the first period if available
      if (_registerPeriods.isNotEmpty) {
        _selectedRegisterPeriodId = _registerPeriods.first.id;
        
        // Try to load exam rooms for the first period from cache
        final hasExamCache = await _dbHelper.hasExamRoomCache(
          semesterId,
          _registerPeriods.first.id,
          1,
        );
        
        if (hasExamCache) {
          _examRooms = await _dbHelper.getExamRooms(
            semesterId,
            _registerPeriods.first.id,
            1,
          );
          
          // Schedule notifications for cached exam data
          await _scheduleExamNotifications();
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all available semesters
  Future<void> fetchAvailableSemesters(String? accessToken) async {
    _isLoadingSemesters = true;
    notifyListeners();

    try {
      // Try to load from cache first
      final cachedSemesters = await _dbHelper.getSemesters();
      
      if (cachedSemesters.isNotEmpty) {
        _availableSemesters = cachedSemesters;
        
        // Sort by ordinalNumbers descending (newest first)
        _availableSemesters.sort(
          (a, b) => (b.ordinalNumbers ?? 0).compareTo(a.ordinalNumbers ?? 0),
        );
        
        _isLoadingSemesters = false;
        notifyListeners();
        
        _log.log('fetchAvailableSemesters: Loaded ${_availableSemesters.length} semesters from cache', level: LogLevel.debug);
        
        // Fetch fresh data in background ONLY if we have valid access token
        if (accessToken != null && accessToken.isNotEmpty) {
          _log.log('fetchAvailableSemesters: Starting background refresh', level: LogLevel.debug);
          _fetchAvailableSemestersFromApi(accessToken);
        }
        return;
      }
      
      // No cache, try to fetch from API if we have access token
      _log.log('fetchAvailableSemesters: No cache, trying API', level: LogLevel.debug);
      if (accessToken != null && accessToken.isNotEmpty) {
        await _fetchAvailableSemestersFromApi(accessToken);
      } else {
        // No cache and no token - can't do anything
        _isLoadingSemesters = false;
        notifyListeners();
      }
    } catch (e) {
      _log.log('fetchAvailableSemesters ERROR: $e', level: LogLevel.error);
      _isLoadingSemesters = false;
      notifyListeners();
    }
  }
  
  /// Fetch semesters from API (internal method)
  Future<void> _fetchAvailableSemestersFromApi(String accessToken) async {
    try {
      final response = await _authService.getAllSemesters(accessToken);
      _availableSemesters = response.content;

      // Sort by ordinalNumbers descending (newest first)
      _availableSemesters.sort(
        (a, b) => (b.ordinalNumbers ?? 0).compareTo(a.ordinalNumbers ?? 0),
      );
      
      // Save to cache
      await _dbHelper.saveSemesters(_availableSemesters);

      // Only notify if this is not a background refresh
      if (_isLoadingSemesters) {
        _isLoadingSemesters = false;
        notifyListeners();
      }
      
      _log.log('_fetchAvailableSemestersFromApi: Saved ${_availableSemesters.length} semesters to cache', level: LogLevel.debug);
    } catch (e) {
      // Check if this is a 401 error (token expired) - completely silent
      final is401Error = e.toString().contains('401');
      
      // Check if we have cached data
      if (_availableSemesters.isEmpty) {
        // Initial fetch failed, show error
        _log.log('Failed to load available semesters: $e', level: LogLevel.error);
      } else if (!is401Error) {
        // Only log non-auth errors for background refresh
        _log.log('Background semesters refresh failed: $e', level: LogLevel.warning);
      }
      // If it's 401 and we have cached data, completely silent (expected offline behavior)
    }
  }

  /// Select a semester and fetch its exam schedule
  Future<void> selectSemester(String? accessToken, int semesterId) async {
    _selectedSemesterId = semesterId;
    _selectedRegisterPeriodId = null; // Reset register period selection
    _examRooms = []; // Clear exam rooms when semester changes
    _selectedExamRound = 1; // Reset exam round to 1
    _isLoading = true; // Show loading state immediately
    notifyListeners();

    await fetchExamSchedule(accessToken, semesterId);
    
    // After fetching register periods, pre-cache all exam rounds for offline use
    if (_selectedRegisterPeriodId != null && _selectedSemesterId != null && accessToken != null) {
      _log.log('selectSemester: Pre-caching all exam rounds for offline use', level: LogLevel.debug);
      
      // Fetch exam rooms for the selected round (will be displayed)
      await fetchExamRoomDetails(
        accessToken,
        _selectedSemesterId!,
        _selectedRegisterPeriodId!,
        _selectedExamRound,
      );
      
      // Pre-cache other rounds in background (silently, don't block UI)
      _preCacheExamRounds(
        accessToken,
        _selectedSemesterId!,
        _selectedRegisterPeriodId!,
        _selectedExamRound,
      );
    }
  }

  /// Check if there's incomplete cache (for showing resume button)
  Future<bool> checkIncompletCache() async {
    try {
      final isComplete = await _dbHelper.isCacheComplete();
      final cachedSemesters = await _dbHelper.getCachedSemesterIds();
      // Incomplete if not marked complete AND has some cached data
      return !isComplete && cachedSemesters.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Pre-cache every exam schedule the student can see, for full offline use.
  ///
  /// Every (semester x register period x exam round) combination is flattened
  /// into a single task queue and drained by a fixed pool of workers. That
  /// keeps a constant number of requests in flight instead of stalling on the
  /// slowest semester in a batch, and lets progress be reported against real
  /// work done rather than semester count.
  ///
  /// Semesters are processed newest-first so the data the student actually
  /// wants lands early, and already-cached semesters are skipped so an
  /// interrupted run resumes where it left off.
  Future<void> preCacheAllExamData(String accessToken, int currentSemesterId) async {
    _isPreCaching = true;
    _preCacheProgress = 0;
    _preCacheStatus = 'Bắt đầu tải dữ liệu offline...';
    notifyListeners();

    _log.log('Exhaustive exam caching started (pool of $_maxConcurrentRequests)',
        level: LogLevel.info);
    _log.log('Current semester ID: $currentSemesterId', level: LogLevel.debug);

    try {
      await _reloadTimetableCache(_timetableGeneration);
      if (await _dbHelper.isCacheComplete()) {
        _log.log('Cache already complete - nothing to do', level: LogLevel.success);
        _isPreCaching = false;
        _preCacheProgress = 100;
        _preCacheStatus = 'Dữ liệu đã được tải đầy đủ';
        notifyListeners();
        return;
      }

      // ---- Step 1: every semester -----------------------------------------
      _preCacheStatus = 'Đang lấy danh sách học kỳ...';
      notifyListeners();

      final allSemesters = await _authService.getAllSemesters(accessToken);
      _preCacheTotalSemesters = allSemesters.content.length;
      await _dbHelper.saveSemesters(allSemesters.content);
      _log.log('Found $_preCacheTotalSemesters semesters', level: LogLevel.success);

      final cachedSemesterIds = await _dbHelper.getCachedSemesterIds();
      final semestersToCache = allSemesters.content
          .where((sem) => !cachedSemesterIds.contains(sem.id))
          .toList()
        // Newest first: the current semester matters more than 2019's.
        ..sort((a, b) {
          if (a.id == currentSemesterId) return -1;
          if (b.id == currentSemesterId) return 1;
          return b.startDate.compareTo(a.startDate);
        });

      if (semestersToCache.isEmpty) {
        _log.log('All semesters already cached', level: LogLevel.success);
        await _dbHelper.updateCacheProgress(
          totalSemesters: _preCacheTotalSemesters,
          cachedSemesters: _preCacheTotalSemesters,
          isComplete: true,
        );
        _isPreCaching = false;
        _preCacheProgress = 100;
        _preCacheStatus = 'Hoàn tất! Tất cả dữ liệu đã sẵn sàng';
        notifyListeners();
        return;
      }

      _log.log('${semestersToCache.length} semesters left to cache',
          level: LogLevel.info);

      // ---- Step 2: register periods, all semesters in parallel -------------
      _preCacheStatus = 'Đang lấy các đợt học...';
      notifyListeners();

      final periodsBySemester = <int, List<RegisterPeriod>>{};
      var periodsDone = 0;

      await _runPool(
        semestersToCache.map((sem) {
          return () async {
            try {
              final periods =
                  await _authService.getRegisterPeriods(accessToken, sem.id);
              await _dbHelper.saveRegisterPeriods(sem.id, periods);
              periodsBySemester[sem.id] = periods;
            } catch (e) {
              _log.log('Register periods failed for ${sem.semesterName}: $e',
                  level: LogLevel.warning);
              periodsBySemester[sem.id] = const <RegisterPeriod>[];
            }
          };
        }).toList(),
        onEach: () {
          periodsDone++;
          // Fetching periods is roughly the first tenth of the work.
          _preCacheProgress =
              (periodsDone * 10 / semestersToCache.length).round();
          _preCacheStatus =
              'Đợt học: $periodsDone/${semestersToCache.length} học kỳ';
          notifyListeners();
        },
      );

      _preCacheTotalPeriods =
          periodsBySemester.values.fold(0, (sum, list) => sum + list.length);
      _log.log('Cached $_preCacheTotalPeriods register periods',
          level: LogLevel.success);

      // ---- Step 3: flatten (semester x period x round) into one queue ------
      final tasks = <_ExamCacheTask>[];
      for (final sem in semestersToCache) {
        final periods = periodsBySemester[sem.id] ?? const <RegisterPeriod>[];
        for (final period in periods) {
          for (final round in _examRounds) {
            tasks.add(_ExamCacheTask(sem, period, round));
          }
        }
      }

      if (tasks.isEmpty) {
        _log.log('No register periods found - nothing further to cache',
            level: LogLevel.warning);
      }

      _log.log('Queued ${tasks.length} exam-room requests', level: LogLevel.info);

      var completed = 0;
      var totalRooms = 0;
      var roundsWithData = 0;

      // Count tasks per semester so the UI can report semester-level progress
      // as each semester's last request lands.
      final remainingBySemester = <int, int>{};
      for (final task in tasks) {
        remainingBySemester.update(
          task.semester.id,
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
      final finishedSemesters = <int>{};

      await _runPool(
        tasks.map((task) {
          return () async {
            try {
              final rooms = await _authService.getStudentExamRooms(
                accessToken,
                task.semester.id,
                task.period.id,
                task.round,
              );
              await _dbHelper.saveExamRooms(
                task.semester.id,
                task.period.id,
                task.round,
                rooms,
              );
              if (rooms.isNotEmpty) {
                roundsWithData++;
                totalRooms += rooms.length;
                _log.log(
                  '${task.semester.semesterName} | ${task.period.name} | '
                  'lần ${task.round} -> ${rooms.length} phòng',
                  level: LogLevel.success,
                );
              }
            } catch (e) {
              // A missing combination is normal - most rounds have no exams.
              _log.log(
                'Exam rooms ${task.semester.semesterName}/${task.period.name}/'
                'lần ${task.round} failed: $e',
                level: LogLevel.debug,
              );
            } finally {
              final left = (remainingBySemester[task.semester.id] ?? 1) - 1;
              remainingBySemester[task.semester.id] = left;
              if (left <= 0) {
                finishedSemesters.add(task.semester.id);
              }
            }
          };
        }).toList(),
        onEach: () {
          completed++;
          // Remaining 90% of the bar covers the exam-room sweep.
          _preCacheProgress = 10 + (completed * 90 / tasks.length).round();
          _preCacheCurrentPeriod = completed;
          _preCacheStatus = 'Đang tải lịch thi: $completed/${tasks.length}';

          // Report semester-level progress as each semester's tasks finish.
          _preCacheCurrentSemester =
              cachedSemesterIds.length + finishedSemesters.length;
          notifyListeners();
        },
      );

      await _dbHelper.updateCacheProgress(
        totalSemesters: _preCacheTotalSemesters,
        cachedSemesters: _preCacheTotalSemesters,
        isComplete: true,
      );

      _log.log('═══ Exam caching complete ═══', level: LogLevel.success);
      _log.log('• Semesters: ${allSemesters.content.length}', level: LogLevel.info);
      _log.log('• Register periods: $_preCacheTotalPeriods', level: LogLevel.info);
      _log.log('• Requests made: ${tasks.length}', level: LogLevel.info);
      _log.log('• Combinations with data: $roundsWithData', level: LogLevel.info);
      _log.log('• Exam rooms cached: $totalRooms', level: LogLevel.info);

      _isPreCaching = false;
      _preCacheProgress = 100;
      _preCacheCurrentSemester = _preCacheTotalSemesters;
      await _reloadTimetableCache(_timetableGeneration);
      _preCacheStatus = 'Hoàn tất! Ứng dụng có thể hoạt động offline';
      notifyListeners();
    } catch (e) {
      _log.log('Pre-caching failed: $e', level: LogLevel.error);
      _isPreCaching = false;
      _preCacheStatus = 'Lỗi: $e';
      notifyListeners();
      // Don't throw - the app still works without a complete cache.
    }
  }

  /// Drains [tasks] with at most [_maxConcurrentRequests] running at once.
  ///
  /// Dart's event loop is single-threaded, so the shared cursor needs no lock:
  /// no `await` sits between reading and incrementing it.
  Future<void> _runPool(
    List<Future<void> Function()> tasks, {
    void Function()? onEach,
  }) async {
    if (tasks.isEmpty) return;

    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next;
        if (index >= tasks.length) return;
        next = index + 1;

        await tasks[index]();
        onEach?.call();
      }
    }

    final workerCount = min(_maxConcurrentRequests, tasks.length);
    await Future.wait(List.generate(workerCount, (_) => worker()));
  }
  
  /// Pre-cache all exam rounds in background for offline use
  Future<void> _preCacheExamRounds(
    String accessToken,
    int semesterId,
    int registerPeriodId,
    int currentRound,
  ) async {
    _log.log('_preCacheExamRounds: Caching rounds 1-5 for offline use', level: LogLevel.debug);
    
    // Cache all 5 rounds (skip the current one since it's already cached)
    for (int round = 1; round <= 5; round++) {
      if (round == currentRound) continue; // Skip current round
      
      try {
        _log.log('_preCacheExamRounds: Caching round $round...', level: LogLevel.debug);
        final rooms = await _authService.getStudentExamRooms(
          accessToken,
          semesterId,
          registerPeriodId,
          round,
        );
        
        // Save to cache
        await _dbHelper.saveExamRooms(
          semesterId,
          registerPeriodId,
          round,
          rooms,
        );
        _log.log('_preCacheExamRounds: Round $round cached (${rooms.length} rooms)', level: LogLevel.success);
      } catch (e) {
        // Silently fail - not critical if pre-caching fails
        _log.log('_preCacheExamRounds: Failed to cache round $round: $e', level: LogLevel.warning);
      }
    }
    _log.log('_preCacheExamRounds: Pre-caching complete!', level: LogLevel.success);
  }
  
  /// Fetch exam schedule (register periods) for a semester
  Future<void> fetchExamSchedule(String? accessToken, int semesterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to load from cache first
      final hasCache = await _dbHelper.hasRegisterPeriodsCache(semesterId);
      _log.log('fetchExamSchedule: hasCache=$hasCache, semesterId=$semesterId', level: LogLevel.debug);
      
      if (hasCache) {
        _registerPeriods = await _dbHelper.getRegisterPeriods(semesterId);
        _log.log('fetchExamSchedule: Loaded ${_registerPeriods.length} periods from cache', level: LogLevel.debug);
        
        // Sort by display order
        _registerPeriods.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        // Auto-select the first period if none selected
        if (_registerPeriods.isNotEmpty && _selectedRegisterPeriodId == null) {
          _selectedRegisterPeriodId = _registerPeriods.first.id;
        }

        _isLoading = false;
        notifyListeners();

        // Fetch fresh data in background ONLY if we have valid access token
        if (accessToken != null && accessToken.isNotEmpty) {
          _log.log('fetchExamSchedule: Starting background refresh', level: LogLevel.debug);
          _fetchExamScheduleFromApi(accessToken, semesterId);
        }
        return;
      }

      // No cache, try to fetch from API if we have access token
      _log.log('fetchExamSchedule: No cache, trying API', level: LogLevel.debug);
      if (accessToken != null && accessToken.isNotEmpty) {
        await _fetchExamScheduleFromApi(accessToken, semesterId);
      } else {
        // No cache and no token - show error
        _errorMessage = 'Không có dữ liệu. Vui lòng kết nối internet.';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Check if this is a 401 error (token expired)
      final is401Error = e.toString().contains('401');
      _log.log('fetchExamSchedule ERROR: is401=$is401Error, error=$e', level: LogLevel.error);
      
      if (is401Error) {
        _log.log('fetchExamSchedule: 401 error, checking cache fallback', level: LogLevel.debug);
        // Token expired - try to use cache as fallback
        final hasCache = await _dbHelper.hasRegisterPeriodsCache(semesterId);
        _log.log('fetchExamSchedule: Cache fallback hasCache=$hasCache', level: LogLevel.debug);
        
        if (hasCache) {
          // Load from cache instead of showing error
          _registerPeriods = await _dbHelper.getRegisterPeriods(semesterId);
          _registerPeriods.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          
          if (_registerPeriods.isNotEmpty && _selectedRegisterPeriodId == null) {
            _selectedRegisterPeriodId = _registerPeriods.first.id;
          }
          
          _isLoading = false;
          _errorMessage = null; // No error - we have cached data!
          notifyListeners();
          _log.log('fetchExamSchedule: SUCCESS using cache fallback', level: LogLevel.success);
          return; // Success! Using cached data
        }
        // No cache available - show friendly message
        _log.log('fetchExamSchedule: No cache available, showing error', level: LogLevel.warning);
        _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      } else {
        // Other error - show actual error
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch exam schedule from API and cache it
  Future<void> _fetchExamScheduleFromApi(
    String accessToken,
    int semesterId,
  ) async {
    try {
      final periods = await _authService.getRegisterPeriods(
        accessToken,
        semesterId,
      );

      _registerPeriods = periods;

      // Sort by display order
      _registerPeriods.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      // Auto-select the first period if none selected
      if (_registerPeriods.isNotEmpty && _selectedRegisterPeriodId == null) {
        _selectedRegisterPeriodId = _registerPeriods.first.id;
      }

      // Save to cache
      await _dbHelper.saveRegisterPeriods(semesterId, _registerPeriods);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.log('_fetchExamScheduleFromApi ERROR: $e', level: LogLevel.error);
      // Check if this is a 401 error (token expired) - completely silent
      final is401Error = e.toString().contains('401');
      
      // Check if this is an initial fetch (no existing periods) or background refresh
      if (_registerPeriods.isEmpty && _selectedSemesterId == semesterId) {
        // Initial fetch failed, rethrow so outer catch can handle with fallback
        _log.log('_fetchExamScheduleFromApi: Initial fetch failed, rethrowing', level: LogLevel.debug);
        rethrow;
      } else if (!is401Error) {
        // Only log non-auth errors for background refresh
        _log.log('Background exam schedule refresh failed: $e', level: LogLevel.warning);
      }
      // If it's 401 and we have cached data, completely silent (expected offline behavior)
    }
  }

  /// Select a register period by ID and fetch exam rooms
  Future<void> selectRegisterPeriod(
    String? accessToken,
    int semesterId,
    int periodId,
    int examRound,
  ) async {
    _selectedRegisterPeriodId = periodId;
    _examRooms = []; // Clear exam rooms when register period changes
    _isLoadingRooms = true; // Show loading state immediately
    notifyListeners();
    
    // Fetch exam rooms for the selected register period and exam round
    await fetchExamRoomDetails(
      accessToken,
      semesterId,
      periodId,
      examRound,
    );
    
    // Pre-cache other exam rounds for this period in background
    if (accessToken != null) {
      _preCacheExamRounds(accessToken, semesterId, periodId, examRound);
    }
  }

  /// Select exam round (1, 2, etc.)
  void selectExamRound(int round) {
    _selectedExamRound = round;
    // Don't clear exam rooms here - let fetchExamRoomDetails handle it
    // This prevents showing "No exam schedule" briefly before loading
    notifyListeners();
  }

  /// Fetch exam room details for selected semester, register period, and exam round
  Future<void> fetchExamRoomDetails(
    String? accessToken,
    int semesterId,
    int registerPeriodId,
    int examRound,
  ) async {
    _log.log('fetchExamRoomDetails: semesterId=$semesterId, periodId=$registerPeriodId, round=$examRound', level: LogLevel.debug);
    _log.log('fetchExamRoomDetails: accessToken=${accessToken?.substring(0, 20)}...', level: LogLevel.debug);
    // Clear exam rooms when starting to fetch new data
    _examRooms = [];
    _isLoadingRooms = true;
    _roomErrorMessage = null;
    notifyListeners();

    try {
      // Try to load from cache first
      final hasCache = await _dbHelper.hasExamRoomCache(
        semesterId,
        registerPeriodId,
        examRound,
      );
      _log.log('fetchExamRoomDetails: hasCache=$hasCache', level: LogLevel.debug);

      if (hasCache) {
        _examRooms = await _dbHelper.getExamRooms(
          semesterId,
          registerPeriodId,
          examRound,
        );

        _isLoadingRooms = false;
        notifyListeners();
        _log.log('fetchExamRoomDetails: Loaded ${_examRooms.length} rooms from cache', level: LogLevel.debug);

        // Schedule notifications for cached data
        await _scheduleExamNotifications();

        // Fetch fresh data in background ONLY if we have a valid access token
        if (accessToken != null && accessToken.isNotEmpty) {
          _log.log('fetchExamRoomDetails: Starting background refresh', level: LogLevel.debug);
          _fetchExamRoomDetailsFromApi(
            accessToken,
            semesterId,
            registerPeriodId,
            examRound,
          );
        }
        return;
      }

      // No cache, try to fetch from API if we have access token
      _log.log('fetchExamRoomDetails: No cache, trying API', level: LogLevel.debug);
      if (accessToken != null && accessToken.isNotEmpty) {
        await _fetchExamRoomDetailsFromApi(
          accessToken,
          semesterId,
          registerPeriodId,
          examRound,
        );
      } else {
        // No cache and no token - show error
        _roomErrorMessage = 'Không có dữ liệu. Vui lòng kết nối internet.';
        _isLoadingRooms = false;
        notifyListeners();
      }
    } catch (e) {
      // Check if this is a 401 error (token expired)
      final is401Error = e.toString().contains('401');
      _log.log('fetchExamRoomDetails ERROR: is401=$is401Error, error=$e', level: LogLevel.error);
      
      if (is401Error) {
        _log.log('fetchExamRoomDetails: 401 error, checking cache fallback', level: LogLevel.debug);
        // Token expired - try to use cache as fallback
        final hasCache = await _dbHelper.hasExamRoomCache(
          semesterId,
          registerPeriodId,
          examRound,
        );
        _log.log('fetchExamRoomDetails: Cache fallback hasCache=$hasCache', level: LogLevel.debug);
        
        if (hasCache) {
          // Load from cache instead of showing error
          _examRooms = await _dbHelper.getExamRooms(
            semesterId,
            registerPeriodId,
            examRound,
          );
          
          _isLoadingRooms = false;
          _roomErrorMessage = null; // No error - we have cached data!
          notifyListeners();
          
          // Schedule notifications for cached data
          await _scheduleExamNotifications();
          _log.log('fetchExamRoomDetails: SUCCESS using cache fallback', level: LogLevel.success);
          return; // Success! Using cached data
        }
        // No cache available - show friendly message
        _log.log('fetchExamRoomDetails: No cache available, showing error', level: LogLevel.warning);
        _roomErrorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      } else {
        // Other error - show actual error
        _roomErrorMessage = e.toString();
      }
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  /// Fetch exam room details from API and cache it
  Future<void> _fetchExamRoomDetailsFromApi(
    String accessToken,
    int semesterId,
    int registerPeriodId,
    int examRound,
  ) async {
    try {
      final rooms = await _authService.getStudentExamRooms(
        accessToken,
        semesterId,
        registerPeriodId,
        examRound,
      );

      if (_selectedSemesterId == semesterId &&
          _selectedRegisterPeriodId == registerPeriodId &&
          _selectedExamRound == examRound) {
        // Sort rooms by exam date to maintain consistent order
        rooms.sort((a, b) {
          // First compare by exam date (if available)
          final aDate = a.examRoom?.examDate;
          final bDate = b.examRoom?.examDate;
          
          if (aDate != null && bDate != null) {
            final dateComparison = aDate.compareTo(bDate);
            if (dateComparison != 0) return dateComparison;
          } else if (aDate != null) {
            return -1; // a has date, b doesn't -> a comes first
          } else if (bDate != null) {
            return 1; // b has date, a doesn't -> b comes first
          }
          
          // If dates are equal or both null, compare by exam date string
          final aDateStr = a.examRoom?.examDateString ?? '';
          final bDateStr = b.examRoom?.examDateString ?? '';
          final dateStrComparison = aDateStr.compareTo(bDateStr);
          if (dateStrComparison != 0) return dateStrComparison;
          
          // If still equal, compare by subject name for stability
          return a.subjectName.compareTo(b.subjectName);
        });
        
        // Check if data actually changed before updating
        final dataChanged = _examRooms.length != rooms.length ||
            !_areExamRoomsEqual(_examRooms, rooms);
        
        _examRooms = rooms;
        _isLoadingRooms = false;
        notifyListeners();

        // Only re-schedule notifications if data actually changed
        if (dataChanged) {
          await _scheduleExamNotifications();
        }
      }

      // Always save to cache regardless of current selection
      await _dbHelper.saveExamRooms(
        semesterId,
        registerPeriodId,
        examRound,
        rooms, // Save the fetched data, not _examRooms
      );
      await _reloadTimetableCache(_timetableGeneration);
    } catch (e) {
      _log.log('_fetchExamRoomDetailsFromApi ERROR: $e', level: LogLevel.error);
      // Check if this is a 401 error (token expired) - completely silent
      final is401Error = e.toString().contains('401');
      
      // Silently fail background refresh if we already have cached data
      if (_examRooms.isEmpty &&
          _selectedSemesterId == semesterId &&
          _selectedRegisterPeriodId == registerPeriodId &&
          _selectedExamRound == examRound) {
        // This is initial fetch (not background), rethrow so outer catch can handle with fallback
        _log.log('_fetchExamRoomDetailsFromApi: Initial fetch failed, rethrowing', level: LogLevel.debug);
        rethrow; // Let outer catch handle it with cache fallback!
      } else if (!is401Error) {
        // Background refresh failed for non-auth reasons - log it
        _log.log('Background exam room refresh failed: $e', level: LogLevel.warning);
      }
      // If it's 401 and we have cached data, completely silent (expected offline behavior)
    }
  }

  /// Clear all data
  void clear() {
    _timetableGeneration++;
    _isLoadingTimetable = false;
    _timetableSemester = null;
    _timetableRequest = null;
    _timetableExams = [];
    _registerPeriods = [];
    _examRooms = [];
    _selectedRegisterPeriodId = null;
    _selectedSemesterId = null;
    _selectedExamRound = 1;
    _errorMessage = null;
    _roomErrorMessage = null;
    _isLoading = false;
    _isLoadingRooms = false;
    notifyListeners();
  }

  /// Schedule notifications for upcoming exams
  Future<void> _scheduleExamNotifications() async {
    if (_examRooms.isEmpty) return;

    try {
      await NotificationHelper.scheduleExamNotifications(
        examRooms: _examRooms,
      );
      _log.log('Notifications scheduled for ${_examRooms.length} exams', level: LogLevel.success);
    } catch (e) {
      _log.log('Failed to schedule exam notifications: $e', level: LogLevel.warning);
    }
  }

  /// Compare two lists of exam rooms for equality
  bool _areExamRoomsEqual(List<StudentExamRoom> list1, List<StudentExamRoom> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      final room1 = list1[i];
      final room2 = list2[i];
      
      // Compare key fields that would affect notifications
      if (room1.id != room2.id ||
          room1.subjectName != room2.subjectName ||
          room1.examCode != room2.examCode ||
          room1.examRoom?.examDate != room2.examRoom?.examDate ||
          room1.examRoom?.examHour?.id != room2.examRoom?.examHour?.id) {
        return false;
      }
    }
    
    return true;
  }
}

/// One (semester x register period x exam round) request in the pre-cache
/// sweep. Flattening the three nested loops into records like this is what
/// lets a single worker pool keep every connection busy.
class _ExamCacheTask {
  final Semester semester;
  final RegisterPeriod period;
  final int round;

  const _ExamCacheTask(this.semester, this.period, this.round);
}

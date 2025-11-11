import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/models/api_response.dart';

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  bool _hasInitialized = false;
  bool? _lastLoginState; // Track login state changes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isLoggedIn) {
          _loadExamSchedule();
          _loadAvailableSemesters();
          _hasInitialized = true;
          _lastLoginState = userProvider.isLoggedIn;
        }
      }
    });
  }

  Future<void> _loadAvailableSemesters() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    if (!userProvider.isLoggedIn) {
      return;
    }

    await examProvider.fetchAvailableSemesters(userProvider.accessToken!);
  }

  Future<void> _loadExamSchedule() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    if (!userProvider.isLoggedIn) {
      return;
    }

    final selectedSemester = userProvider.selectedSemester;
    if (selectedSemester == null) {
      return;
    }

    // Always try to load data, whether from cache or API
    // Check if we have cached data first
    final hasCache = await examProvider.hasRegisterPeriodsCache(selectedSemester.id);
    
    if (hasCache) {
      // Load from cache without API call
      await examProvider.selectSemesterFromCache(selectedSemester.id);
    } else {
      // No cache, fetch from API (will handle null token gracefully)
      await examProvider.selectSemester(
        userProvider.accessToken,
        selectedSemester.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ExamProvider>(
      builder: (context, userProvider, examProvider, _) {
        // Check if login state changed and schedule reinitialize after build
        if (_lastLoginState != userProvider.isLoggedIn) {
          _lastLoginState = userProvider.isLoggedIn;
          _hasInitialized = false;
          
          // Schedule initialization for after the build completes
          if (userProvider.isLoggedIn && !_hasInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasInitialized) {
                _loadExamSchedule();
                _loadAvailableSemesters();
                _hasInitialized = true;
              }
            });
          }
        }
        
        if (!userProvider.isLoggedIn) {
          return _buildNotLoggedIn();
        }

        if (userProvider.selectedSemester == null) {
          return _buildNoSemesterSelected();
        }

        if (examProvider.isLoading) {
          return _buildLoading();
        }

        if (examProvider.errorMessage != null) {
          return _buildError(examProvider.errorMessage!, _loadExamSchedule);
        }

        // If no semester is selected yet in exam provider, show loading
        if (examProvider.selectedSemesterId == null) {
          return _buildLoading();
        }

        if (examProvider.registerPeriods.isEmpty) {
          return _buildNoExams();
        }

        return _buildExamSchedule(context, userProvider, examProvider);
      },
    );
  }

  Widget _buildExamSchedule(
    BuildContext context,
    UserProvider userProvider,
    ExamProvider examProvider,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          elevation: 0,
          title: Text(
            'Lịch thi',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // Semester info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn học kỳ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (examProvider.isLoadingSemesters)
                      const Center(child: CircularProgressIndicator())
                    else if (examProvider.availableSemesters.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: examProvider.selectedSemesterId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: examProvider.availableSemesters
                            .map(
                              (semester) => DropdownMenuItem<int>(
                                value: semester.id,
                                child: Row(
                                  children: [
                                    Text(semester.semesterName),
                                    if (semester.isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Hiện tại',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            await examProvider.selectSemester(
                              userProvider.accessToken,
                              value,
                            );
                          }
                        },
                      )
                    else
                      Text(
                        userProvider.selectedSemester?.semesterName ??
                            'Không có học kỳ',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Register period filter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đợt học',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: examProvider.selectedRegisterPeriodId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: examProvider.registerPeriods
                          .map(
                            (period) => DropdownMenuItem<int>(
                              value: period.id,
                              child: Text(period.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null &&
                            examProvider.selectedSemesterId != null) {
                          // selectRegisterPeriod now handles fetching internally
                          examProvider.selectRegisterPeriod(
                            userProvider.accessToken,
                            examProvider.selectedSemesterId!,
                            value,
                            examProvider.selectedExamRound,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Exam round selector
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lần thi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: examProvider.selectedExamRound,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [1, 2, 3, 4, 5]
                          .map(
                            (round) => DropdownMenuItem<int>(
                              value: round,
                              child: Text('Lần $round'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null &&
                            examProvider.selectedSemesterId != null &&
                            examProvider.selectedRegisterPeriodId != null) {
                          examProvider.selectExamRound(value);
                          // Fetch exam room details when round changes
                          examProvider.fetchExamRoomDetails(
                            userProvider.accessToken,
                            examProvider.selectedSemesterId!,
                            examProvider.selectedRegisterPeriodId!,
                            value,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Exam room details
        _buildExamRoomDetails(context, userProvider, examProvider),
      ],
    );
  }

  Widget _buildExamRoomDetails(
    BuildContext context,
    UserProvider userProvider,
    ExamProvider examProvider,
  ) {
    if (examProvider.isLoadingRooms) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (examProvider.roomErrorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    examProvider.roomErrorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (examProvider.selectedSemesterId != null &&
                          examProvider.selectedRegisterPeriodId != null) {
                        examProvider.fetchExamRoomDetails(
                          userProvider.accessToken!,
                          examProvider.selectedSemesterId!,
                          examProvider.selectedRegisterPeriodId!,
                          examProvider.selectedExamRound,
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (examProvider.examRooms.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có thông tin phòng thi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng chọn đợt học và lần thi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (examProvider.selectedSemesterId != null &&
                    examProvider.selectedRegisterPeriodId != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      examProvider.fetchExamRoomDetails(
                        userProvider.accessToken!,
                        examProvider.selectedSemesterId!,
                        examProvider.selectedRegisterPeriodId!,
                        examProvider.selectedExamRound,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final examRoom = examProvider.examRooms[index];
        return _buildExamRoomCard(context, examRoom, index);
      }, childCount: examProvider.examRooms.length),
    );
  }

  Widget _buildExamRoomCard(
    BuildContext context,
    StudentExamRoom examRoom,
    int index,
  ) {
    return Padding(
      key: ValueKey(examRoom.id), // Add unique key to preserve widget identity
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with index badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'STT ${index + 1}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          examRoom.subjectName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (examRoom.examCode != null)
                          Text(
                            'Số báo danh: ${examRoom.examCode}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Exam room details
              if (examRoom.examRoom != null) ...[
                _buildDetailRow(
                  context,
                  'Ngày thi',
                  examRoom.examRoom!.examDateString ?? 'Chưa có',
                  Icons.calendar_today,
                ),
                _buildDetailRow(
                  context,
                  'Ca thi',
                  examRoom.examRoom!.examHour?.name ?? 'Chưa có',
                  Icons.access_time,
                ),
                _buildDetailRow(
                  context,
                  'Giờ thi',
                  examRoom.examRoom!.examHour != null
                      ? '${examRoom.examRoom!.examHour!.startString ?? ''} - ${examRoom.examRoom!.examHour!.endString ?? ''}'
                      : 'Chưa có',
                  Icons.schedule,
                ),
                _buildDetailRow(
                  context,
                  'Phòng thi',
                  examRoom.examRoom!.room?.name ?? 'Chưa có',
                  Icons.room,
                ),
                if (examRoom.examRoom!.numberExpectedStudent != null)
                  _buildDetailRow(
                    context,
                    'Số sinh viên dự kiến',
                    '${examRoom.examRoom!.numberExpectedStudent}',
                    Icons.people,
                  ),
              ] else ...[
                Center(
                  child: Text(
                    'Chưa có thông tin phòng thi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa đăng nhập',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đăng nhập để xem lịch thi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSemesterSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa chọn học kỳ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chọn học kỳ trong cài đặt',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải dữ liệu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExams() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lịch thi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có lịch thi nào được công bố cho học kỳ này',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

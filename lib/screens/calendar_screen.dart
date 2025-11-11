import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final Map<String, GlobalKey> _leftDateKeys = {};
  final Map<String, GlobalKey> _rightDateKeys = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime.now();
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  void _scrollToDate(DateTime date) {
    final dateKey = _getDateKey(date);
    
    // Scroll right column (event cards)
    final rightKey = _rightDateKeys[dateKey];
    if (rightKey != null && rightKey.currentContext != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        Scrollable.ensureVisible(
          rightKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      });
    }
    
    // Scroll left column (date items) to keep selected date visible
    final leftKey = _leftDateKeys[dateKey];
    if (leftKey != null && leftKey.currentContext != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        Scrollable.ensureVisible(
          leftKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with semester selector
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lịch học',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Month navigation
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    'T${_focusedMonth.month}/${_focusedMonth.year}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            // Semester selector (compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: _buildSemesterSelector(context),
            ),
            const SizedBox(height: 24),
            // Split Timeline Layout
            Expanded(
              child: _buildSplitTimelineLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSelector(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.schoolYears == null) {
          return const SizedBox.shrink();
        }

        // Get all semesters from all school years
        final allSemesters = userProvider.schoolYears!.content
            .expand((year) => year.semesters)
            .toList();

        if (allSemesters.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: userProvider.selectedSemester?.id,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              style: Theme.of(context).textTheme.bodyMedium,
              items: allSemesters.map((semester) {
                return DropdownMenuItem<int>(
                  value: semester.id,
                  child: Text(
                    semester.semesterName,
                    style: TextStyle(
                      fontWeight:
                          semester.id == userProvider.selectedSemester?.id
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (semesterId) async {
                if (semesterId != null) {
                  final semester = allSemesters.firstWhere(
                    (s) => s.id == semesterId,
                  );
                  await userProvider.selectSemester(semester);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitTimelineLayout(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (!userProvider.isLoggedIn) {
          return EmptyStateWidget(
            icon: Icons.lock_outlined,
            title: 'Vui lòng đăng nhập',
            description: 'Đăng nhập để xem lịch học của bạn',
          );
        }

        if (userProvider.isLoadingCourses) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang tải lịch học...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        // Get all days in the month that have courses
        final daysWithCourses = _getDaysWithCourses(userProvider);

        if (daysWithCourses.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_available_outlined,
            title: 'Không có lớp',
            description: 'Không có lịch học trong tháng này',
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Date navigator
            Container(
              width: 100,
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: ListView.builder(
                controller: _leftScrollController,
                itemCount: daysWithCourses.length,
                itemBuilder: (context, index) {
                  final date = daysWithCourses[index];
                  final dateKey = _getDateKey(date);
                  
                  // Create or reuse GlobalKey for left date item
                  if (!_leftDateKeys.containsKey(dateKey)) {
                    _leftDateKeys[dateKey] = GlobalKey();
                  }
                  
                  return Container(
                    key: _leftDateKeys[dateKey],
                    child: _buildDateItem(context, date),
                  );
                },
              ),
            ),
            // Right column: Event cards
            Expanded(
              child: ListView.builder(
                controller: _rightScrollController,
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                itemCount: daysWithCourses.length,
                itemBuilder: (context, index) {
                  final date = daysWithCourses[index];
                  final dateKey = _getDateKey(date);
                  
                  // Create or reuse GlobalKey for right event cards
                  if (!_rightDateKeys.containsKey(dateKey)) {
                    _rightDateKeys[dateKey] = GlobalKey();
                  }
                  
                  return Container(
                    key: _rightDateKeys[dateKey],
                    child: _buildEventCardsForDate(context, userProvider, date),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<DateTime> _getDaysWithCourses(UserProvider userProvider) {
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    final daysWithCourses = <DateTime>[];
    
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final activeCourses = userProvider.getActiveCourses(date);
      final dayWeekIndex = date.weekday + 1;
      final hasCourses = activeCourses.any((c) => c.dayOfWeek == dayWeekIndex);
      
      if (hasCourses) {
        daysWithCourses.add(date);
      }
    }
    
    return daysWithCourses;
  }

  Widget _buildDateItem(BuildContext context, DateTime date) {
    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        _scrollToDate(date);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : isToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getWeekdayShort(date.weekday),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  Widget _buildEventCardsForDate(
    BuildContext context,
    UserProvider userProvider,
    DateTime date,
  ) {
    final activeCourses = userProvider.getActiveCourses(date);
    final dayWeekIndex = date.weekday + 1;
    final dayCourses = activeCourses
        .where((c) => c.dayOfWeek == dayWeekIndex)
        .toList()
      ..sort((a, b) => a.startCourseHour.compareTo(b.startCourseHour));

    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header for the event group (subtle, only visible when scrolling)
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day} Th${date.month}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ...dayCourses.map((course) {
          return _buildEventCard(context, userProvider, course, isSelected);
        }).toList(),
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    UserProvider userProvider,
    course,
    bool isSelected,
  ) {
    final timeRange = _getTimeRange(userProvider, course);
    final times = timeRange.split('\n');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(isSelected ? 0.12 : 0.08),
            blurRadius: isSelected ? 20 : 16,
            offset: Offset(0, isSelected ? 6 : 4),
          ),
        ],
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category indicator
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  course.courseName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${times[0]} - ${times[1]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Course code
          Text(
            course.courseCode,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Location
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                course.building.isNotEmpty
                    ? '${course.room} - ${course.building}'
                    : course.room,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  String _getTimeRange(UserProvider userProvider, course) {
    final startHour = userProvider.courseHours[course.startCourseHour];
    final endHour = userProvider.courseHours[course.endCourseHour];

    if (startHour != null && endHour != null) {
      return '${startHour.startString}\n${endHour.endString}';
    }

    return 'Tiết ${course.startCourseHour}\nTiết ${course.endCourseHour}';
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/styled_dropdown.dart';
import 'package:tlustudy_planner/screens/choose_date_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const double _dateChipWidth = 76;
  static const double _dateChipSpacing = 12;
  static const double _dateListHorizontalPadding = 16;

  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  String? _selectedFilter;
  late final ScrollController _dateScrollController;
  bool _hasScrolledToInitialDate = false;

  static const List<String> _quickFilters = [
    'today',
    'tomorrow',
    'next 2 day',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month);
    _selectedFilter = 'today';
    _dateScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lịch học',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              monthLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _buildCalendarPickerButton(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuickFilterDropdown(context),
                  const SizedBox(height: 16),
                  _buildSemesterSelector(context),
                ],
              ),
            ),
            SizedBox(height: 110, child: _buildHorizontalDatePicker(context)),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _buildDayCourses(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarPickerButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await Navigator.of(context).push<DateTime>(
          MaterialPageRoute(
            builder: (_) => ChooseDateScreen(initialDate: _selectedDate),
          ),
        );
        if (pickedDate != null) {
          setState(() {
            _selectDate(pickedDate, resetFilter: true);
          });
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildQuickFilterDropdown(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: StyledDropdownButton<String>(
        value: _selectedFilter,
        hint: 'Chọn nhanh',
        items: _quickFilters
            .map(
              (filter) => DropdownMenuItem<String>(
                value: filter,
                child: Text(filter.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          _applyQuickFilter(value);
        },
      ),
    );
  }

  Widget _buildSemesterSelector(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final schoolYears = userProvider.schoolYears;
        if (schoolYears == null) {
          return const SizedBox.shrink();
        }

        final semesters =
            schoolYears.content.expand((year) => year.semesters).toList();
        if (semesters.isEmpty) {
          return const SizedBox.shrink();
        }

        return StyledDropdownButton<int>(
          value: userProvider.selectedSemester?.id,
          isExpanded: true,
          items: semesters.map((semester) {
            final isSelected = semester.id == userProvider.selectedSemester?.id;
            return DropdownMenuItem<int>(
              value: semester.id,
              child: Text(
                semester.semesterName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            );
          }).toList(),
          onChanged: (semesterId) async {
            if (semesterId == null) return;
            final semester =
                semesters.firstWhere((candidate) => candidate.id == semesterId);
            await userProvider.selectSemester(semester);
            final semesterStart =
                DateTime.fromMillisecondsSinceEpoch(semester.startDate);
            setState(() {
              _selectedFilter = null;
              _selectDate(semesterStart);
            });
          },
        );
      },
    );
  }

  Widget _buildHorizontalDatePicker(BuildContext context) {
    final days = _generateDaysForMonth(_focusedMonth);
    final userProvider = context.watch<UserProvider>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        _dateListHorizontalPadding,
        0,
        _dateListHorizontalPadding,
        10,
      ),
      controller: _dateScrollController,
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == days.length - 1 ? 0 : _dateChipSpacing,
              ),
              child: _buildDateChip(
                context,
                days[i],
                _hasCoursesOnDate(userProvider, days[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateChip(
    BuildContext context,
    DateTime date,
    bool hasCourses,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _isSameDate(date, _selectedDate);
    final isToday = _isSameDate(date, DateTime.now());

    final dayLabel = DateFormat('EEE').format(date).toUpperCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = null;
          _selectDate(date);
        });
      },
      child: Container(
        width: _dateChipWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isToday ? AppTheme.accentColor : colorScheme.outlineVariant.withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.18 : 0.08),
              blurRadius: isSelected ? 24 : 18,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                        ? Colors.black 
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.black : colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: hasCourses ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCourses(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (!userProvider.isLoggedIn) {
          return EmptyStateWidget(
            icon: Icons.lock_outlined,
            title: 'Vui lòng đăng nhập',
            description: 'Đăng nhập để xem lịch học của bạn',
          );
        }

        // Show loading indicator while fetching courses
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        // Get courses for selected date
        final activeCourses = userProvider.getActiveCourses(_selectedDate);

        final dayWeekIndex = _selectedDate.weekday + 1;

        final dayCourses =
            activeCourses.where((c) => c.dayOfWeek == dayWeekIndex).toList()
              ..sort((a, b) => a.startCourseHour.compareTo(b.startCourseHour));

        if (dayCourses.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_available_outlined,
            title: 'Không có lớp',
            description: 'Chọn một ngày khác để xem lịch học',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: dayCourses.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(context, userProvider, dayCourses[index]);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    UserProvider userProvider,
    course,
  ) {
    final timeRange = _getTimeRange(userProvider, course);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Time and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timeRange.split('\n')[0], // Start time
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Text(
                        timeRange.split('\n')[1], // End time
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Course name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.courseCode,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.building.isNotEmpty
                          ? 'Phòng ${course.room} - ${course.building}'
                          : 'Phòng ${course.room}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    DateTime target;
    switch (filter) {
      case 'tomorrow':
        target = now.add(const Duration(days: 1));
        break;
      case 'next 2 day':
        target = now.add(const Duration(days: 2));
        break;
      case 'today':
      default:
        target = now;
        break;
    }
    setState(() {
      _selectedFilter = filter;
      _selectDate(target);
    });
  }

  void _selectDate(DateTime date, {bool resetFilter = false}) {
    final normalized = DateTime(date.year, date.month, date.day);
    _selectedDate = normalized;
    _focusedMonth = DateTime(normalized.year, normalized.month);
    if (resetFilter) {
      _selectedFilter = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(force: true);
    });
  }

  List<DateTime> _generateDaysForMonth(DateTime month) {
    final totalDays = DateUtils.getDaysInMonth(month.year, month.month);
    return List.generate(totalDays, (index) {
      return DateTime(month.year, month.month, index + 1);
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasCoursesOnDate(UserProvider userProvider, DateTime date) {
    if (!userProvider.isLoggedIn) {
      return false;
    }

    final activeCourses = userProvider.getActiveCourses(date);
    final dayWeekIndex = date.weekday + 1;
    return activeCourses.any((course) => course.dayOfWeek == dayWeekIndex);
  }

  void _scrollToSelectedDate({bool force = false}) {
    if (!force && _hasScrolledToInitialDate) {
      return;
    }

    if (!_dateScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate(force: force);
      });
      return;
    }

    final days = _generateDaysForMonth(_focusedMonth);
    final index = days.indexWhere((day) => _isSameDate(day, _selectedDate));
    if (index == -1) {
      return;
    }

    final rawOffset = _dateListHorizontalPadding +
        index * (_dateChipWidth + _dateChipSpacing);
    final maxExtent = _dateScrollController.position.maxScrollExtent;
    final targetOffset =
        (rawOffset - _dateListHorizontalPadding).clamp(0.0, maxExtent);

    if (!force) {
      _hasScrolledToInitialDate = true;
    }
    _dateScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
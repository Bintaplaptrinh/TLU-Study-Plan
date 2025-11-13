import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/models/api_response.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late DateTime _currentDate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    
    // Update every second to keep the date fresh
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      // Only rebuild if the date actually changed
      if (now.day != _currentDate.day || 
          now.month != _currentDate.month || 
          now.year != _currentDate.year) {
        setState(() {
          _currentDate = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = _currentDate;
    final dayName = _getDayOfWeek(today.weekday);
    final dateFormat =
        '$dayName, Ngày ${today.day}/${today.month}/${today.year}';

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        // Show login prompt if not logged in
        if (!userProvider.isLoggedIn) {
          return Center(
            child: EmptyStateWidget(
              icon: Icons.lock_outlined,
              title: 'Vui lòng đăng nhập',
              description: 'Đăng nhập để xem lịch học của bạn',
            ),
          );
        }

        // Get today's courses
        final todayWeekIndex = today.weekday + 1;
        final activeCourses = userProvider.getActiveCourses(today);
        final todaySchedules =
            activeCourses
                .where((course) => course.dayOfWeek == todayWeekIndex)
                .toList()
              ..sort((a, b) => a.startCourseHour.compareTo(b.startCourseHour));

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              // Modern App Bar with date
              SliverAppBar(
                floating: true,
                snap: true,
                expandedHeight: 160,
                backgroundColor: Theme.of(context).colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Hi, ${userProvider.tluUser?.displayName ?? userProvider.currentUser.fullName}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateFormat,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Course list or empty state
              todaySchedules.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.event_available_rounded,
                        title: 'Không có lớp hôm nay',
                        description: 'Hãy tận hưởng ngày nghỉ của bạn!',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildCourseCard(
                              context,
                              userProvider,
                              todaySchedules[index],
                            );
                          },
                          childCount: todaySchedules.length,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    UserProvider userProvider,
    StudentCourseSubject course,
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

  String _getDayOfWeek(int weekday) {
    // Monday = 1, Sunday = 7
    // In Vietnamese: Monday-Saturday use "Thứ" prefix, Sunday is just "Chủ Nhật"
    const days = [
      'Thứ Hai', // Monday (1)
      'Thứ Ba', // Tuesday (2)
      'Thứ Tư', // Wednesday (3)
      'Thứ Năm', // Thursday (4)
      'Thứ Sáu', // Friday (5)
      'Thứ Bảy', // Saturday (6)
      'Chủ Nhật', // Sunday (7)
    ];
    if (weekday >= 1 && weekday <= 7) {
      return days[weekday - 1];
    }
    return '';
  }

  String _getTimeRange(UserProvider userProvider, StudentCourseSubject course) {
    final startHour = userProvider.courseHours[course.startCourseHour];
    final endHour = userProvider.courseHours[course.endCourseHour];

    if (startHour != null && endHour != null) {
      return '${startHour.startString}\n${endHour.endString}';
    }

    return 'Tiết ${course.startCourseHour}\nTiết ${course.endCourseHour}';
  }
}

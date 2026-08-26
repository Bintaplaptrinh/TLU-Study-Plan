import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/schedule_time.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/weather_card.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

/// Home tab: greeting, live weather, and today's classes as a timeline.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // A minute is plenty to keep "đang học" and the greeting accurate.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            if (!userProvider.isLoggedIn) {
              return const EmptyStateWidget(
                icon: Symbols.lock_rounded,
                title: 'Vui lòng đăng nhập',
                description: 'Đăng nhập để xem lịch học của bạn',
              );
            }

            final today = DateTime(_now.year, _now.month, _now.day);
            final classes = _todayClasses(userProvider, today);

            return RefreshIndicator(
              onRefresh: () async => setState(() => _now = DateTime.now()),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _header(context, userProvider)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: WeatherCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _summaryRow(context, classes, userProvider),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      child: Row(
                        children: [
                          TrText(
                            'Lịch hôm nay',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.text(context),
                            ),
                          ),
                          const Spacer(),
                          if (classes.isNotEmpty)
                            Text(
                              '${classes.length} ${context.tr('lớp')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (userProvider.isLoadingCourses)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (classes.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: EmptyStateWidget(
                          icon: Symbols.beach_access_rounded,
                          title: 'Không có lớp hôm nay',
                          description: 'Hãy tận hưởng ngày nghỉ của bạn!',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: classes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final slot = classes[i];
                          return ClassCard(
                            course: slot.course,
                            startLabel: slot.startLabel,
                            endLabel: slot.endLabel,
                            state: slot.stateAt(_now),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────

  Widget _header(BuildContext context, UserProvider userProvider) {
    final name = userProvider.tluUser?.displayName ??
        userProvider.currentUser.fullName;
    final firstName = name.trim().split(' ').last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrText(
                  _greeting(_now.hour),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 3),
                // A person's name is never translated.
                Text(
                  firstName.isEmpty ? context.tr('Sinh viên') : firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 6),
                TrText(
                  vietnameseFullDate(_now),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSoft(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AvatarBadge(name: name),
        ],
      ),
    );
  }

  // ── quick stats ─────────────────────────────────────────────────────────

  Widget _summaryRow(
    BuildContext context,
    List<ClassSlot> classes,
    UserProvider userProvider,
  ) {
    final upcoming =
        classes.where((s) => s.stateAt(_now) != ClassState.past).toList();
    final remaining = upcoming.length;
    final ClassSlot? next = upcoming.isEmpty ? null : upcoming.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Symbols.menu_book_rounded,
              label: 'Còn lại',
              value: classes.isEmpty
                  ? '—'
                  : '$remaining ${context.tr('lớp')}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Symbols.schedule_rounded,
              label: 'Tiết kế tiếp',
              value: classes.isEmpty
                  ? '—'
                  : (next == null ? 'Đã xong' : next.startLabel),
            ),
          ),
        ],
      ),
    );
  }

  // ── data ────────────────────────────────────────────────────────────────

  List<ClassSlot> _todayClasses(UserProvider userProvider, DateTime today) {
    // The API encodes Monday as 2 … Sunday as 8.
    final apiWeekday = today.weekday + 1;
    final courses = userProvider
        .getActiveCourses(today)
        .where((c) => c.dayOfWeek == apiWeekday)
        .toList()
      ..sort((a, b) => a.startCourseHour.compareTo(b.startCourseHour));

    return [
      for (final course in courses) ClassSlot.from(course, userProvider, today),
    ];
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accentTint(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon,
                size: 19, weight: 600, color: AppColors.accent(context)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? 'SV'
        : (parts.length == 1
            ? parts.first.substring(0, 1)
            : '${parts[parts.length - 2][0]}${parts.last[0]}');

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(context),
        ),
        shape: BoxShape.circle,
      ),
      child: TrText(
        initials.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tlustudy_planner/widgets/glass_button.dart';
import 'package:tlustudy_planner/providers/exam_provider.dart';
import 'package:tlustudy_planner/widgets/timetable_card.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/providers/mail_provider.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/notice_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/utils/schedule_time.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
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
            final exams = context.watch<ExamProvider>();
            final classes = timetableOn(
              _todayClasses(userProvider, today),
              exams.timetableExams,
              today,
            );

            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _now = DateTime.now());
                final semester = userProvider.selectedSemester?.id;
                if (semester != null)
                  await exams.loadTimetable(
                    userProvider.accessToken,
                    semester,
                    force: true,
                  );
              },
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
                              '${classes.length} ${context.tr('mục')}',
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
                  if (userProvider.isLoadingCourses || (exams.isLoadingTimetable && classes.isEmpty))
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
                          title: 'Không có lịch hôm nay',
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
                          final state = slot.stateAt(_now);
                          return TimetableCard(slot: slot, state: state);
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: FloatingNavBar.bottomInset(context),
                    ),
                  ),
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
    final name =
        userProvider.tluUser?.displayName ?? userProvider.currentUser.fullName;
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
          const _NoticeButton(),
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
    final upcoming = classes
        .where((s) => s.stateAt(_now) != ClassState.past)
        .toList();
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
              value: classes.isEmpty ? '—' : '$remaining ${context.tr('mục')}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Symbols.schedule_rounded,
              label: 'Lịch kế tiếp',
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
    final courses =
        userProvider
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
            child: Icon(
              icon,
              size: 19,
              weight: 600,
              color: AppColors.accent(context),
            ),
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

/// Nút Thông báo ở góc phải tiêu đề Trang chủ.
///
/// Trước đây chỗ này là vòng tròn chữ cái đầu, bấm vào ra Cài đặt - một lối
/// tắt ít ai dùng, vì Cài đặt đã có sẵn một tab riêng ngay dưới đáy màn hình.
/// Thông báo thì không có tab nào, nên nó nhận chỗ đứng này: có việc mới thì
/// thấy ngay từ Trang chủ.
class _NoticeButton extends StatelessWidget {
  const _NoticeButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<MailProvider>(
      builder: (context, mail, _) {
        final unread = mail.isLinked ? mail.unreadCount : 0;

        return Semantics(
          button: true,
          label: unread > 0
              ? '${context.tr('Thông báo')}, $unread ${context.tr('thư chưa đọc')}'
              : context.tr('Thông báo'),
          child: Tooltip(
            message: context.tr('Thông báo'),
            waitDuration: const Duration(milliseconds: 600),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GlassIconButton(icon: Symbols.notifications_rounded,
                    onTap: () => pushSlide(context, const NoticeScreen()),
                    color: AppColors.text(context)),
                  // Huy hiệu số thư chưa đọc. Vượt 9 thì hiện "9+" - con số
                  // chính xác không đáng để huy hiệu phình ra che mất icon.
                  if (unread > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 19),
                        height: 19,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColors.danger(context),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.bg(context),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

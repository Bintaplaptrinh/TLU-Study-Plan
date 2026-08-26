import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/choose_date_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/schedule_time.dart';
import 'package:tlustudy_planner/widgets/calendar_widgets.dart';
import 'package:tlustudy_planner/widgets/class_card.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/styled_dropdown.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

enum CalendarMode { week, month }

/// Schedule tab: a Tuần / Tháng segmented control drives the calendar in the
/// top card; the selected day's classes fill the sheet below.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  CalendarMode _mode = CalendarMode.week;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        // One scroll view for the whole page: in Tháng the grid is tall
        // enough to push the class list off-screen, so the calendar has to
        // be able to scroll away with it rather than sit in a fixed header.
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _calendarCard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ..._daySheetSlivers(context),
          ],
        ),
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    final label = _mode == CalendarMode.week
        ? weekRangeLabel(_selectedDate)
        : vietnameseMonth(_focusedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
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
                    TrText(
                      'Lịch học',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TrText(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              _RoundButton(
                icon: Symbols.today_rounded,
                tooltip: 'Về hôm nay',
                onTap: () => setState(() => _select(DateTime.now())),
              ),
              const SizedBox(width: 8),
              _RoundButton(
                icon: Symbols.edit_calendar_rounded,
                tooltip: 'Chọn ngày',
                onTap: () async {
                  final picked = await Navigator.of(context).push<DateTime>(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChooseDateScreen(initialDate: _selectedDate),
                    ),
                  );
                  if (picked != null && mounted) {
                    setState(() => _select(picked));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedPill<CalendarMode>(
            value: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
            segments: const [
              SegmentItem(
                value: CalendarMode.week,
                label: 'Tuần',
                icon: Symbols.view_week_rounded,
              ),
              SegmentItem(
                value: CalendarMode.month,
                label: 'Tháng',
                icon: Symbols.calendar_month_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── calendar card ───────────────────────────────────────────────────────

  Widget _calendarCard(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border(context)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _mode == CalendarMode.week
                ? WeekStrip(
                    key: const ValueKey('week'),
                    selectedDate: _selectedDate,
                    hasEvents: (d) => _hasClasses(userProvider, d),
                    onSelect: (d) => setState(() => _select(d)),
                    onWeekChanged: (monday) => setState(() {
                      _focusedMonth = DateTime(monday.year, monday.month);
                    }),
                  )
                : MonthGrid(
                    key: const ValueKey('month'),
                    selectedDate: _selectedDate,
                    hasEvents: (d) => _hasClasses(userProvider, d),
                    onSelect: (d) => setState(() => _select(d)),
                    onMonthChanged: (m) => setState(() => _focusedMonth = m),
                  ),
          ),
        ),
      ),
    );
  }

  // ── day sheet ───────────────────────────────────────────────────────────

  /// The lower "sheet" as slivers rather than a fixed-height box, so it takes
  /// part in the page's single scroll. [DecoratedSliver] paints the rounded
  /// surface behind the whole group, and the trailing filler keeps that
  /// surface reaching the bottom of the screen on quiet days.
  List<Widget> _daySheetSlivers(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    final decoration = BoxDecoration(
      color: AppColors.surfaceAlt(context),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      border: Border(top: BorderSide(color: AppColors.border(context))),
    );

    Widget wrap(List<Widget> slivers) => DecoratedSliver(
      decoration: decoration,
      sliver: SliverMainAxisGroup(slivers: slivers),
    );

    if (!userProvider.isLoggedIn) {
      return [
        wrap(const [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EmptyStateWidget(
                icon: Symbols.lock_rounded,
                title: 'Vui lòng đăng nhập',
                description: 'Đăng nhập để xem lịch học của bạn',
              ),
            ),
          ),
          SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink()),
        ]),
      ];
    }

    if (userProvider.isLoadingCourses) {
      return [
        wrap([
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  TrText(
                    'Đang tải lịch học...',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSoft(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox.shrink(),
          ),
        ]),
      ];
    }

    final slots = _classesOn(userProvider, _selectedDate);
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);

    return [
      wrap([
        SliverToBoxAdapter(child: _dayHeader(context, slots.length)),
        SliverToBoxAdapter(child: _semesterSelector(context)),
        if (slots.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyStateWidget(
                icon: Symbols.event_available_rounded,
                title: 'Không có lớp',
                description: 'Chọn một ngày khác để xem lịch học',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 20, 8),
            sliver: SliverList.separated(
              itemCount: slots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final slot = slots[i];
                return ClassCard(
                  course: slot.course,
                  startLabel: slot.startLabel,
                  endLabel: slot.endLabel,
                  state: isToday ? slot.stateAt(now) : ClassState.upcoming,
                );
              },
            ),
          ),
        // Clears the bottom navigation bar and stretches the sheet's
        // background to the bottom edge when the list is short.
        const SliverFillRemaining(
          hasScrollBody: false,
          child: SizedBox(height: 28),
        ),
      ]),
    ];
  }

  Widget _dayHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrText(
                  vietnameseWeekday(_selectedDate),
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentTint(context),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              count == 0 ? context.tr('Nghỉ') : '$count ${context.tr('lớp')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _semesterSelector(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final schoolYears = userProvider.schoolYears;
        if (schoolYears == null) return const SizedBox.shrink();

        final semesters = schoolYears.content
            .expand((year) => year.semesters)
            .toList();
        if (semesters.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: StyledDropdownButton<int>(
            value: userProvider.selectedSemester?.id,
            isExpanded: true,
            items: semesters
                .map(
                  (semester) => DropdownMenuItem<int>(
                    value: semester.id,
                    child: TrText(
                      semester.semesterName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            semester.id == userProvider.selectedSemester?.id
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (semesterId) async {
              if (semesterId == null) return;
              final semester = semesters.firstWhere((c) => c.id == semesterId);
              await userProvider.selectSemester(semester);
              if (!mounted) return;
              setState(() {
                _select(
                  DateTime.fromMillisecondsSinceEpoch(semester.startDate),
                );
              });
            },
          ),
        );
      },
    );
  }

  // ── data ────────────────────────────────────────────────────────────────

  void _select(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _focusedMonth = DateTime(date.year, date.month);
  }

  List<ClassSlot> _classesOn(UserProvider userProvider, DateTime date) {
    final apiWeekday = date.weekday + 1; // API: Monday = 2 … Sunday = 8
    final courses =
        userProvider
            .getActiveCourses(date)
            .where((c) => c.dayOfWeek == apiWeekday)
            .toList()
          ..sort((a, b) => a.startCourseHour.compareTo(b.startCourseHour));

    return [
      for (final course in courses) ClassSlot.from(course, userProvider, date),
    ];
  }

  bool _hasClasses(UserProvider userProvider, DateTime date) {
    if (!userProvider.isLoggedIn) return false;
    final apiWeekday = date.weekday + 1;
    return userProvider
        .getActiveCourses(date)
        .any((course) => course.dayOfWeek == apiWeekday);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 21,
            weight: 500,
            color: AppColors.accent(context),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

/// ── Segmented control ─────────────────────────────────────────────────────
/// A pill with an animated thumb, used for the Tuần / Tháng switch.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 40,
  });

  final List<SegmentItem<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = segments.indexWhere((s) => s.value == value);
    final count = segments.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final segWidth = width / count;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: (index < 0 ? 0 : index) * segWidth,
                top: 0,
                bottom: 0,
                width: segWidth,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.accentGradient(context),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final seg in segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(seg.value),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: seg.value == value
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: seg.value == value
                                  ? Colors.white
                                  : AppColors.textSoft(context),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (seg.icon != null) ...[
                                  Icon(
                                    seg.icon,
                                    size: 17,
                                    weight: 600,
                                    color: seg.value == value
                                        ? Colors.white
                                        : AppColors.textSoft(context),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                TrText(seg.label),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SegmentItem<T> {
  const SegmentItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// ── Week strip ────────────────────────────────────────────────────────────
/// Seven day cells for one week; swipe left/right to move between weeks.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    required this.hasEvents,
    this.onWeekChanged,
    this.height = 92,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  /// Whether a dot should be shown under a given day.
  final bool Function(DateTime) hasEvents;

  /// Fired with the Monday of the week the user swiped to.
  final ValueChanged<DateTime>? onWeekChanged;
  final double height;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  static const int _initialPage = 1000;
  late final DateTime _anchorMonday;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _anchorMonday = _mondayOf(widget.selectedDate);
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final target = _pageFor(widget.selectedDate);
      if (_controller.hasClients &&
          (_controller.page ?? _initialPage).round() != target) {
        _controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  int _pageFor(DateTime date) {
    final monday = _mondayOf(date);
    final diff = monday.difference(_anchorMonday).inDays ~/ 7;
    return _initialPage + diff;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (page) {
          final monday =
              _anchorMonday.add(Duration(days: (page - _initialPage) * 7));
          widget.onWeekChanged?.call(monday);
        },
        itemBuilder: (context, page) {
          final monday =
              _anchorMonday.add(Duration(days: (page - _initialPage) * 7));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: DayCell(
                        date: monday.add(Duration(days: i)),
                        selected: _isSameDay(
                          monday.add(Duration(days: i)),
                          widget.selectedDate,
                        ),
                        hasEvents:
                            widget.hasEvents(monday.add(Duration(days: i))),
                        onTap: () =>
                            widget.onSelect(monday.add(Duration(days: i))),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A single day pill — weekday initial on top, day number below, event dot.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
    this.compact = false,
    this.muted = false,
  });

  final DateTime date;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;
  final bool compact;

  /// Days outside the focused month in the grid view.
  final bool muted;

  static const List<String> _weekdayInitialsVi = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  static const List<String> _weekdayInitialsEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Weekday headers are abbreviations rather than words, so they come from a
  /// pair of fixed lists instead of the translator.
  static List<String> weekdayInitials(BuildContext context) =>
      context.watch<LocaleProvider>().isEnglish
          ? _weekdayInitialsEn
          : _weekdayInitialsVi;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    final accent = AppColors.accent(context);

    final Color numberColor = selected
        ? Colors.white
        : muted
            ? AppColors.textMuted(context).withValues(alpha: 0.55)
            : isToday
                ? accent
                : AppColors.text(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.accentGradient(context),
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: !selected && isToday
              ? Border.all(color: accent.withValues(alpha: 0.5), width: 1.4)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Text(
                weekdayInitials(context)[date.weekday - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 6),
            ],
            TrText(
              '${date.day}',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: selected || isToday
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: numberColor,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasEvents ? 1 : 0,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Month grid ────────────────────────────────────────────────────────────
/// A full month, Monday-first, swipeable between months.
class MonthGrid extends StatefulWidget {
  const MonthGrid({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    required this.hasEvents,
    this.onMonthChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime>? onMonthChanged;

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  static const int _initialPage = 1000;
  static const double _cellAspectRatio = 0.82;
  late final DateTime _anchorMonth;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _anchorMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant MonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _pageFor(widget.selectedDate);
    if (_controller.hasClients &&
        (_controller.page ?? _initialPage).round() != target) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _pageFor(DateTime date) {
    final months = (date.year - _anchorMonth.year) * 12 +
        (date.month - _anchorMonth.month);
    return _initialPage + months;
  }

  DateTime _monthFor(int page) =>
      DateTime(_anchorMonth.year, _anchorMonth.month + (page - _initialPage));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Row(
            children: [
              for (final label in DayCell.weekdayInitials(context))
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Six rows always fit, so the last week is never clipped.
            const hPadding = 30.0;
            final cellWidth = (constraints.maxWidth - hPadding) / 7;
            final height = 6 * (cellWidth / _cellAspectRatio + 2);
            return SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) =>
                    widget.onMonthChanged?.call(_monthFor(page)),
                itemBuilder: (context, page) =>
                    _buildMonth(context, _monthFor(page)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonth(BuildContext context, DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leading = firstOfMonth.weekday - 1; // Monday-first
    final gridStart = firstOfMonth.subtract(Duration(days: leading));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: _cellAspectRatio,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          final date = gridStart.add(Duration(days: index));
          return DayCell(
            date: date,
            compact: true,
            muted: date.month != month.month,
            selected: _isSameDay(date, widget.selectedDate),
            hasEvents: widget.hasEvents(date),
            onTap: () => widget.onSelect(date),
          );
        },
      ),
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────

DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

/// Where a class sits relative to right now.
enum ClassState { past, current, upcoming }

/// The one class card used by both Hôm nay and Lịch học.
///
/// The class happening right now is filled with the blue accent (white text);
/// everything else is a white/near-black surface card with black/white text.
class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.course,
    required this.startLabel,
    required this.endLabel,
    this.state = ClassState.upcoming,
    this.onTap,
    this.showTimeline = true,
    this.isExam = false,
  });

  final StudentCourseSubject course;
  final String startLabel; // "07:00"
  final String endLabel; // "09:25"
  final ClassState state;
  final VoidCallback? onTap;

  /// Draws the vertical rail + dot on the left, timeline style.
  final bool showTimeline;
  final bool isExam;

  @override
  Widget build(BuildContext context) {
    final active = state == ClassState.current;
    final dim = state == ClassState.past;

    final accent = isExam
        ? AppColors.danger(context)
        : AppColors.accent(context);
    final surface = AppColors.surface(context);
    final onCard = active ? Colors.white : AppColors.text(context);
    final softOnCard = active
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.textSoft(context);

    final card = Opacity(
      opacity: dim ? 0.62 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isExam
                          ? const [Color(0xFFDC2626), Color(0xFF991B1B)]
                          : AppColors.accentGradient(context),
                    )
                  : null,
              color: active ? null : surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: active
                  ? null
                  : Border.all(color: AppColors.border(context)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flexible, not Expanded: a short title lets the code chip
                    // sit right beside it instead of being pushed to the edge.
                    Flexible(
                      child: TrText(
                        course.courseName,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (active)
                      _LiveBadge(color: Colors.white, isExam: isExam)
                    else
                      // Capped at a third of the card so a long code can never
                      // squeeze the title out; it wraps to a second line and
                      // only then ellipsises.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: codeChipMaxWidth(context),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isExam ? Theme.of(context).colorScheme.errorContainer : AppColors.accentTint(context),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            isExam ? context.tr('LỊCH THI') : breakAnywhere(course.courseCode),
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Both metas are flexible: on a narrow phone the time
                    // alone can be wide enough to push the room off the card.
                    Flexible(
                      child: _Meta(
                        icon: Symbols.schedule_rounded,
                        label: '$startLabel – $endLabel',
                        color: softOnCard,
                        strong: true,
                        translate: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _Meta(
                        icon: Symbols.location_on_rounded,
                        // The room code is never translated; only the building
                        // name is, and on its own so it hits the dictionary.
                        label: course.building.isNotEmpty
                            ? '${course.room} · ${_building(context, course.building)}'
                            : course.room,
                        color: softOnCard,
                        translate: false,
                      ),
                    ),
                  ],
                ),
                if ((course.lecturer?.name ?? '').isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _Meta(
                    icon: Symbols.person_rounded,
                    label: course.lecturer!.name,
                    color: softOnCard,
                    // A lecturer's name is a proper noun, never translated.
                    translate: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!showTimeline) return card;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 14),
                TrText(
                  startLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? accent : AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                TrText(
                  endLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Rail(active: active, dim: dim, isExam: isExam),
          const SizedBox(width: 12),
          Expanded(child: card),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.active, required this.dim, this.isExam = false});

  final bool active;
  final bool dim;
  final bool isExam;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final line = AppColors.border(context);

    return SizedBox(
      width: 12,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: Center(child: Container(width: 2, color: line)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Container(
              width: active ? 12 : 9,
              height: active ? 12 : 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isExam
                    ? AppColors.danger(context)
                    : active
                    ? accent
                    : (dim
                          ? AppColors.textMuted(context)
                          : AppColors.surface(context)),
                border: Border.all(
                  color: isExam
                      ? AppColors.danger(context)
                      : active
                      ? accent
                      : AppColors.textMuted(context),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    required this.color,
    this.strong = false,
    this.translate = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool strong;

  /// False when [label] was assembled from already-translated parts.
  final bool translate;

  TextStyle get _style => TextStyle(
    fontSize: 12.5,
    fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color, weight: 500),
        const SizedBox(width: 5),
        Flexible(
          child: translate
              ? TrText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style,
                )
              : Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style,
                ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge({required this.color, this.isExam = false});

  final Color color;
  final bool isExam;

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TrText(
            widget.isExam ? 'ĐANG THI' : 'ĐANG HỌC',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Building names arrive as "Nhà A2" or "Toà nhà C3" - a Vietnamese word
/// followed by an identifier. Translating the whole string turns the
/// identifier into nonsense, so only the leading word is translated.
String _building(BuildContext context, String raw) {
  final trimmed = raw.trim();
  final space = trimmed.indexOf(' ');
  if (space <= 0) return context.tr(trimmed);

  // Try the two-word prefix first ("Toà nhà"), then the single word.
  final second = trimmed.indexOf(' ', space + 1);
  if (second > 0) {
    final twoWords = trimmed.substring(0, second);
    final translated = context.tr(twoWords);
    if (translated != twoWords) {
      return '$translated${trimmed.substring(second)}';
    }
  }
  final first = trimmed.substring(0, space);
  return '${context.tr(first)}${trimmed.substring(space)}';
}

/// Course codes have no spaces ("CSE441_02"), so Flutter has nowhere to wrap
/// them and they overflow their chip. Zero-width spaces give the layout a
/// legal break after every character without changing what is displayed or
/// what gets copied.
String breakAnywhere(String value) {
  if (value.length <= 6) return value;
  const zwsp = '\u200B';
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    buffer.write(value[i]);
    if (i < value.length - 1) buffer.write(zwsp);
  }
  return buffer.toString();
}

/// Widest a course-code chip may get before it wraps.
///
/// Derived from the screen rather than the card's own constraints: the card
/// sits inside an [IntrinsicHeight] for the timeline rail, and a LayoutBuilder
/// there has no intrinsic dimensions, which collapses every card to nothing.
double codeChipMaxWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.26).clamp(72.0, 132.0);
}

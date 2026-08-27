import 'package:flutter/material.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';

/// Mở một popup chi tiết trượt lên từ đáy.
///
/// Dùng Navigator gốc để tấm nền mờ phủ được cả thanh điều hướng nổi - nếu
/// dùng Navigator lồng thì thanh sẽ nổi lên trên tấm nền, trông như một nút
/// lơ lửng không bấm được.
Future<T?> showDetailSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (_) => DetailSheet(child: child),
  );
}

/// Vỏ ngoài của popup chi tiết: bo góc trên, thanh kéo, và cuộn được khi nội
/// dung dài hơn 85% chiều cao màn hình.
class DetailSheet extends StatelessWidget {
  const DetailSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khối đầu popup: ô icon màu, tên chính, dòng phụ.
class DetailSheetHeader extends StatelessWidget {
  const DetailSheetHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.translateTitle = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  /// Tên riêng (mã lớp, mã biên lai) thì để `false` cho khỏi bị dịch.
  final bool translateTitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 19,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: AppColors.text(context),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              translateTitle
                  ? TrText(title, style: titleStyle)
                  : Text(title, style: titleStyle),
              if ((subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Một dòng "nhãn - giá trị" trong popup.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.translateValue = false,
    this.strong = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  /// Mặc định không dịch: phần lớn giá trị là mã, số, tên riêng.
  final bool translateValue;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 14.5,
      height: 1.35,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      color: valueColor ?? AppColors.text(context),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, weight: 500, color: AppColors.textMuted(context)),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: TrText(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: translateValue
                ? TrText(value, style: valueStyle)
                : Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

/// Vạch ngăn mảnh giữa các nhóm dòng.
class DetailDivider extends StatelessWidget {
  const DetailDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 22, thickness: 1, color: AppColors.border(context));
  }
}

/// Nhãn trạng thái nhỏ, nền nhạt cùng tông với [color].
class DetailChip extends StatelessWidget {
  const DetailChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: TrText(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: color,
        ),
      ),
    );
  }
}

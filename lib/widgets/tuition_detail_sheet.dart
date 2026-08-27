import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/widgets/detail_sheet.dart';

/// "1234567" → "1,234,567 đ".
String formatVnd(double amount) {
  final digits = amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '$digits đ';
}

/// Popup chi tiết một khoản học phí hoặc một biên lai đã nộp.
///
/// Thẻ trong danh sách phải cắt bớt ghi chú và không có chỗ cho ngày nộp hay
/// số đã nộp một phần - những con số hay bị thắc mắc nhất thì lại nằm ngoài
/// tầm nhìn.
class TuitionDetailSheet extends StatelessWidget {
  const TuitionDetailSheet({super.key, required this.entry});

  final TuitionEntry entry;

  @override
  Widget build(BuildContext context) {
    final settled = entry.outstanding <= 0;
    final accent = entry.isPayment || settled
        ? AppColors.success(context)
        : AppColors.warning(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSheetHeader(
          icon: entry.isPayment
              ? Symbols.receipt_long_rounded
              : Symbols.account_balance_wallet_rounded,
          color: accent,
          title: entry.semesterName.isEmpty
              ? 'Không rõ học kỳ'
              : entry.semesterName,
          subtitle: entry.isPayment ? 'Biên lai đã nộp' : 'Khoản phải nộp',
        ),
        const SizedBox(height: 16),

        // Con số quan trọng nhất, tách hẳn ra cho đọc được từ xa.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatVnd(entry.amount),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              DetailChip(
                label: entry.isPayment
                    ? 'Đã nộp'
                    : (settled ? 'Đã thanh toán đủ' : 'Còn thiếu'),
                color: accent,
              ),
            ],
          ),
        ),

        const DetailDivider(),

        if (!entry.isPayment) ...[
          DetailRow(
            icon: Symbols.check_circle_rounded,
            label: 'Đã nộp',
            value: formatVnd(entry.amountPaid),
            valueColor: AppColors.success(context),
          ),
          DetailRow(
            icon: Symbols.pending_rounded,
            label: 'Còn lại',
            value: formatVnd(entry.outstanding),
            valueColor: settled
                ? AppColors.success(context)
                : AppColors.warning(context),
            strong: true,
          ),
        ],

        if ((entry.dateString ?? '').isNotEmpty)
          DetailRow(
            icon: Symbols.event_rounded,
            label: 'Ngày',
            value: entry.dateString!,
          ),
        if ((entry.note ?? '').isNotEmpty)
          DetailRow(
            icon: Symbols.sticky_note_2_rounded,
            label: 'Ghi chú',
            value: entry.note!,
            translateValue: true,
          ),
        if (entry.id > 0)
          DetailRow(
            icon: Symbols.tag_rounded,
            label: 'Mã chứng từ',
            value: '#${entry.id}',
          ),
      ],
    );
  }
}

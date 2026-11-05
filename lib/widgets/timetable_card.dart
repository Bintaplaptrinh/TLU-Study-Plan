import 'package:flutter/material.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/utils/schedule_time.dart';
import 'class_card.dart';
import 'class_detail_sheet.dart';
import 'detail_sheet.dart';

class TimetableCard extends StatelessWidget {
  const TimetableCard({super.key, required this.slot, required this.state});
  final ClassSlot slot;
  final ClassState state;

  @override
  Widget build(BuildContext context) => ClassCard(
    course: slot.course,
    startLabel: slot.startLabel,
    endLabel: slot.endLabel,
    state: state,
    isExam: slot.isExam,
    onTap: () => showDetailSheet(
      context,
      child: slot.isExam
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TrText(
                    'Lịch thi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slot.exam!.subjectName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${slot.start.day}/${slot.start.month}/${slot.start.year}',
                  ),
                  Text('${slot.startLabel} – ${slot.endLabel}'),
                  Text('${context.tr('Phòng thi')}: ${slot.course.room}'),
                  if (slot.exam!.examCode != null)
                    Text(
                      '${context.tr('Số báo danh')}: ${slot.exam!.examCode}',
                    ),
                  if (slot.exam!.examRoom?.duration != null)
                    Text(
                      '${slot.exam!.examRoom!.duration} ${context.tr('phút')}',
                    ),
                ],
              ),
            )
          : ClassDetailSheet(
              course: slot.course,
              startLabel: slot.startLabel,
              endLabel: slot.endLabel,
              state: state,
            ),
    ),
  );
}

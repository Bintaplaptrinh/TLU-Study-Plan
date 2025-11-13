import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';

class ChooseDateScreen extends StatefulWidget {
  const ChooseDateScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<ChooseDateScreen> createState() => _ChooseDateScreenState();
}

class _ChooseDateScreenState extends State<ChooseDateScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _months;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    final now = DateTime.now();
    final initialMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final currentMonth = DateTime(now.year, now.month);
    final startMonth = initialMonth.isBefore(currentMonth)
        ? initialMonth
        : currentMonth;

    _months = List.generate(
      12,
      (index) => DateTime(startMonth.year, startMonth.month + index, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Choose Date'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final month = _months[index];
                return _MonthCalendar(
                  month: month,
                  selectedDate: _selectedDate,
                  onSelect: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'CONTINUE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.selectedDate,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmptySlots = firstDay.weekday - 1; // Monday-first grid
    final totalItems = leadingEmptySlots + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthLabel,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _buildWeekdayHeader(context),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index < leadingEmptySlots) {
              return const SizedBox.shrink();
            }

            final day = index - leadingEmptySlots + 1;
            final date = DateTime(month.year, month.month, day);

            return _DateCell(
              date: date,
              isSelected: _isSameDate(date, selectedDate),
              onTap: () => onSelect(date),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = _isSameDate(date, DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday ? AppTheme.accentColor : colorScheme.outlineVariant.withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.16 : 0.06),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.black : colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

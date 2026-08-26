import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/models/api_response.dart';
import 'package:tlustudy_planner/models/enrollment.dart';
import 'package:tlustudy_planner/providers/enrollment_provider.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';
import 'package:tlustudy_planner/widgets/styled_dropdown.dart';

/// Màn hình "Đăng ký môn học".
///
/// Dựng lại màn `#/enrollment_newreg` của cổng sinh viên: chọn năm học → học kỳ
/// → đợt đăng ký, xem danh sách môn, mở một môn để thấy các lớp học phần, rồi
/// đăng ký hoặc hủy.
///
/// Khác cổng web ở hai điểm cố ý:
/// - Web xếp môn và lớp thành hai cột; ở đây danh sách môn có thể mở/đóng ngay
///   tại chỗ, vì màn hình điện thoại không đủ rộng cho hai cột.
/// - Hủy đăng ký hỏi xác nhận (giống web), còn đăng ký thì làm ngay.
class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EnrollmentProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EnrollmentProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            // Nút back mặc định của Flutter đã đúng hành vi, chỉ cần tô trắng
            // cho nổi trên nền gradient.
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const TrText(
                'Đăng ký môn học',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: provider.isLoading ? null : provider.refresh,
                tooltip: 'Tải lại',
              ),
            ],
          ),

          SliverToBoxAdapter(child: _buildSelectors(theme, provider)),
          SliverToBoxAdapter(child: _buildStatusBanner(theme, provider)),

          if (provider.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.view.subjects.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(theme, provider),
            )
          else
            _buildSubjectList(theme, provider),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // --- Bộ chọn năm học / học kỳ / đợt -------------------------------------

  Widget _buildSelectors(ThemeData theme, EnrollmentProvider provider) {
    final years = provider.schoolYears;
    final semesters = provider.semesters;
    final periods = provider.periods;

    // Trước khi năm học về, mọi dropdown đều rỗng - hiện chỗ trống còn hơn ba
    // ô vô nghĩa.
    if (years.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Năm học', theme),
          const SizedBox(height: 6),
          StyledDropdownButton<int>(
            value: provider.selectedYearId,
            items: years
                .map(
                  (y) => DropdownMenuItem<int>(
                    value: y.id,
                    child: TrText(
                      y.displayName.isNotEmpty ? y.displayName : y.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: provider.isLoading
                ? null
                : (value) {
                    if (value != null) provider.selectYear(value);
                  },
          ),

          const SizedBox(height: 14),
          _fieldLabel('Giai đoạn năm học', theme),
          const SizedBox(height: 6),
          StyledDropdownButton<int>(
            value: provider.selectedSemesterId,
            hint: 'Chưa có học kỳ',
            items: semesters
                .map(
                  (s) => DropdownMenuItem<int>(
                    value: s.id,
                    child: TrText(
                      _semesterLabel(s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: provider.isLoading || semesters.isEmpty
                ? null
                : (value) {
                    if (value != null) provider.selectSemester(value);
                  },
          ),

          const SizedBox(height: 14),
          _fieldLabel('Đợt đăng ký', theme),
          const SizedBox(height: 6),
          StyledDropdownButton<int>(
            value: provider.selectedPeriodId,
            hint: 'Chưa có đợt đăng ký',
            items: periods
                .map(
                  (p) => DropdownMenuItem<int>(
                    value: p.id,
                    child: TrText(p.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: provider.isLoading || periods.isEmpty
                ? null
                : (value) {
                    if (value != null) provider.selectPeriod(value);
                  },
          ),
        ],
      ),
    );
  }

  /// Kỳ hiển thị theo mã ("1_2026_2027") vì đó là thứ sinh viên quen nhìn trên
  /// cổng; rơi về tên nếu mã trống.
  String _semesterLabel(Semester s) {
    if (s.semesterCode.isNotEmpty) return s.semesterCode;
    if (s.semesterName.isNotEmpty) return s.semesterName;
    return 'Học kỳ ${s.id}';
  }

  Widget _fieldLabel(String text, ThemeData theme) {
    return TrText(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // --- Dải trạng thái đợt -------------------------------------------------

  /// Cho biết đợt đang mở hay đã đóng, kèm mốc thời gian và số tín chỉ đã đăng ký.
  Widget _buildStatusBanner(ThemeData theme, EnrollmentProvider provider) {
    final view = provider.view;
    if (provider.isLoading || view.subjects.isEmpty) {
      return const SizedBox.shrink();
    }

    final open = view.allowRegister;
    final color = open ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            open ? Icons.lock_open_rounded : Icons.lock_clock_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrText(
                  open ? 'Đợt đăng ký đang mở' : 'Ngoài thời gian đăng ký',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (view.windowLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    view.windowLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                // Không hiện số tín chỉ: payload của màn đăng ký trả
                // `numberOfCredit = 0` cho mọi lớp, nên con số đó vô nghĩa.
                TrText(
                  'Đã đăng ký ${view.registeredCount} môn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Danh sách môn ------------------------------------------------------

  Widget _buildSubjectList(ThemeData theme, EnrollmentProvider provider) {
    final subjects = provider.view.subjects;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final subject = subjects[index];
        final isOpen = provider.selectedSubjectName == subject.subjectName;
        return _buildSubjectCard(theme, provider, subject, isOpen);
      }, childCount: subjects.length),
    );
  }

  Widget _buildSubjectCard(
    ThemeData theme,
    EnrollmentProvider provider,
    EnrollmentSubject subject,
    bool isOpen,
  ) {
    final registered = subject.isRegistered;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: registered
              ? AppTheme.primaryColor.withOpacity(0.5)
              : theme.colorScheme.outlineVariant,
          width: registered ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => provider.selectSubject(subject.subjectName),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    registered
                        ? Icons.check_circle_rounded
                        : Icons.menu_book_rounded,
                    color: registered
                        ? AppTheme.primaryColor
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.subjectName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        TrText(
                          registered
                              ? 'Đã đăng ký · ${subject.registeredClass?.code ?? ''}'
                              : '${subject.classes.length} lớp học phần',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: registered
                                ? AppTheme.primaryColor
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AnimatedSize + AnimatedSwitcher: mở/đóng trượt mượt thay vì giật
          // một nhịp khi danh sách lớp xuất hiện.
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isOpen
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      if (subject.dependSubjectNames.isNotEmpty)
                        _buildWarningRow(
                          theme,
                          'Môn tiên quyết: ${subject.dependSubjectNames.join(', ')}',
                        ),
                      ...subject.classes.map(
                        (c) => _buildClassRow(theme, provider, subject, c),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningRow(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFBBF24).withOpacity(0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Một lớp học phần ---------------------------------------------------

  Widget _buildClassRow(
    ThemeData theme,
    EnrollmentProvider provider,
    EnrollmentSubject subject,
    CourseClass courseClass,
  ) {
    final selected = courseClass.isSelected;
    final busy = provider.busyClassId == courseClass.id;

    // Lý do khóa ô chọn, theo đúng thứ tự ưu tiên của cổng: hết đợt → lớp đầy
    // → không cho hủy. `null` nghĩa là bấm được.
    final String? blockedReason = () {
      if (!provider.canRegister) return 'Ngoài thời gian đăng ký của đợt này.';
      if (selected) {
        // Chỉ xét cờ theo môn. Cờ `isAllowUnRegister` ở cấp đợt trả `false`
        // ngay cả khi cổng vẫn cho hủy bình thường (đã kiểm chứng: hủy thành
        // công trong lúc cờ đó là false), nên dùng nó sẽ khóa nhầm nút.
        return subject.isAllowSubjectUnRegister
            ? null
            : 'Môn này không cho phép hủy đăng ký.';
      }
      if (courseClass.isFull) return 'Lớp đã đủ số lượng sinh viên.';
      return null;
    }();

    final enabled = blockedReason == null && !busy;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryColor.withOpacity(0.06)
            : Colors.transparent,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
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
                    Text(
                      courseClass.code,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _chip(
                          theme,
                          Icons.people_alt_rounded,
                          courseClass.capacityLabel,
                          courseClass.isFull
                              ? const Color(0xFFDC2626)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        if (courseClass.displayTeacher.isNotEmpty)
                          _chip(
                            theme,
                            Icons.person_rounded,
                            courseClass.displayTeacher,
                            theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: busy
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Checkbox(
                        value: selected,
                        onChanged: enabled
                            ? (_) => _onToggle(provider, subject, courseClass)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
              ),
            ],
          ),

          // Thời khóa biểu: mỗi dòng là một khoảng tuần của lớp.
          if (courseClass.timetables.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...courseClass.timetables.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [
                          t.dayLabel,
                          t.hourLabel,
                          if (t.roomName.isNotEmpty) t.roomName,
                          if (t.weekLabel.isNotEmpty) t.weekLabel,
                        ].where((e) => e.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (courseClass.isOverlapTime && !selected) ...[
            const SizedBox(height: 6),
            TrText(
              'Lớp này trùng lịch với môn đã đăng ký',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],

          if (blockedReason != null) ...[
            const SizedBox(height: 6),
            TrText(
              blockedReason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
                fontStyle: FontStyle.italic,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  // --- Thao tác -----------------------------------------------------------

  /// Bấm ô chọn: chưa đăng ký thì đăng ký ngay, đã đăng ký thì hỏi trước khi hủy.
  ///
  /// Đây đúng hành vi của cổng - và hợp lý, vì hủy nhầm giữa đợt cao điểm là
  /// mất chỗ thật.
  Future<void> _onToggle(
    EnrollmentProvider provider,
    EnrollmentSubject subject,
    CourseClass courseClass,
  ) async {
    if (courseClass.isSelected) {
      final confirmed = await _confirmUnregister(courseClass);
      if (!confirmed || !mounted) return;

      final error = await provider.unregister(courseClass);
      if (!mounted) return;
      if (error == null) {
        showAppSnackBar(
          context,
          'Đã hủy đăng ký ${courseClass.code}',
          tone: SnackTone.success,
        );
      } else {
        showAppSnackBar(context, error, tone: SnackTone.error);
      }
      return;
    }

    // Trùng lịch không chặn hẳn - cổng vẫn cho đăng ký - nhưng phải hỏi.
    if (courseClass.isOverlapTime) {
      final proceed = await _confirmOverlap(courseClass);
      if (!proceed || !mounted) return;
    }

    final error = await provider.register(courseClass);
    if (!mounted) return;
    if (error == null) {
      showAppSnackBar(
        context,
        'Đã đăng ký ${subject.subjectName} - lớp ${courseClass.code}',
        tone: SnackTone.success,
      );
    } else {
      showAppSnackBar(context, error, tone: SnackTone.error);
    }
  }

  Future<bool> _confirmUnregister(CourseClass courseClass) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const TrText('Hủy đăng ký'),
        content: TrText(
          'Bạn có thực sự muốn hủy đăng ký lớp học phần '
          '${courseClass.code} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TrText('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TrText('Có'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmOverlap(CourseClass courseClass) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const TrText('Trùng lịch học'),
        content: TrText(
          'Lớp ${courseClass.code} trùng lịch với môn bạn đã đăng ký. '
          'Vẫn tiếp tục đăng ký?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TrText('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TrText('Vẫn đăng ký'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // --- Trạng thái rỗng ----------------------------------------------------

  Widget _buildEmptyState(ThemeData theme, EnrollmentProvider provider) {
    final message = provider.error ?? 'Đợt này chưa có môn nào để đăng ký.';
    final isError =
        provider.error != null && !message.contains('chưa có môn nào');

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.event_busy_rounded,
            size: 56,
            color: theme.colorScheme.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 16),
          TrText(
            isError ? 'Không tải được dữ liệu' : 'Chưa có môn để đăng ký',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TrText(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: provider.isLoading ? null : provider.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const TrText('Thử lại'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/enrollment_screen.dart';
import 'package:tlustudy_planner/screens/utility_section_screen.dart';
import 'package:tlustudy_planner/theme/app_theme.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';

/// Trang chủ của "Tiện ích": một lưới thẻ, mỗi thẻ mở một trang riêng.
///
/// Trước đây đây là một trang bốn tab cuộn ngang, nên mục thứ tư gần như không
/// ai thấy và không còn chỗ để thêm mục mới. Dạng lưới thẻ hiển thị mọi mục
/// cùng lúc và thêm mục chỉ là thêm một phần tử vào [_entries].
class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  /// Các tiện ích, theo thứ tự hiển thị.
  ///
  /// "Đăng ký môn học" đứng đầu vì nó có tính thời điểm - chỉ dùng được trong
  /// đợt mở đăng ký, và khi đó là việc gấp nhất.
  static const List<_UtilityEntry> _entries = [
    _UtilityEntry(
      title: 'Đăng ký môn học',
      subtitle: 'Đăng ký, hủy lớp học phần theo đợt',
      icon: Icons.app_registration_rounded,
      color: Color(0xFF2563EB),
      highlight: true,
    ),
    _UtilityEntry(
      title: 'Điểm số',
      subtitle: 'Bảng điểm và GPA tích lũy',
      icon: Icons.grade_rounded,
      color: Color(0xFF7C3AED),
      section: UtilitySection.marks,
    ),
    _UtilityEntry(
      title: 'Rèn luyện',
      subtitle: 'Điểm rèn luyện từng kỳ',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFEA580C),
      section: UtilitySection.behavior,
    ),
    _UtilityEntry(
      title: 'Học phí',
      subtitle: 'Khoản thu và thanh toán',
      icon: Icons.payment_rounded,
      color: Color(0xFF059669),
      section: UtilitySection.tuition,
    ),
    _UtilityEntry(
      title: 'Chương trình đào tạo',
      subtitle: 'Khối kiến thức và tiến độ',
      icon: Icons.account_tree_rounded,
      color: Color(0xFF0891B2),
      section: UtilitySection.program,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: const TrText(
                'Tiện ích',
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
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrText(
                          userProvider.tluUser?.displayName ?? 'Sinh viên',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TrText(
                          'Chọn một tiện ích để xem chi tiết',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                // Hai cột trên điện thoại, ba cột khi máy đủ rộng (tablet, xoay
                // ngang) - thẻ giữ nguyên tỉ lệ thay vì kéo dài ra.
                final width = constraints.crossAxisExtent;
                final columns = width >= 600 ? 3 : 2;

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _UtilityCard(entry: _entries[index]),
                    childCount: _entries.length,
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// Mô tả một thẻ tiện ích.
///
/// [section] rỗng nghĩa là thẻ mở một màn hình riêng chứ không phải một mục
/// của [UtilitySectionScreen] - hiện chỉ có "Đăng ký môn học".
class _UtilityEntry {
  const _UtilityEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.section,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final UtilitySection? section;

  /// Vẽ viền đậm hơn để thẻ nổi lên khỏi lưới.
  final bool highlight;
}

/// Thẻ bo góc bốn cạnh, lún xuống khi nhấn giữ.
class _UtilityCard extends StatefulWidget {
  const _UtilityCard({required this.entry});

  final _UtilityEntry entry;

  @override
  State<_UtilityCard> createState() => _UtilityCardState();
}

class _UtilityCardState extends State<_UtilityCard> {
  bool _pressed = false;

  void _open() {
    final section = widget.entry.section;
    pushSlideUp(
      context,
      section == null
          ? const EnrollmentScreen()
          : UtilitySectionScreen(section: section),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    return GestureDetector(
      onTap: _open,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        // Lún nhẹ khi nhấn để cú chạm có phản hồi ngay, trước cả khi trang mới
        // bắt đầu trượt lên.
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: entry.highlight
                  ? entry.color.withOpacity(0.55)
                  : theme.colorScheme.outlineVariant,
              width: entry.highlight ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: entry.color.withOpacity(_pressed ? 0.02 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: entry.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(entry.icon, color: entry.color, size: 24),
              ),
              const Spacer(),
              TrText(
                entry.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              TrText(
                entry.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11.5,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

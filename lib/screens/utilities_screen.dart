import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/documents_screen.dart';
import 'package:tlustudy_planner/screens/enrollment_screen.dart';
import 'package:tlustudy_planner/screens/utility_section_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';

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
      destination: UtilityDestination.enrollment,
      highlight: true,
    ),
    _UtilityEntry(
      title: 'Đơn từ',
      subtitle: 'Tạo, nộp và tra cứu đơn',
      icon: Icons.description_rounded,
      color: Color(0xFFDB2777),
      destination: UtilityDestination.documents,
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
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Cùng một kiểu tiêu đề với Trang chủ và Lịch học: chữ lớn nằm
            // thẳng trên nền trang thay vì dải gradient của bản cũ.
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'Tiện ích',
                subtitle: 'Chọn một tiện ích để xem chi tiết',
                // trailing: HeaderAvatar(
                //   name: userProvider.tluUser?.displayName ?? 'Sinh viên',
                // ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  // Hai cột trên điện thoại, ba cột khi máy đủ rộng (tablet,
                  // xoay ngang) - thẻ giữ nguyên tỉ lệ thay vì kéo dài ra.
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

            SliverToBoxAdapter(
              child: SizedBox(height: FloatingNavBar.bottomInset(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình riêng mà một thẻ có thể mở, khi thẻ đó không phải là một mục của
/// [UtilitySectionScreen].
enum UtilityDestination { enrollment, documents }

/// Mô tả một thẻ tiện ích.
///
/// Một thẻ mở *hoặc* một mục của [UtilitySectionScreen] ([section]), *hoặc*
/// một màn hình riêng ([destination]) - đúng một trong hai, không bao giờ cả
/// hai cùng rỗng.
class _UtilityEntry {
  const _UtilityEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.section,
    this.destination,
    this.highlight = false,
  }) : assert(
         (section == null) != (destination == null),
         'Mỗi thẻ mở đúng một đích đến',
       );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final UtilitySection? section;

  /// Màn hình riêng, khi thẻ không thuộc [UtilitySectionScreen].
  final UtilityDestination? destination;

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
    final entry = widget.entry;
    final section = entry.section;
    if (section != null) {
      pushSlide(context, UtilitySectionScreen(section: section));
      return;
    }
    switch (entry.destination!) {
      case UtilityDestination.enrollment:
        pushSlide(context, const EnrollmentScreen());
      case UtilityDestination.documents:
        pushSlide(context, const DocumentsScreen());
    }
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
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: entry.highlight
                  ? entry.color.withOpacity(0.55)
                  : AppColors.border(context),
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

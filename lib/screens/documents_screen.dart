import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/screens/document_branch_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';

/// "Đơn từ" - nơi đặt các đầu mối làm đơn.
///
/// Hiện chỉ có một thẻ (Phân hiệu), nhưng cơ sở chính và các khoa cũng có quy
/// trình đơn riêng, nên đây là một danh sách chứ không phải trang đích: thêm
/// một nơi nữa chỉ là thêm một thẻ.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeader(
                title: 'Đơn từ',
                subtitle: 'Chọn nơi bạn cần làm đơn',
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.list(
                children: [
                  _PlaceCard(
                    icon: Symbols.account_balance_rounded,
                    color: const Color(0xFF0891B2),
                    title: 'Phân hiệu trường Đại học Thủy Lợi',
                    subtitle:
                        'Xác nhận sinh viên, hoãn NVQS, vay vốn, giấy giới thiệu...',
                    onTap: () =>
                        pushSlide(context, const DocumentBranchScreen()),
                  ),
                ],
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

/// Thẻ một cơ sở, rộng hết bề ngang - tên cơ sở dài nên xếp lưới hai cột thì
/// chữ bị cắt.
class _PlaceCard extends StatefulWidget {
  const _PlaceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.02 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrText(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TrText(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14, left: 6),
                child: Icon(
                  Symbols.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

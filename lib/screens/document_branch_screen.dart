import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/screens/document_form_webview_screen.dart';
import 'package:tlustudy_planner/screens/document_status_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';
import 'package:tlustudy_planner/widgets/detail_sheet.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';

/// Ba bước làm đơn ở Phân hiệu, gom vào một trang.
///
/// Quy trình thật đi qua ba dịch vụ khác nhau - mini app Zalo để soạn đơn,
/// Google Form để ghi danh, Google Sheet để tra kết quả - và trước đây sinh
/// viên phải tự giữ ba đường dẫn đó. Trang này xếp chúng đúng theo thứ tự phải
/// làm, kèm dấu ? ở góc giải thích vì sao lại có ba bước.
class DocumentBranchScreen extends StatelessWidget {
  const DocumentBranchScreen({super.key});

  /// Mini app Zalo "Đơn từ" của Phân hiệu.
  static const String createUrl = 'https://zalo.me/s/2738103329983064239/';

  /// Google Form ghi danh, đã kèm tham số để mở đúng dạng trong ứng dụng.
  static const String enrollUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSc5howRtdwFCj2P_69BwkTlCVXenm4ECb4ek7Kt-BUCDZf2Rw/viewform?typeInapp=1&zarsrc=1303';

  Future<void> _openZalo(BuildContext context) async {
    final uri = Uri.parse(createUrl);
    var opened = false;
    try {
      // externalApplication: đường dẫn zalo.me được chính app Zalo nhận, nên
      // mini app mở thẳng trong Zalo với tài khoản đã đăng nhập sẵn thay vì
      // rơi vào trang giới thiệu trên trình duyệt.
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      // Máy chưa cài Zalo thì vẫn còn bản web.
      try {
        opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && context.mounted) {
      await showAppSnackBar(
        context,
        'Không mở được Zalo. Hãy cài ứng dụng Zalo rồi thử lại.',
        tone: SnackTone.error,
      );
    }
  }

  void _showGuide(BuildContext context) {
    showDetailSheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailSheetHeader(
            icon: Symbols.help_rounded,
            color: AppColors.accent(context),
            title: 'Quy trình tạo đơn',
            subtitle: 'Ba bước, làm lần lượt từ trên xuống',
          ),
          const SizedBox(height: 18),
          const _GuideStep(
            index: 1,
            icon: Symbols.edit_document_rounded,
            title: 'Vào mini app tạo đơn',
            description:
                'Mở mini app "Đơn từ" trên Zalo, chọn loại đơn và điền thông tin. '
                'Mini app sẽ tạo ra bản đơn của bạn.',
          ),
          const _GuideStep(
            index: 2,
            icon: Symbols.how_to_reg_rounded,
            title: 'Ghi danh nộp đơn',
            description:
                'Điền biểu mẫu ghi danh để Phân hiệu biết bạn đã gửi đơn và biết đơn thuộc về ai. '
                'Đơn chưa ghi danh thì sẽ không được vào danh sách xử lý.',
          ),
          const _GuideStep(
            index: 3,
            icon: Symbols.fact_check_rounded,
            title: 'Kiểm tra tình trạng đơn',
            description:
                'Quay lại đây để xem đơn đã được duyệt chưa và khi nào tới lấy. '
                'Phân hiệu nhận đơn vào chiều thứ 3 và chiều thứ 5 hàng tuần.',
            last: true,
          ),
        ],
      ),
    );
  }

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
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'Phân hiệu trường Đại học Thủy Lợi',
                subtitle: 'Làm đơn và tra cứu kết quả',
                actions: [
                  HeaderIconButton(
                    icon: Symbols.help_rounded,
                    tooltip: 'Hướng dẫn quy trình',
                    onTap: () => _showGuide(context),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _ActionCard(
                        step: 1,
                        icon: Symbols.edit_document_rounded,
                        color: const Color(0xFF2563EB),
                        title: 'Tạo đơn',
                        subtitle: 'Soạn đơn trên mini app Zalo của Phân hiệu',
                        trailingIcon: Symbols.open_in_new_rounded,
                        onTap: () => _openZalo(context),
                      );
                    case 1:
                      return _ActionCard(
                        step: 2,
                        icon: Symbols.how_to_reg_rounded,
                        color: const Color(0xFF7C3AED),
                        title: 'Ghi danh nộp đơn',
                        subtitle: 'Điền biểu mẫu để đơn được đưa vào xử lý',
                        onTap: () => DocumentFormWebViewScreen.open(
                          context,
                          url: enrollUrl,
                          title: 'biểu mẫu ghi danh',
                        ),
                      );
                    default:
                      return _ActionCard(
                        step: 3,
                        icon: Symbols.fact_check_rounded,
                        color: const Color(0xFF059669),
                        title: 'Kiểm tra tình trạng đơn',
                        subtitle: 'Xem đơn của bạn đã được duyệt tới đâu',
                        onTap: () =>
                            pushSlide(context, const DocumentStatusScreen()),
                      );
                  }
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

/// Một trong ba mục, kèm số thứ tự bước để đọc là thấy ngay trình tự.
class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = Symbols.chevron_right_rounded,
  });

  final int step;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.02 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  Positioned(
                    top: -5,
                    left: -5,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface(context),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${widget.step}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrText(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    TrText(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.trailingIcon,
                size: 20,
                color: AppColors.textMuted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một bước trong popup hướng dẫn, có vạch nối xuống bước kế tiếp.
class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.description,
    this.last = false,
  });

  final int index;
  final IconData icon;
  final String title;
  final String description;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TrText(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.text(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TrText(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSoft(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tlustudy_planner/widgets/notice_list.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/models/mail_message.dart';
import 'package:tlustudy_planner/providers/mail_provider.dart';
import 'package:tlustudy_planner/screens/mail_detail_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/utils/page_transitions.dart';
import 'package:tlustudy_planner/widgets/calendar_widgets.dart';
import 'package:tlustudy_planner/widgets/empty_state_widget.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';

/// Hai nhóm nội dung của trang Thông báo.
enum NoticeGroup { announcements, mail }

/// Trang Thông báo: thông báo của trường và hộp thư trường, chia bằng hai
/// pill ở đầu trang.
///
/// Mở từ biểu tượng chuông ở Trang chủ, bằng Navigator lồng của khung tab -
/// nhờ vậy thanh điều hướng vẫn nằm trên và tự thu thành nút back.
class NoticeScreen extends StatefulWidget {
  const NoticeScreen({
    super.key,
    this.initialGroup = NoticeGroup.announcements,
  });

  final NoticeGroup initialGroup;

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  late NoticeGroup _group = widget.initialGroup;

  @override
  void initState() {
    super.initState();
    // Vào trang là làm mới ngay, nhưng phải đợi frame đầu: gọi provider giữa
    // initState sẽ notifyListeners trong lúc cây widget đang dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mail = context.read<MailProvider>();
      if (mail.isLinked && !mail.hasLoadedOnce) mail.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Không đặt showBack: trong khung tab, thanh điều hướng nổi tự
            // thu thành nút back khi có trang con - thêm một mũi tên nữa ở
            // đây là hai nút back cho cùng một việc.
            PageHeader(
              title: 'Thông báo',
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              actions: [
                if (_group == NoticeGroup.mail)
                  Consumer<MailProvider>(
                    builder: (context, mail, _) => HeaderIconButton(
                      icon: Symbols.refresh_rounded,
                      tooltip: 'Tải lại',
                      onTap: mail.isLinked && !mail.isLoading
                          ? () => mail.refresh()
                          : null,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: SegmentedPill<NoticeGroup>(
                value: _group,
                onChanged: (value) => setState(() => _group = value),
                segments: const [
                  SegmentItem(
                    value: NoticeGroup.announcements,
                    label: 'Thông báo',
                    icon: Symbols.campaign_rounded,
                  ),
                  SegmentItem(
                    value: NoticeGroup.mail,
                    label: 'Mail',
                    icon: Symbols.mail_rounded,
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _group == NoticeGroup.announcements ? 0 : 1,
                children: const [NoticeList(), _MailListView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhóm "Mail": chưa liên kết thì mời liên kết, đã liên kết thì hiện danh
/// sách thẻ.
class _MailListView extends StatelessWidget {
  const _MailListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<MailProvider>(
      builder: (context, mail, _) {
        final bottomInset = FloatingNavBar.bottomInset(context);

        if (!mail.isLinked) {
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: EmptyStateWidget(
              icon: Symbols.link_off_rounded,
              title: 'Vui lòng liên kết email',
              description:
                  'Liên kết hộp thư @tlu.edu.vn để xem thông báo qua email '
                  'ngay trong ứng dụng.',
              action: FilledButton.icon(
                onPressed: mail.isLinking
                    ? null
                    : () async {
                        final ok = await mail.link();
                        if (!context.mounted) return;
                        if (!ok && mail.error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(mail.error!)));
                        }
                      },
                icon: mail.isLinking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Symbols.link_rounded),
                label: TrText(
                  mail.isLinking ? 'Đang liên kết...' : 'Liên kết email',
                ),
              ),
            ),
          );
        }

        if (mail.isLoading && mail.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mail.messages.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => mail.refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                EmptyStateWidget(
                  icon: mail.error != null
                      ? Symbols.error_rounded
                      : Symbols.inbox_rounded,
                  title: mail.error != null
                      ? 'Không tải được thư'
                      : 'Hộp thư trống',
                  description:
                      mail.error ?? 'Chưa có thư nào trong hộp thư đến.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => mail.refresh(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
            itemCount: mail.messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final message = mail.messages[i];
              return MailCard(
                message: message,
                onTap: () {
                  mail.markReadLocally(message.id);
                  pushSlide(context, MailDetailScreen(message: message));
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Thẻ một thư trong danh sách.
///
/// Chưa đọc được nhấn mạnh ba lớp chứ không chỉ bằng chấm màu: chấm, tiêu đề
/// đậm, và viền màu nhấn. Chỉ dựa vào màu thôi thì người mù màu không phân
/// biệt được đã đọc với chưa đọc.
class MailCard extends StatelessWidget {
  const MailCard({super.key, required this.message, required this.onTap});

  final MailMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = message.isUnread;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: unread
                ? AppColors.accentTint(context)
                : AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: unread
                  ? AppColors.accent(context).withValues(alpha: 0.35)
                  : AppColors.border(context),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SenderAvatar(message: message),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.displaySender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: unread
                                  ? AppColors.text(context)
                                  : AppColors.textSoft(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _shortTime(message.receivedAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message.displaySubject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.text(context),
                      ),
                    ),
                    if (message.preview.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message.preview.replaceAll(RegExp(r'\s+'), ' ').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                    if (message.hasAttachments) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Symbols.attach_file_rounded,
                            size: 14,
                            weight: 600,
                            color: AppColors.textMuted(context),
                          ),
                          const SizedBox(width: 4),
                          TrText(
                            'Có tệp đính kèm',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hôm nay thì hiện giờ, trong tuần hiện thứ, xa hơn thì hiện ngày.
  String _shortTime(DateTime at) {
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    if (sameDay) {
      return '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}';
    }
    final diff = now.difference(at).inDays;
    if (diff < 7) {
      const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return names[at.weekday - 1];
    }
    return '${at.day}/${at.month}';
  }
}

/// Vòng tròn chữ cái đầu của người gửi, kèm chấm "chưa đọc" ở góc.
class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.message});

  final MailMessage message;

  @override
  Widget build(BuildContext context) {
    final unread = message.isUnread;

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unread
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.accentGradient(context),
                    )
                  : null,
              color: unread ? null : AppColors.surfaceAlt(context),
              border: unread
                  ? null
                  : Border.all(color: AppColors.border(context)),
            ),
            child: Center(
              child: Text(
                message.senderInitial,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: unread ? Colors.white : AppColors.textSoft(context),
                ),
              ),
            ),
          ),
          if (unread)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent(context),
                  border: Border.all(
                    color: AppColors.accentTint(context),
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

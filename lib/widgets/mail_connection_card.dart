import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/providers/mail_provider.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';
import 'package:tlustudy_planner/widgets/cupertino_widgets.dart';

/// Thẻ "Email trường" trong Cài đặt → Kết nối.
///
/// Ba trạng thái: chưa cấu hình (bản build thiếu client ID), chưa liên kết,
/// và đã liên kết. Việc liên kết chỉ xảy ra đúng một lần - sau đó refresh
/// token nằm trong keystore lo phần còn lại, nên ở đây chỉ còn nút huỷ.
class MailConnectionCard extends StatelessWidget {
  const MailConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<MailProvider>(
      builder: (context, mail, _) {
        final linked = mail.isLinked;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: linked
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        linked
                            ? Symbols.mark_email_read_rounded
                            : Symbols.alternate_email_rounded,
                        color: linked
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrText(
                            'Email trường',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          // Địa chỉ email là dữ liệu, không dịch.
                          linked
                              ? Text(
                                  mail.account ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                )
                              : TrText(
                                  'Chưa liên kết',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TrText(
                  linked
                      ? 'Ứng dụng chỉ đọc thư, không gửi và không trả lời thay bạn.'
                      : 'Đăng nhập một lần bằng tài khoản @tlu.edu.vn để đọc '
                          'thông báo qua email ngay trong ứng dụng. Ứng dụng '
                          'chỉ xin quyền đọc thư.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (!mail.isConfigured) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TrText(
                            'Bản cài đặt này chưa được cấu hình kết nối email.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (linked) ...[
                  // Thông báo thư mới chỉ có nghĩa khi đã liên kết.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TrText(
                              'Thông báo thư mới',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            TrText(
                              'Báo khi có thư chưa đọc mới trong hộp thư đến',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: mail.notifyNewMail,
                        onChanged: (value) => mail.setNotifyNewMail(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Huỷ liên kết',
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: () => _confirmUnlink(context, mail),
                  ),
                ] else
                  AppButton(
                    label: mail.isLinking
                        ? 'Đang liên kết...'
                        : 'Liên kết email trường',
                    variant: AppButtonVariant.primary,
                    expand: true,
                    onPressed: mail.isLinking || !mail.isConfigured
                        ? null
                        : () async {
                            final ok = await mail.link();
                            if (!context.mounted) return;
                            showAppSnackBar(
                              context,
                              ok
                                  ? 'Đã liên kết ${mail.account}'
                                  : (mail.error ?? 'Đã huỷ liên kết email'),
                              tone: ok ? SnackTone.success : SnackTone.warning,
                            );
                          },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Huỷ liên kết là thao tác không lấy lại được bằng một cú chạm (phải đăng
  /// nhập lại), nên hỏi trước.
  Future<void> _confirmUnlink(BuildContext context, MailProvider mail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const TrText('Huỷ liên kết email?'),
        content: const TrText(
          'Ứng dụng sẽ xoá phiên đăng nhập email khỏi thiết bị. '
          'Bạn có thể liên kết lại bất cứ lúc nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const TrText('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const TrText('Huỷ liên kết'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await mail.unlink();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      'Đã huỷ liên kết email',
      tone: SnackTone.success,
    );
  }
}

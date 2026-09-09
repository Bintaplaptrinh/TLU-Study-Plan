import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tlustudy_planner/config/app_info.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/services/update_service.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';

/// Hộp thoại "có bản mới": xem mô tả, tải, rồi giao cho trình cài đặt.
///
/// Cả ba việc nằm trong cùng một hộp thoại chứ không tách thành nhiều màn
/// hình, vì đây là một mạch việc ngắn mà người dùng sẽ không quay lại giữa
/// chừng - và vì thanh tiến trình phải nằm ngay dưới nút vừa được bấm.
Future<void> showUpdateDialog(
  BuildContext context,
  AppRelease release, {
  /// Cho phép "Bỏ qua bản này". Chỉ có nghĩa khi hộp thoại tự bật lên; người
  /// dùng chủ động bấm "Kiểm tra cập nhật" thì không cần lựa chọn đó.
  bool allowSkip = false,
}) {
  return showDialog<void>(
    context: context,
    // Không cho đóng bằng cách chạm ra ngoài *trong lúc đang tải*: việc chặn
    // đó nằm trong PopScope bên dưới, còn ở trạng thái nghỉ thì đóng thoải mái.
    barrierDismissible: true,
    builder: (_) => _UpdateDialog(release: release, allowSkip: allowSkip),
  );
}

/// Kiểm tra cập nhật do người dùng bấm: hiện vòng quay, rồi báo kết quả dù có
/// bản mới hay không. Im lặng khi không có gì mới là cách nhanh nhất khiến
/// người dùng nghĩ nút bị hỏng.
Future<void> runInteractiveUpdateCheck(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    final release = await UpdateService.instance.checkNow();
    if (!context.mounted) return;

    if (release == null) {
      messenger.hideCurrentSnackBar();
      await showAppSnackBar(
        context,
        'Bạn đang dùng phiên bản mới nhất (${AppInfo.version})',
        tone: SnackTone.success,
      );
      return;
    }

    await showUpdateDialog(context, release);
  } on UpdateException catch (e) {
    if (!context.mounted) return;
    await showAppSnackBar(context, e.message, tone: SnackTone.error);
  } catch (e) {
    if (!context.mounted) return;
    await showAppSnackBar(
      context,
      'Không kiểm tra được cập nhật',
      tone: SnackTone.error,
    );
  }
}

enum _Phase { idle, downloading, installing, failed }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.release, required this.allowSkip});

  final AppRelease release;
  final bool allowSkip;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  _Phase _phase = _Phase.idle;
  CancelToken? _cancelToken;

  int _received = 0;
  int _total = 0;
  String? _error;

  /// Đã tải xong ít nhất một lần: nút chuyển thành "Cài đặt" để bấm lại được
  /// nếu người dùng lỡ tắt màn hình xin quyền của hệ thống.
  File? _downloaded;

  @override
  void dispose() {
    _cancelToken?.cancel('dialog disposed');
    super.dispose();
  }

  double? get _progress {
    if (_total <= 0) return null; // máy chủ không gửi Content-Length
    return (_received / _total).clamp(0.0, 1.0);
  }

  Future<void> _start() async {
    final existing = _downloaded;
    if (existing != null && await existing.exists()) {
      await _install(existing);
      return;
    }

    final token = CancelToken();
    setState(() {
      _phase = _Phase.downloading;
      _error = null;
      _received = 0;
      _total = widget.release.apkSize;
      _cancelToken = token;
    });

    try {
      final file = await UpdateService.instance.downloadApk(
        widget.release,
        cancelToken: token,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            if (total > 0) _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() => _downloaded = file);
      await _install(file);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (mounted) setState(() => _phase = _Phase.idle);
        return;
      }
      _fail('Tải bản cập nhật thất bại');
    } on UpdateException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Đã xảy ra lỗi khi tải bản cập nhật');
    } finally {
      _cancelToken = null;
    }
  }

  Future<void> _install(File file) async {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.installing;
      _error = null;
    });

    try {
      await UpdateService.instance.installApk(file);
      // Trình cài đặt của hệ thống đã lên trước mặt người dùng. Ứng dụng này
      // sắp bị thay thế, nên không có gì để làm tiếp - đóng hộp thoại lại,
      // giữ nguyên tệp đã tải phòng khi người dùng huỷ rồi muốn cài lại.
      if (mounted) Navigator.of(context).pop();
    } on UpdateException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Không mở được trình cài đặt');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _error = message;
    });
  }

  void _cancelDownload() {
    _cancelToken?.cancel('user cancelled');
    setState(() => _phase = _Phase.idle);
  }

  Future<void> _skip() async {
    await UpdateService.instance.skipVersion(
      widget.release.version.canonical,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final busy = _phase == _Phase.downloading || _phase == _Phase.installing;

    return PopScope(
      // Đang tải dở mà bấm back thì tệp tải sẽ bị bỏ lửng ngầm; buộc người
      // dùng bấm "Huỷ" để việc dừng lại là một quyết định rõ ràng.
      canPop: !busy,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: _buildTitle(context),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380, maxWidth: 420),
          child: _buildContent(context),
        ),
        actions: _buildActions(context),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Symbols.system_update_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrText(
                'Đã có bản cập nhật',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${AppInfo.version}  →  ${widget.release.version}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (_phase) {
      case _Phase.downloading:
        final progress = _progress;
        final percent = progress == null
            ? null
            : (progress * 100).toStringAsFixed(0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrText(
              'Đang tải bản cập nhật',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  percent == null ? '' : '$percent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  _total > 0
                      ? '${formatBytes(_received)} / ${formatBytes(_total)}'
                      : formatBytes(_received),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );

      case _Phase.installing:
        return Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TrText(
                'Đang mở trình cài đặt của hệ thống',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );

      case _Phase.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TrText(
                    _error ?? 'Đã xảy ra lỗi',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _permissionHint(context),
          ],
        );

      case _Phase.idle:
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metaLine(context),
              const SizedBox(height: 14),
              if (widget.release.notes.isNotEmpty) ...[
                TrText(
                  'Có gì mới',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _tidyNotes(widget.release.notes),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _permissionHint(context),
            ],
          ),
        );
    }
  }

  Widget _metaLine(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final published = widget.release.publishedAt;
    final bits = <String>[
      if (published != null)
        '${published.day.toString().padLeft(2, '0')}-'
            '${published.month.toString().padLeft(2, '0')}-'
            '${published.year}',
      if (widget.release.readableSize.isNotEmpty) widget.release.readableSize,
    ];
    if (bits.isEmpty) return const SizedBox.shrink();

    return Text(
      bits.join('  ·  '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Nhắc trước về quyền cài đặt: trên Android 8 trở lên, trình cài đặt sẽ
  /// dừng lại xin quyền, và người dùng không đoán được đó là bước bình thường
  /// nếu không được báo trước.
  Widget _permissionHint(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Symbols.shield_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrText(
                  'Android sẽ hỏi quyền cài ứng dụng từ nguồn này. '
                  'Hãy chọn Cho phép rồi quay lại để cài tiếp.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed:
                  UpdateService.instance.openInstallPermissionSettings,
              child: const TrText('Mở cài đặt quyền'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    switch (_phase) {
      case _Phase.downloading:
        return [
          TextButton(
            onPressed: _cancelDownload,
            child: const TrText('Huỷ'),
          ),
        ];

      case _Phase.installing:
        return const [];

      case _Phase.failed:
        return [
          TextButton(
            onPressed: () => _openReleasePage(context),
            child: const TrText('Tải thủ công'),
          ),
          FilledButton(
            onPressed: _start,
            child: const TrText('Thử lại'),
          ),
        ];

      case _Phase.idle:
        return [
          if (widget.allowSkip)
            TextButton(
              onPressed: _skip,
              child: const TrText('Bỏ qua bản này'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const TrText('Để sau'),
          ),
          FilledButton(
            onPressed: _start,
            child: TrText(
              _downloaded == null ? 'Cập nhật ngay' : 'Cài đặt',
            ),
          ),
        ];
    }
  }

  Future<void> _openReleasePage(BuildContext context) async {
    final uri = Uri.parse(widget.release.pageUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        await showAppSnackBar(
          context,
          'Không mở được trình duyệt',
          tone: SnackTone.error,
        );
      }
    }
  }
}

/// GitHub tự sinh phần mô tả kèm tiêu đề Markdown và đường dẫn so sánh ở
/// cuối. Hộp thoại này hiển thị văn bản thuần, nên gọt bớt để phần còn lại
/// đọc được: bỏ dấu `#`, bỏ dòng "Full Changelog", và cắt cho vừa một hộp
/// thoại thay vì cuộn mãi.
String _tidyNotes(String raw) {
  final lines = raw.split('\n');
  final kept = <String>[];

  for (final line in lines) {
    final trimmed = line.trimRight();
    if (trimmed.trim().isEmpty) {
      if (kept.isNotEmpty && kept.last.isNotEmpty) kept.add('');
      continue;
    }
    if (trimmed.startsWith('**Full Changelog')) continue;
    kept.add(trimmed.replaceFirst(RegExp(r'^#{1,6}\s*'), ''));
  }

  var text = kept.join('\n').trim();
  if (text.length > 1200) {
    text = '${text.substring(0, 1200).trimRight()}…';
  }
  return text;
}

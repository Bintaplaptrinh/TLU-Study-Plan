import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/models/mail_message.dart';
import 'package:tlustudy_planner/providers/mail_provider.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/widgets/app_snackbar.dart';
import 'package:tlustudy_planner/widgets/floating_nav_bar.dart';
import 'package:tlustudy_planner/widgets/page_header.dart';

/// Nội dung một thư: tiêu đề, người gửi, thân thư, và tệp đính kèm.
///
/// Chỉ đọc - không có trả lời, chuyển tiếp hay xoá, đúng phạm vi `Mail.Read`
/// mà ứng dụng xin.
class MailDetailScreen extends StatefulWidget {
  const MailDetailScreen({super.key, required this.message});

  /// Bản rút gọn từ danh sách; thân thư được tải lại khi mở trang.
  final MailMessage message;

  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  MailMessage? _full;
  List<MailAttachment> _attachments = const <MailAttachment>[];
  bool _loading = true;
  String? _error;

  /// Tệp đang tải, để hiện vòng quay trên đúng thẻ đính kèm.
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mail = context.read<MailProvider>();
    try {
      final full = await mail.loadMessage(widget.message.id);
      // Đính kèm là một lời gọi riêng của Graph; thư không có đính kèm thì
      // khỏi gọi cho tốn một vòng mạng.
      final attachments = full.hasAttachments
          ? await mail.loadAttachments(widget.message.id)
          : const <MailAttachment>[];

      if (!mounted) return;
      setState(() {
        _full = full;
        _attachments = attachments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _full ?? widget.message;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const PageHeader(
              title: 'Nội dung thư',
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  FloatingNavBar.bottomInset(context) + 16,
                ),
                children: [
                  _headerCard(context, message),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _errorCard(context)
                  else ...[
                    _bodyCard(context, message),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _attachmentsCard(context),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Khối tiêu đề ────────────────────────────────────────────────────────

  Widget _headerCard(BuildContext context, MailMessage message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.displaySubject,
            style: TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.accentGradient(context),
                  ),
                ),
                child: Center(
                  child: Text(
                    message.senderInitial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.displaySender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                    if (message.senderAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message.senderAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Symbols.schedule_rounded,
                size: 15,
                weight: 600,
                color: AppColors.textMuted(context),
              ),
              const SizedBox(width: 5),
              Text(
                _fullTime(message.receivedAt),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Thân thư ────────────────────────────────────────────────────────────

  Widget _bodyCard(BuildContext context, MailMessage message) {
    final html = message.bodyHtml;
    final text = message.bodyText ?? message.preview;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: html != null && html.trim().isNotEmpty
          ? _MailHtmlBody(html: html)
          : Padding(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                text.trim().isEmpty ? '(Thư không có nội dung)' : text,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: AppColors.text(context),
                ),
              ),
            ),
    );
  }

  Widget _errorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.error_rounded,
            size: 32,
            color: AppColors.danger(context),
          ),
          const SizedBox(height: 10),
          TrText(
            'Không tải được nội dung thư',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
            icon: const Icon(Symbols.refresh_rounded),
            label: const TrText('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ── Đính kèm ────────────────────────────────────────────────────────────

  Widget _attachmentsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.attach_file_rounded,
                size: 18,
                weight: 600,
                color: AppColors.accent(context),
              ),
              const SizedBox(width: 7),
              TrText(
                'Tệp đính kèm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${_attachments.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final attachment in _attachments) ...[
            _attachmentRow(context, attachment),
            if (attachment != _attachments.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _attachmentRow(BuildContext context, MailAttachment attachment) {
    final busy = _downloadingId == attachment.id;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: attachment.isFile && !busy
            ? () => _openAttachment(attachment)
            : null,
        child: Ink(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt(context),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentTint(context),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _iconFor(attachment.extension),
                  size: 19,
                  weight: 600,
                  color: AppColors.accent(context),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                    if (attachment.readableSize.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        attachment.readableSize,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  attachment.isFile
                      ? Symbols.download_rounded
                      : Symbols.block_rounded,
                  size: 19,
                  weight: 600,
                  color: attachment.isFile
                      ? AppColors.accent(context)
                      : AppColors.textMuted(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(MailAttachment attachment) async {
    setState(() => _downloadingId = attachment.id);
    try {
      final path = await context
          .read<MailProvider>()
          .downloadAttachment(widget.message.id, attachment);

      if (!mounted) return;
      final result = await OpenFilex.open(path);

      if (!mounted) return;
      if (result.type != ResultType.done) {
        // Không có app nào mở được định dạng này - nói rõ chứ đừng im lặng,
        // tệp đã tải về rồi.
        showAppSnackBar(
          context,
          'Không có ứng dụng nào mở được tệp này',
          tone: SnackTone.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Không tải được tệp: $e', tone: SnackTone.error);
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  IconData _iconFor(String extension) {
    switch (extension) {
      case 'pdf':
        return Symbols.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Symbols.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Symbols.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Symbols.slideshow_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return Symbols.image_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Symbols.folder_zip_rounded;
      default:
        return Symbols.draft_rounded;
    }
  }

  String _fullTime(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)} · '
        '${two(at.day)}/${two(at.month)}/${at.year}';
  }
}

/// Thân thư HTML dựng trong WebView.
///
/// Thư của trường hay có bảng, ảnh chữ ký và bố cục nhiều cột - dựng lại bằng
/// widget Flutter thì gãy hết. WebView tắt JavaScript (thư là nội dung không
/// tin cậy được) và tự cao bằng đúng nội dung để nằm gọn trong trang cuộn.
class _MailHtmlBody extends StatefulWidget {
  const _MailHtmlBody({required this.html});

  final String html;

  @override
  State<_MailHtmlBody> createState() => _MailHtmlBodyState();
}

class _MailHtmlBodyState extends State<_MailHtmlBody> {
  late final WebViewController _controller;
  late final double _height;

  @override
  void initState() {
    super.initState();

    // JavaScript tắt nên không đo được chiều cao thật của nội dung. Ước lượng
    // từ độ dài phần chữ (bỏ thẻ) rồi kẹp trong khoảng hợp lý: thư ngắn không
    // để lại khoảng trắng mênh mông, thư dài thì phần dư tự cuộn trong khung.
    final plain = widget.html.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    _height = (160 + plain.length * 0.42).clamp(180.0, 900.0).toDouble();

    final isDark = WidgetsBinding.instance.platformDispatcher
            .platformBrightness ==
        Brightness.dark;

    _controller = WebViewController()
      // Thư đến từ người lạ: không cho chạy script trong đó.
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Chỉ cho tải chính trang nội dung; bấm link trong thư thì chặn -
          // mở tự do trong WebView là một đường dẫn thẳng tới trang lừa đảo.
          onNavigationRequest: (request) => request.url.startsWith('data:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadHtmlString(_wrap(widget.html, isDark));
  }

  /// Bọc thân thư trong một trang tối thiểu: khoá chiều rộng để không tràn
  /// ngang, và lấy màu chữ theo giao diện đang dùng.
  String _wrap(String body, bool isDark) {
    final fg = isDark ? '#F1F5F9' : '#0F172A';
    final link = isDark ? '#60A5FA' : '#2563EB';
    return '''
<!doctype html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html,body{margin:0;padding:12px;background:transparent;color:$fg;
    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
    font-size:15px;line-height:1.6;word-break:break-word;}
  img,table{max-width:100% !important;height:auto !important;}
  table{display:block;overflow-x:auto;border-collapse:collapse;}
  a{color:$link;}
  pre{white-space:pre-wrap;}
</style>
</head><body>$body</body></html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: WebViewWidget(controller: _controller),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/widgets/circle_back_button.dart';

/// Google Form "Ghi danh nộp đơn", mở kín cả màn hình.
///
/// Không có thanh tiêu đề: biểu mẫu của Google vốn đã có tên và mô tả ở đầu
/// trang, thêm một thanh nữa chỉ lặp lại thông tin và ăn mất chiều cao vốn đã
/// eo hẹp khi bàn phím bật lên. Điều hướng dồn vào một nút back tròn nổi ở góc
/// dưới bên phải.
///
/// Trang này được mở trên Navigator gốc (xem [open]) để thanh điều hướng của
/// khung chính không nổi đè lên biểu mẫu.
class DocumentFormWebViewScreen extends StatefulWidget {
  const DocumentFormWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;

  /// Chỉ dùng cho trình đọc màn hình và màn hình báo lỗi.
  final String title;

  /// Mở toàn màn hình, phủ lên cả thanh điều hướng nổi.
  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) =>
            DocumentFormWebViewScreen(url: url, title: title),
        transitionsBuilder: (context, animation, secondary, child) {
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  State<DocumentFormWebViewScreen> createState() =>
      _DocumentFormWebViewScreenState();
}

class _DocumentFormWebViewScreenState extends State<DocumentFormWebViewScreen> {
  late final WebViewController _controller;

  /// 0 khi chưa bắt đầu, 1 khi xong - dùng cho vạch tiến trình mảnh ở trên.
  double _progress = 0;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Nền trắng trong lúc trang đang tải, thay vì một khoảng đen nháy lên.
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;
            setState(() => _progress = value / 100);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loaded = true;
              _progress = 1;
            });
          },
          onWebResourceError: (error) {
            // Chỉ báo lỗi khi chính trang chính hỏng; ảnh hay font lẻ tẻ tải
            // trượt thì biểu mẫu vẫn dùng được bình thường.
            if (!mounted || error.isForMainFrame == false) return;
            setState(() => _error = error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    setState(() {
      _error = null;
      _loaded = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      // Biểu mẫu tự cuộn phần nội dung của nó, nên để bàn phím phủ lên thay vì
      // ép cả trang co lại - Google Form cuộn ô đang gõ vào giữa màn hình.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Chừa đúng phần tai thỏ / thanh trạng thái ở trên, còn lại là web.
          Padding(
            padding: EdgeInsets.only(top: media.viewPadding.top),
            child: _error != null
                ? _ErrorView(title: widget.title, message: _error!, onRetry: _retry)
                : WebViewWidget(controller: _controller),
          ),

          // Dải màu lấp chỗ thanh trạng thái để chữ giờ/pin không đè lên
          // biểu mẫu.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: media.viewPadding.top,
            child: const ColoredBox(color: Colors.white),
          ),

          if (!_loaded && _error == null)
            Positioned(
              top: media.viewPadding.top,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.blue600,
                ),
              ),
            ),

          Positioned(
            right: 16,
            bottom: 12 + media.viewPadding.bottom,
            child: CircleBackButton(
              tooltip: 'Quay lại',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Màn hình thay thế khi biểu mẫu không tải được.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.accentTint(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Symbols.wifi_off_rounded,
                  size: 38,
                  color: AppColors.accent(context),
                ),
              ),
              const SizedBox(height: 20),
              TrText(
                'Không mở được $title',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Symbols.refresh_rounded, size: 20),
                label: const TrText('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

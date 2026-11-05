import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/widgets/circle_back_button.dart';

class NoticeWebViewScreen extends StatefulWidget {
  const NoticeWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;

  final String title;

  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => NoticeWebViewScreen(url: url, title: title),
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
  State<NoticeWebViewScreen> createState() => _NoticeWebViewScreenState();
}

class _NoticeWebViewScreenState extends State<NoticeWebViewScreen> {
  late final WebViewController _controller;

  double _progress = 0;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: media.viewPadding.top),
            child: _error != null
                ? _ErrorView(
                    title: widget.title,
                    message: _error!,
                    onRetry: _retry,
                  )
                : WebViewWidget(controller: _controller),
          ),

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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue600),
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

import 'package:flutter/material.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/services/notice_service.dart';
import 'package:tlustudy_planner/screens/notice_webview_screen.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'floating_nav_bar.dart';
import 'glass_surface.dart';

class NoticeList extends StatefulWidget {
  const NoticeList({super.key, this.service});
  final NoticeService? service;
  @override
  State<NoticeList> createState() => _NoticeListState();
}

class _NoticeListState extends State<NoticeList> {
  late final NoticeService _service = widget.service ?? NoticeService();
  final List<SchoolNotice> _items = [];
  bool _loading = true, _hasNext = false;
  String? _error;
  int _page = 0;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = reset ? 1 : _page + 1;
      final data = await _service.fetchPage(page);
      if (!mounted || request != _request) return;
      setState(() {
        if (reset) _items.clear();
        final known = _items.map((n) => n.url).toSet();
        _items.addAll(data.items.where((n) => known.add(n.url)));
        _page = page;
        _hasNext = data.hasNext;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được thông báo. Vui lòng thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _request++;
    if (widget.service == null) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => _load(reset: true),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        FloatingNavBar.bottomInset(context) + 16,
      ),
      children: [
        for (final notice in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassSurface(
              radius: 24,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: Icon(
                  Icons.campaign_rounded,
                  color: AppColors.accent(context),
                ),
                title: Text(
                  notice.title,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text('tlus.edu.vn'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => NoticeWebViewScreen.open(
                  context,
                  url: notice.url.toString(),
                  title: notice.title,
                ),
              ),
            ),
          ),
        if (_loading) const NoticeSkeleton(),
        if (_error != null) ...[
          TrText(_error!, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: () => _load(reset: _items.isEmpty),
            icon: const Icon(Icons.refresh_rounded),
            label: const TrText('Thử lại'),
          ),
        ] else if (_hasNext && !_loading)
          OutlinedButton(
            onPressed: () => _load(),
            child: const TrText('Xem thêm'),
          ),
      ],
    ),
  );
}

/// Text-shaped placeholders remain visible throughout a slow fetch.
class NoticeSkeleton extends StatefulWidget {
  const NoticeSkeleton({super.key});
  @override
  State<NoticeSkeleton> createState() => _NoticeSkeletonState();
}

class _NoticeSkeletonState extends State<NoticeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('Đang tải thông báo...'),
    child: FadeTransition(
      opacity: MediaQuery.disableAnimationsOf(context)
          ? const AlwaysStoppedAnimation(1)
          : Tween<double>(begin: .4, end: .9).animate(_animation),
      child: Column(
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final width in [double.infinity, 220.0, 100.0])
                  Container(
                    width: width,
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

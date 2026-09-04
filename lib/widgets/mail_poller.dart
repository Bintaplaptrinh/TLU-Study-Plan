import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/providers/mail_provider.dart';

/// Bọc quanh khung chính để hộp thư tự làm mới và bắn thông báo thư mới.
///
/// Cố tình chỉ chạy khi ứng dụng đang mở (hoặc vừa được mở lại), chứ không
/// dựng một alarm nền riêng: đọc refresh token từ Keystore trong isolate của
/// AlarmManager rất dễ gãy giữa các phiên bản Android, và một vòng gọi mạng
/// mỗi 15 phút suốt ngày là cái giá quá đắt về pin cho thứ mà mở app ra là
/// thấy ngay. Đổi lại, thông báo tới khi sinh viên mở máy - đủ sớm cho một
/// hộp thư của trường.
///
/// Muốn thật sự tức thời thì phải đăng ký Graph change notification với một
/// máy chủ trung gian và FCM; đó là một hệ thống khác, không phải việc của
/// một ứng dụng chạy hoàn toàn trên máy.
class MailPoller extends StatefulWidget {
  const MailPoller({super.key, required this.child});

  final Widget child;

  /// Khoảng cách giữa hai lần kiểm tra khi app đang mở.
  static const Duration interval = Duration(minutes: 15);

  /// Không kiểm tra lại nếu vừa kiểm tra xong - tránh việc chuyển qua lại
  /// giữa các app gọi mạng liên tục.
  static const Duration minGap = Duration(minutes: 2);

  @override
  State<MailPoller> createState() => _MailPollerState();
}

class _MailPollerState extends State<MailPoller> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    _timer = Timer.periodic(MailPoller.interval, (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!mounted) return;

    final last = _lastCheck;
    if (last != null && DateTime.now().difference(last) < MailPoller.minGap) {
      return;
    }

    final mail = context.read<MailProvider>();
    if (!mail.isLinked) return;

    _lastCheck = DateTime.now();
    // silent: không hiện vòng quay - sinh viên đang xem lịch học chứ không
    // chờ hộp thư.
    await mail.refresh(silent: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

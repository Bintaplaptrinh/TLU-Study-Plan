import 'package:flutter/material.dart';

import 'package:tlustudy_planner/services/update_service.dart';
import 'package:tlustudy_planner/widgets/update_dialog.dart';

/// Bọc quanh ứng dụng để tự hỏi GitHub xem đã có bản mới chưa.
///
/// Cùng một cách tiếp cận với [MailPoller]: không dựng tác vụ nền, chỉ kiểm
/// tra khi ứng dụng thực sự đang được mở. Một lần một ngày là đủ - bản phát
/// hành không xuất hiện theo giờ, và mỗi lượt gọi đều tính vào hạn mức chung
/// của cả một dải IP.
///
/// Đặt *ngoài* cổng đăng nhập là có chủ đích: người vừa tải app về, chưa đăng
/// nhập được vì bản cũ gọi sai API, vẫn phải nhận được lời mời cập nhật.
class UpdateWatcher extends StatefulWidget {
  const UpdateWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateWatcher> createState() => _UpdateWatcherState();
}

class _UpdateWatcherState extends State<UpdateWatcher>
    with WidgetsBindingObserver {
  /// Chỉ hiện hộp thoại một lần cho mỗi lần chạy ứng dụng, kể cả khi người
  /// dùng chuyển đi chuyển lại nhiều lần trong ngày.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    // Tệp .apk của lần cập nhật trước không còn giá trị gì sau khi đã cài, mà
    // vẫn chiếm vài chục MB.
    UpdateService.instance.cleanUpDownloads();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_shown || !mounted) return;

    final release = await UpdateService.instance.autoCheck();
    if (release == null || !mounted) return;

    _shown = true;
    await showUpdateDialog(context, release, allowSkip: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

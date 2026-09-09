import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/providers/user_provider.dart';
import 'package:tlustudy_planner/screens/home_shell.dart';
import 'package:tlustudy_planner/screens/login_screen.dart';
import 'package:tlustudy_planner/widgets/mail_poller.dart';

/// Quyết định màn hình đầu tiên: khung chính khi đã đăng nhập, trang đăng
/// nhập khi chưa.
///
/// Trước đây ứng dụng luôn mở thẳng vào khung chính, kể cả khi chưa có phiên
/// nào - và sinh viên nhìn thấy một thời khoá biểu trống rỗng, một danh sách
/// điểm trống rỗng, không có gì cho biết là do chưa đăng nhập hay do trường
/// chưa xếp lịch. Trạng thái rỗng ấy không mang thông tin gì, nên nó được
/// thay bằng thứ duy nhất có ích ở thời điểm đó: ô nhập mã sinh viên.
///
/// Đây là một [Consumer] chứ không phải một cú `Navigator.push`, nên đăng
/// xuất từ Cài đặt cũng tự đưa về đây mà không nơi nào phải gọi điều hướng:
/// [UserProvider] báo `isLoggedIn` đổi, cây widget đổi theo.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    // `select` thay vì `Consumer`: UserProvider bắn notifyListeners suốt quá
    // trình tải dữ liệu, mà ở đây chỉ có đúng một bit là đáng dựng lại.
    final loggedIn = context.select<UserProvider, bool>(
      (user) => user.isLoggedIn,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: loggedIn
          // Hộp thư chỉ có nghĩa khi đã có phiên, nên bộ hẹn giờ của nó nằm
          // trong nhánh này chứ không bọc cả hai.
          ? const MailPoller(
              key: ValueKey('shell'),
              child: HomeShell(),
            )
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}

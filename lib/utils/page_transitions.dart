import 'package:flutter/material.dart';

/// Chuyển cảnh dùng chung khi mở một trang con.
///
/// Trang mới trượt vào từ mép phải, trang đang xem lùi sang trái một đoạn ngắn
/// rồi nằm lại phía sau - đi tới thì sang trái, quay lại thì ngược chiều. Cùng
/// một ngôn ngữ chuyển động với việc đổi tab: mọi thứ đều trượt, và hướng
/// trượt luôn chỉ về phía trang đích.
///
/// Bản trước trượt lên từ dưới kèm mờ dần; đặt cạnh cú trượt ngang của thanh
/// tab thì thành hai kiểu chuyển cảnh khác nhau trong cùng một ứng dụng.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // easeOutCubic: nhanh lúc đầu rồi dịu lại - cảm giác "bắt" theo ngón
          // tay hơn là chạy đều.
          final incoming =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );

          return buildCoveredSlide(
            secondaryAnimation,
            SlideTransition(position: incoming, child: child),
          );
        },
      );

  final Widget page;
}

/// Cú lùi của trang bị một trang khác phủ lên.
///
/// Trang bên dưới chỉ lùi một phần tư màn hình chứ không đi hẳn: mắt vẫn bám
/// được là nó còn nằm đó, chờ mình quay lại.
///
/// Tách ra thành hàm riêng vì trang bị phủ tự dựng chuyển cảnh của chính nó -
/// trang gốc của khung tab phải gọi hàm này thì mới lùi theo, chứ
/// [SlidePageRoute] không với tới được nó.
Widget buildCoveredSlide(Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position:
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0)).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        ),
    child: child,
  );
}

/// Mở [page] bằng [SlidePageRoute].
Future<T?> pushSlide<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(SlidePageRoute<T>(page: page));
}

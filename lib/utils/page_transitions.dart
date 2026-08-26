import 'package:flutter/material.dart';

/// Chuyển cảnh dùng chung cho các trang mở từ lưới thẻ "Tiện ích".
///
/// Trang mới trượt lên từ dưới và mờ dần hiện ra, trang cũ lùi lại một chút -
/// đủ để mắt bám được là đang đi *vào* một mục, chứ không phải nhảy màn hình.
/// Dùng một lớp chung thay vì mỗi chỗ tự viết để mọi thẻ mở ra giống nhau.
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  SlideUpPageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // easeOutCubic: nhanh lúc đầu rồi dịu lại - cảm giác "bắt" theo ngón
          // tay hơn là chạy đều.
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          // Trang bên dưới lùi lại nhè nhẹ, tạo chiều sâu khi trang mới phủ lên.
          final outgoing = Tween<double>(begin: 1.0, end: 0.94).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            ),
          );

          return ScaleTransition(
            scale: outgoing,
            child: FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            ),
          );
        },
      );

  final Widget page;
}

/// Mở [page] bằng [SlideUpPageRoute].
Future<T?> pushSlideUp<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(SlideUpPageRoute<T>(page: page));
}

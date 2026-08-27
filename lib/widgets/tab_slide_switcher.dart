import 'package:flutter/material.dart';

/// Đổi giữa các tab bằng một cú trượt ngang theo đúng hướng của tab đích.
///
/// Bấm sang tab bên phải thì trang mới trượt vào từ mép phải và trang cũ trượt
/// khỏi mép trái; bấm ngược lại thì đổi chiều. Nhờ vậy thứ tự các tab trên
/// thanh điều hướng có thật trong chuyển động - người dùng cảm được mình đang
/// đi tới hay lùi lại, thay vì mọi lần đổi tab đều mờ vào giống hệt nhau.
///
/// Trượt trọn một màn hình chứ không phải nhích một đoạn ngắn rồi mờ dần: đó
/// mới là "trượt", và trang cũ rời đi hẳn thay vì tan biến tại chỗ.
class TabSlideSwitcher extends StatelessWidget {
  const TabSlideSwitcher({
    super.key,
    required this.index,
    required this.direction,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  /// Chỉ số tab đang hiển thị; đổi giá trị này là chạy chuyển cảnh.
  final int index;

  /// `1` khi đi sang tab bên phải, `-1` khi lùi về bên trái.
  final int direction;

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // [direction] chỉ đổi cùng lúc với [index], nên trang đang vào và trang
    // đang ra luôn cùng nói về một cú chuyển: bấm liên tiếp thì cú sau ghi đè
    // cú trước và cả hai trang quay theo hướng mới, chứ không cãi nhau.
    final dx = direction >= 0 ? 1.0 : -1.0;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, animation) {
        // Trang đang vào xuất phát từ phía tab đích; trang đang ra đi về phía
        // ngược lại. Với trang đang ra, `animation` chạy ngược từ 1 về 0 nên
        // chỉ cần đặt điểm đầu ở phía đối diện là nó tự trượt đúng chiều.
        final incoming = (child.key as ValueKey<int>?)?.value == index;
        final begin = Offset(incoming ? dx : -dx, 0);

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(index), child: child),
    );
  }
}

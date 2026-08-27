import 'package:flutter/widgets.dart';

/// Cho phép các trang bên trong khung chính chuyển tab.
///
/// Tab nằm ở state của khung, còn nơi muốn đổi tab lại nằm sâu trong cây widget
/// (ví dụ avatar ở Trang chủ mở sang Cài đặt). Truyền callback xuống qua
/// [InheritedWidget] để khỏi phải nối tham số qua từng lớp - và để widget nào
/// không nằm trong khung thì đơn giản là không tìm thấy scope rồi bỏ qua.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goToTab, required super.child});

  /// Chuyển sang tab thứ [index] và đóng mọi trang con đang mở.
  final void Function(int index) goToTab;

  /// Thứ tự tab trên thanh điều hướng.
  static const int todayTab = 0;
  static const int calendarTab = 1;
  static const int examsTab = 2;
  static const int utilitiesTab = 3;
  static const int settingsTab = 4;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

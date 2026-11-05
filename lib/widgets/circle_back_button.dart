import 'package:flutter/material.dart';
import 'glass_button.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/theme/app_colors.dart';

/// Nút back tròn nổi, cùng chất liệu với thanh điều hướng khi nó thu gọn.
///
/// Các trang mở toàn màn hình (webview của Google Form) nằm trên Navigator gốc
/// nên thanh điều hướng của khung chính không với tới được. Nút này thay chỗ
/// nó: cùng đường kính, cùng nền mờ và cùng mũi tên, chỉ khác là nằm ở mép
/// phải để không che phần nội dung bên trái của biểu mẫu.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  /// Cùng đường kính với thanh điều hướng lúc thu gọn.
  static const double diameter = 62;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: Symbols.arrow_back_rounded,
      onTap: onTap,
      size: diameter,
      tooltip: tooltip ?? 'Quay lại',
      color: AppColors.accent(context),
    );
  }
}

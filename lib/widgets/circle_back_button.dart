import 'dart:ui';

import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final button = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Đục hơn thanh điều hướng một chút: bên dưới là trang web nền
              // trắng của Google chứ không phải nền tối của ứng dụng.
              color: AppColors.surface(
                context,
              ).withValues(alpha: isDark ? 0.72 : 0.86),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    Symbols.arrow_back_rounded,
                    size: 24,
                    weight: 600,
                    color: AppColors.accent(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: tooltip ?? 'Quay lại',
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip!, child: button),
    );
  }
}

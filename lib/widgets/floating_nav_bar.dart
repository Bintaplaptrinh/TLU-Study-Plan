import 'package:flutter/material.dart';
import 'glass_surface.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';

/// Một mục trên thanh điều hướng.
class FloatingNavItem {
  const FloatingNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Thanh điều hướng dạng viên thuốc nổi trên nội dung.
///
/// Nền mờ (blur) và bán trong suốt nên vẫn thấy trang chạy phía dưới - thanh
/// nổi hẳn lên khỏi trang thay vì là một dải đặc cắt ngang đáy màn hình như
/// `NavigationBar` mặc định.
///
/// Khi mở một trang con ([collapsed] = true), thanh thu từ phải sang trái
/// thành một nút tròn mang mũi tên back. Nút vẫn giữ nền mờ, nên phần nội dung
/// bị nó che vẫn đọc lờ mờ được thay vì bị một khối đặc chặn hẳn.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onBack,
    this.collapsed = false,
  });

  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Gọi khi bấm nút back lúc đã thu gọn.
  final VoidCallback onBack;

  final bool collapsed;

  /// Chiều cao của thanh, cũng là đường kính nút tròn khi thu gọn.
  static const double barHeight = 62;

  /// Khoảng trống các trang cần chừa ở đáy để nội dung không bị thanh che.
  static double bottomInset(BuildContext context) =>
      barHeight + 12 + MediaQuery.of(context).viewPadding.bottom;

  static const Duration _morph = Duration(milliseconds: 420);
  static const Curve _morphCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(barHeight / 2);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      // Khoá chiều cao trước khi vào LayoutBuilder. Nếu không, LayoutBuilder
      // lấy hết chiều cao còn trống của trang và cái Align bên trong đẩy thanh
      // ra giữa màn hình thay vì nằm dưới đáy.
      child: SizedBox(
        height: barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;

            return Align(
              // Thu về bên trái: mép trái đứng yên, mép phải chạy vào - đúng
              // hướng "từ phải sang trái", và nút back đọng lại đúng chỗ ngón
              // cái hay với tới.
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: _morph,
                curve: _morphCurve,
                width: collapsed ? barHeight : fullWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.12,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GlassSurface(
                  radius: barHeight / 2,
                  clear: true,
                  blur: 12,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hàng tab giữ nguyên bề ngang ban đầu trong lúc vỏ
                      // ngoài co lại, nên nó bị cắt dần đi chứ không bị bóp
                      // méo (và không sinh lỗi tràn khi đang chạy).
                      _Fade(
                        visible: !collapsed,
                        child: OverflowBox(
                          minWidth: fullWidth,
                          maxWidth: fullWidth,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (var i = 0; i < items.length; i++)
                                  Flexible(
                                    child: _NavButton(
                                      item: items[i],
                                      selected: i == currentIndex,
                                      onTap: () => onTap(i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      _Fade(
                        visible: collapsed,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onBack,
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Hiện/ẩn mềm, và chặn chạm khi đang ẩn.
class _Fade extends StatelessWidget {
  const _Fade({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        // Nội dung cũ biến mất nhanh hơn lúc vỏ ngoài kịp co, để không thấy
        // chữ bị cắt ngang.
        duration: Duration(milliseconds: visible ? 260 : 140),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

/// Một tab: chỉ icon, riêng tab đang chọn nở ra thành viên thuốc có chữ.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);

    return Semantics(
      button: true,
      selected: selected,
      // Không còn chữ trên thanh, nên nhãn chỉ còn sống ở đây - cho trình đọc
      // màn hình và cho phần gợi ý khi nhấn giữ.
      label: context.tr(item.label),
      child: Tooltip(
        message: context.tr(item.label),
        waitDuration: const Duration(milliseconds: 600),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.glassSelected(context) : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 24,
                weight: selected ? 600 : 400,
                fill: selected ? 1 : 0,
                color: selected ? accent : AppColors.textMuted(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

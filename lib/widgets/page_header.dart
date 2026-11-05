import 'package:flutter/material.dart';
import 'glass_button.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';

/// Tiêu đề trang dùng chung cho mọi màn hình.
///
/// Trước đây "Tiện ích" và các mục con của nó dùng `SliverAppBar` nền gradient
/// với `FlexibleSpaceBar`, trong khi Trang chủ và Lịch học dùng tiêu đề lớn
/// nằm thẳng trên nền trang. Hai kiểu đặt cạnh nhau khiến Tiện ích trông lạc
/// lõng, và ở các trang con thì tiêu đề bị dồn xuống ngay dưới nút back, lệch
/// hẳn so với nút hành động bên phải.
///
/// [PageHeader] gom về một bố cục duy nhất: hàng nút điều hướng ở trên (back
/// bên trái, hành động bên phải - cân nhau về hai mép), rồi mới đến tiêu đề
/// lớn canh trái thẳng hàng với nút back.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.actions = const <Widget>[],
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 16),
  });

  /// Tiêu đề lớn của trang.
  final String title;

  /// Dòng phụ nhỏ bên dưới tiêu đề, thường là một con số tóm tắt.
  final String? subtitle;

  /// Hiện hàng nút điều hướng với nút back ở mép trái.
  final bool showBack;

  /// Các nút hành động nằm ở mép phải hàng điều hướng (khi có [showBack]) hoặc
  /// ngang hàng tiêu đề (khi không có).
  final List<Widget> actions;

  /// Phần tử đứng cuối hàng tiêu đề - ví dụ avatar ở trang gốc.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrText(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: AppColors.text(context),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 5),
          TrText(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted(context),
            ),
          ),
        ],
      ],
    );

    if (!showBack) {
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            for (final action in actions) ...[const SizedBox(width: 8), action],
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeaderIconButton(
                icon: Symbols.arrow_back_rounded,
                tooltip: 'Quay lại',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              for (final action in actions) ...[
                const SizedBox(width: 8),
                action,
              ],
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 16),
          titleBlock,
        ],
      ),
    );
  }
}

/// Nút vuông bo góc 44x44 dùng cho hàng điều hướng của [PageHeader].
///
/// Cùng kích thước và cùng viền với nút trên trang Lịch học, để hai mép trái -
/// phải của hàng nút cân nhau thay vì một bên là mũi tên trần, một bên là
/// `IconButton` tròn.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;

  /// `null` thì nút mờ đi và không bấm được - dùng khi đang tải.
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: icon,
      onTap: onTap,
      tooltip: tooltip,
      color: onTap == null
          ? AppColors.textMuted(context)
          : AppColors.accent(context),
    );
  }
}

/// Vòng tròn chữ cái đầu của sinh viên, đặt cuối hàng tiêu đề trang gốc.
class HeaderAvatar extends StatelessWidget {
  const HeaderAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'SV'
        : (parts.length == 1
              ? parts.first.substring(0, 1)
              : '${parts[parts.length - 2][0]}${parts.last[0]}');

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(context),
        ),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.31,
        ),
      ),
    );
  }
}

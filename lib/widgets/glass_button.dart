import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/glass_appearance.dart';
import 'glass_surface.dart';

class GlassActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final double height;
  final double blur;
  final Color? fillColor;
  final Color? textColor;
  const GlassActionButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
    this.filled = true,
    this.height = 48,
    this.blur = 24,
    this.fillColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final transparency =
        Theme.of(context).extension<GlassAppearance>()?.transparency ?? .5;
    final foreground =
        textColor ??
        (filled && transparency < .65
            ? AppColors.onAccent(context)
            : AppColors.text(context));
    return GlassSurface(
      radius: height / 2,
      blur: blur,
      tint: fillColor ?? (filled ? AppColors.accent(context) : null),
      child: SizedBox(
        height: height,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            minimumSize: Size(48, height),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double blur;
  final Color? color;
  final String? tooltip;
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.blur = 24,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size < 48 ? 48 : size,
    height: size < 48 ? 48 : size,
    child: Center(
      child: GlassSurface(
        radius: size / 2,
        blur: blur,
        child: SizedBox(
          width: size,
          height: size,
          child: IconButton(
            onPressed: onTap,
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: size, height: size),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              shape: const CircleBorder(),
            ).copyWith(
              // The outer GlassSurface already supplies this control's material.
              backgroundBuilder: (_, _, child) => child ?? const SizedBox.shrink(),
            ),
            icon: Icon(
              icon,
              size: size * .48,
              color: color ?? AppColors.text(context),
            ),
          ),
        ),
      ),
    ),
  );
}

class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: GlassIconButton(
      icon: Icons.arrow_back_rounded,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onTap: () => Navigator.of(context).maybePop(),
    ),
  );
}

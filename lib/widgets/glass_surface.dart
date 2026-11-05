import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ported from tlu_schedule_flutter/widgets/glass_surface.dart.
/// Shared frosted material for floating controls and transient surfaces.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final Color? tint;
  final bool clear;
  final EdgeInsetsGeometry padding;
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 28,
    this.blur = 24,
    this.tint,
    this.clear = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final reduceTransparency = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow(context),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          foregroundPainter: clear
              ? _GlassRimPainter(
                  Theme.of(context).brightness == Brightness.dark,
                )
              : null,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: reduceTransparency ? 0 : blur,
              sigmaY: reduceTransparency ? 0 : blur,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: reduceTransparency
                    ? (tint ?? AppColors.bgDeep(context))
                    : null,
                gradient: reduceTransparency
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: tint == null
                            ? clear
                                  ? [
                                      AppColors.glassClear(context),
                                      AppColors.glassClearSoft(context),
                                    ]
                                  : [
                                      AppColors.glass(context),
                                      AppColors.glassSoft(context),
                                    ]
                            : [
                                tint!.withValues(
                                  alpha: AppColors.glassAlpha(context, .92),
                                ),
                                tint!.withValues(
                                  alpha: AppColors.glassAlpha(context, .76),
                                ),
                              ],
                      ),
                borderRadius: BorderRadius.circular(radius),
                border: clear
                    ? null
                    : Border.all(color: AppColors.glassBorder(context)),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Directional reflection along the existing clipped capsule.
class _GlassRimPainter extends CustomPainter {
  final bool dark;
  const _GlassRimPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(.65);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: dark ? .68 : .95),
          Colors.white.withValues(alpha: .10),
          Colors.white.withValues(alpha: .38),
          Colors.white.withValues(alpha: .08),
          Colors.white.withValues(alpha: dark ? .50 : .80),
        ],
        stops: const [0, .28, .52, .72, 1],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) =>
      dark != oldDelegate.dark;
}

/// Frosted dialog with native route focus and wrapping action buttons.
class GlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  const GlassDialog({super.key, this.title, this.content, this.actions});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
    child: GlassSurface(
      radius: 30,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Semantics(
                namesRoute: true,
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!,
                  child: title!,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (content != null)
              Flexible(
                child: SingleChildScrollView(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: content!,
                  ),
                ),
              ),
            if (actions != null) ...[
              const SizedBox(height: 20),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

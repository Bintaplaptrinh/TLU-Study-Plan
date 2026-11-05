import 'package:flutter/material.dart';

/// A theme extension keeps glass controls independent of provider placement.
class GlassAppearance extends ThemeExtension<GlassAppearance> {
  const GlassAppearance({this.transparency = 0.5});
  final double transparency;

  double alpha(double original) => transparency <= 0.5
      ? 1 - (1 - original) * transparency * 2
      : original * (1 - transparency) * 2;

  @override
  GlassAppearance copyWith({double? transparency}) =>
      GlassAppearance(transparency: transparency ?? this.transparency);

  @override
  GlassAppearance lerp(covariant GlassAppearance? other, double t) =>
      GlassAppearance(
        transparency: other == null
            ? transparency
            : transparency + (other.transparency - transparency) * t,
      );
}

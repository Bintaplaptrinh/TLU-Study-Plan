import 'dart:ui';
import 'package:flutter/material.dart';

/// Modern styled dropdown with glass blur background
/// Modern styled dropdown with glass blur background (ĐÃ CẬP NHẬT)
class StyledDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final String? hint;

  const StyledDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;


    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(

            color: colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: isExpanded,
              hint: hint != null ? Text(hint!) : null,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: colorScheme.primary,
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),

              dropdownColor: colorScheme.surface.withOpacity(
                0.9,
              ),
              borderRadius: BorderRadius.circular(16),
              items: items,
              onChanged: onChanged,
              menuMaxHeight: 400,
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled dropdown form field with glass blur background
class StyledDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final bool isExpanded;

  const StyledDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      items: items,
      onChanged: onChanged,
      menuMaxHeight: 400,
    );
  }
}

/// Glass blur backdrop for modals and overlays
class GlassBlurBackdrop extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final Color? backgroundColor;

  const GlassBlurBackdrop({
    super.key,
    required this.child,
    this.sigmaX = 10.0,
    this.sigmaY = 10.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

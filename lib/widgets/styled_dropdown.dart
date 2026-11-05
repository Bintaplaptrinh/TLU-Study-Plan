import 'package:flutter/material.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'glass_surface.dart';

/// Closed control and open menu share the source project's frosted material.
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

  Future<void> _open(BuildContext context) async {
    final selected = await showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .12),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassSurface(
          radius: 28,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              children: [
                for (final item in items)
                  ListTile(
                    enabled: item.enabled,
                    selected: item.value == value,
                    selectedTileColor: AppColors.glassSelected(context),
                    textColor: AppColors.text(context),
                    trailing: item.value == value
                        ? const Icon(Icons.check_rounded)
                        : null,
                    title: item.child,
                    onTap: item.enabled
                        ? () => Navigator.pop(context, item.value)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => item.value == value).firstOrNull;
    final label = selected?.child ?? TrText(hint ?? 'Chọn');
    return GlassSurface(
      radius: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onChanged == null || items.isEmpty
              ? null
              : () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (isExpanded)
                  Expanded(child: label)
                else
                  Flexible(child: label),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.accent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (labelText != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: TrText(
            labelText!,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      StyledDropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: isExpanded,
      ),
    ],
  );
}

class GlassBlurBackdrop extends StatelessWidget {
  final Widget child;
  final double sigmaX, sigmaY;
  final Color? backgroundColor;
  const GlassBlurBackdrop({
    super.key,
    required this.child,
    this.sigmaX = 24,
    this.sigmaY = 24,
    this.backgroundColor,
  });
  @override
  Widget build(BuildContext context) => GlassSurface(
    radius: 28,
    blur: (sigmaX + sigmaY) / 2,
    tint: backgroundColor,
    child: child,
  );
}

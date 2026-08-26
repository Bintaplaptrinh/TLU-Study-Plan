import 'package:flutter/material.dart';

import 'package:tlustudy_planner/i18n/tr_text.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';

/// How a message reads at a glance. The tone is carried by a leading icon and
/// the accent colour rather than by an emoji inside the message text.
enum SnackTone { neutral, success, warning, error }

/// Shows a SnackBar with the message translated into the active language.
///
/// Every call site passes plain prose - no leading emoji - and the tone is
/// chosen here, so the same message can be restyled in one place.
Future<void> showAppSnackBar(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.neutral,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) async {
  // Captured before the await so a disposed widget can't break the call.
  final messenger = ScaffoldMessenger.of(context);
  final text = await context.trAsync(message);

  // The action's label is a plain String, so it needs translating too.
  final translatedAction = action == null
      ? null
      : SnackBarAction(
          label: await context.trAsync(action.label),
          textColor: action.textColor,
          onPressed: action.onPressed,
        );

  final IconData icon;
  final Color accent;
  switch (tone) {
    case SnackTone.success:
      icon = Icons.check_circle_rounded;
      accent = const Color(0xFF4ADE80);
      break;
    case SnackTone.warning:
      icon = Icons.warning_amber_rounded;
      accent = const Color(0xFFFBBF24);
      break;
    case SnackTone.error:
      icon = Icons.error_rounded;
      accent = const Color(0xFFF87171);
      break;
    case SnackTone.neutral:
      icon = Icons.info_rounded;
      accent = AppColors.blue300;
      break;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      action: translatedAction,
      content: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

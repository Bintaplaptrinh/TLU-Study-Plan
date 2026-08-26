import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/i18n/translation_service.dart';

/// Drop-in replacement for [Text] that translates its content on the fly.
///
/// Whatever string it is given is inspected at build time: text already in the
/// active language is rendered unchanged, and anything in the other language is
/// swapped for a translation from the dictionary, the cache, or (a moment
/// later, once the network answers) the translator.
///
/// It has a const constructor so `const TrText('...')` stays as cheap as
/// `const Text('...')`.
class TrText extends StatelessWidget {
  const TrText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    // Watching both means the widget rebuilds when the language changes and
    // again when a pending network translation lands.
    final code = context.watch<LocaleProvider>().code;
    context.watch<TranslationService>();

    return Text(
      TranslationService.instance.translate(data, code),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

extension TranslateContext on BuildContext {
  /// The active language code, 'vi' or 'en'.
  String get languageCode => read<LocaleProvider>().code;

  /// Translate now, from the dictionary or cache. Falls back to the original
  /// string when only the network could help — use [trAsync] if you must have
  /// the translated form before showing anything.
  String tr(String text) =>
      TranslationService.instance.translate(text, languageCode);

  /// Translate, waiting for the network when necessary.
  Future<String> trAsync(String text) =>
      TranslationService.instance.translateAsync(text, languageCode);
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlustudy_planner/i18n/translation_service.dart';

enum AppLanguage { vietnamese, english }

extension AppLanguageX on AppLanguage {
  /// The code handed to the translator: 'vi' or 'en'.
  String get code => this == AppLanguage.vietnamese ? 'vi' : 'en';

  /// Name shown in the language switch, written in its own language.
  String get label => this == AppLanguage.vietnamese ? 'Tiếng Việt' : 'English';

  Locale get locale => Locale(code);
}

/// Holds the language the interface should be shown in.
///
/// Defaults to the device locale - a Vietnamese phone starts in Vietnamese,
/// anything else starts in English - until the student picks one in Settings.
class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_language';

  AppLanguage _language = AppLanguage.vietnamese;
  bool _followSystem = true;
  SharedPreferences? _prefs;

  AppLanguage get language => _language;
  bool get followSystem => _followSystem;
  String get code => _language.code;
  Locale get locale => _language.locale;
  bool get isEnglish => _language == AppLanguage.english;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await TranslationService.instance.init();

    final saved = _prefs?.getString(_key);
    if (saved == null) {
      _followSystem = true;
      _language = _systemLanguage();
    } else {
      _followSystem = false;
      _language = saved == 'en' ? AppLanguage.english : AppLanguage.vietnamese;
    }
    notifyListeners();
  }

  AppLanguage _systemLanguage() {
    final systemCode =
        ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return systemCode == 'vi' ? AppLanguage.vietnamese : AppLanguage.english;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language && !_followSystem) return;
    _language = language;
    _followSystem = false;
    await _prefs?.setString(_key, language.code);
    notifyListeners();
  }

  Future<void> toggle() => setLanguage(
        _language == AppLanguage.vietnamese
            ? AppLanguage.english
            : AppLanguage.vietnamese,
      );

  /// Go back to following the device locale.
  Future<void> useSystemLanguage() async {
    _followSystem = true;
    _language = _systemLanguage();
    await _prefs?.remove(_key);
    notifyListeners();
  }
}

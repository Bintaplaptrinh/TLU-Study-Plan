import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

import 'package:tlustudy_planner/i18n/language_detector.dart';
import 'package:tlustudy_planner/i18n/ui_dictionary.dart';

/// Translates arbitrary runtime strings between Vietnamese and English.
///
/// Resolution order for every string:
///   1. Already in the target language  -> returned untouched.
///   2. In the hand-written UI dictionary -> instant, offline, our wording.
///   3. In the on-disk cache             -> instant, offline.
///   4. GoogleTranslator over the network -> cached for next time.
///
/// [translate] is synchronous on purpose: it answers from the first three
/// steps immediately and, when only step 4 can help, returns the original text
/// and schedules the fetch. Listeners are notified once results arrive, so
/// widgets rebuild with the translation a moment later.
class TranslationService extends ChangeNotifier {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  static const String _cacheKey = 'tr_cache_v1_payload';
  static const int _maxCacheEntries = 3000;
  static const Duration _debounce = Duration(milliseconds: 60);

  final GoogleTranslator _translator = GoogleTranslator();

  /// '<target> <source text>' -> translated text.
  final Map<String, String> _cache = {};
  final Set<String> _inFlight = {};
  final Set<String> _failed = {};
  final List<_PendingRequest> _queue = [];

  SharedPreferences? _prefs;
  Timer? _flushTimer;
  Timer? _persistTimer;
  bool _notifyScheduled = false;

  /// Set false to stay entirely offline (dictionary + cache only).
  bool networkEnabled = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_cacheKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) => _cache[k] = v as String);
    } catch (_) {
      // A corrupt cache is not worth failing startup over.
    }
  }

  String _key(String text, String target) => '$target $text';

  /// The main entry point used by [TrText] and `context.tr(...)`.
  String translate(String text, String target) {
    if (text.isEmpty || !LanguageDetector.isTranslatable(text)) return text;

    final source = LanguageDetector.detect(text, fallback: target);
    // Already the right language - a Vietnamese label in Vietnamese mode, or
    // an English one in English mode - so leave it exactly as written.
    if (source == target) return text;

    final dictionary = UiDictionary.lookup(text, target);
    if (dictionary != null) return dictionary;

    final key = _key(text, target);
    final cached = _cache[key];
    if (cached != null) return cached;

    if (networkEnabled && !_failed.contains(key) && !_inFlight.contains(key)) {
      _enqueue(text, source, target, key);
    }
    return text;
  }

  /// Awaits a real translation. Used where the text is needed before it can be
  /// shown at all, such as a SnackBar message.
  Future<String> translateAsync(String text, String target) async {
    final immediate = translate(text, target);
    if (immediate != text) return immediate;
    if (!networkEnabled || !LanguageDetector.isTranslatable(text)) return text;

    final source = LanguageDetector.detect(text, fallback: target);
    if (source == target) return text;

    final key = _key(text, target);
    try {
      final result =
          await _translator.translate(text, from: source, to: target);
      _cache[key] = result.text;
      _schedulePersist();
      return result.text;
    } catch (_) {
      _failed.add(key);
      return text;
    }
  }

  void _enqueue(String text, String source, String target, String key) {
    _inFlight.add(key);
    _queue.add(_PendingRequest(text, source, target, key));
    _flushTimer?.cancel();
    _flushTimer = Timer(_debounce, _flush);
  }

  /// Requests are batched so a screen full of new strings becomes a handful of
  /// concurrent calls rather than one per widget.
  Future<void> _flush() async {
    if (_queue.isEmpty) return;
    final batch = List<_PendingRequest>.from(_queue);
    _queue.clear();

    var changed = false;
    await Future.wait(
      batch.map((req) async {
        try {
          final result = await _translator
              .translate(req.text, from: req.source, to: req.target)
              .timeout(const Duration(seconds: 8));
          _cache[req.key] = result.text;
          changed = true;
        } catch (_) {
          // Remember the failure so a blocked endpoint isn't hammered; the
          // original text keeps showing, which is always readable.
          _failed.add(req.key);
        } finally {
          _inFlight.remove(req.key);
        }
      }),
    );

    if (changed) {
      _schedulePersist();
      _scheduleNotify();
    }
  }

  /// Coalesces the rebuild so one batch causes one frame of work.
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), _persist);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    var entries = _cache.entries.toList();
    if (entries.length > _maxCacheEntries) {
      entries = entries.sublist(entries.length - _maxCacheEntries);
    }
    await prefs.setString(
      _cacheKey,
      jsonEncode({for (final e in entries) e.key: e.value}),
    );
  }

  /// Drops every cached translation.
  Future<void> clearCache() async {
    _cache.clear();
    _failed.clear();
    await _prefs?.remove(_cacheKey);
    notifyListeners();
  }

  int get cachedCount => _cache.length;

  @override
  void dispose() {
    _flushTimer?.cancel();
    _persistTimer?.cancel();
    super.dispose();
  }
}

class _PendingRequest {
  const _PendingRequest(this.text, this.source, this.target, this.key);

  final String text;
  final String source;
  final String target;
  final String key;
}

import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:tlustudy_planner/config/app_secrets.dart';
import 'package:tlustudy_planner/models/weather_info.dart';

/// Loads current conditions from WeatherAPI.com.
///
/// Tries the device's GPS position first; if location is denied, disabled or
/// simply too slow, it falls back to fixed Ho Chi Minh City coordinates so the
/// card always shows something useful.
class WeatherService {
  /// Khoá đến từ `--dart-define-from-file=env.json`, không nằm trong mã nguồn.
  /// Xem `lib/config/app_secrets.dart`.
  static const String _apiKey = AppSecrets.weatherApiKey;

  static const String _endpoint = 'https://api.weatherapi.com/v1/current.json';

  /// Ho Chi Minh City — used whenever the device position is unavailable.
  static const double fallbackLat = 10.792807392341823;
  static const double fallbackLon = 106.7063029960745;

  static const Duration _locationTimeout = Duration(seconds: 6);
  static const Duration _locationBudget = Duration(seconds: 10);
  static const Duration _requestTimeout = Duration(seconds: 12);

  /// Cached reading so switching tabs doesn't re-hit the API every time.
  static WeatherInfo? _cached;
  static DateTime? _cachedAt;
  static String? _cachedLang;
  static const Duration _cacheTtl = Duration(minutes: 10);

  /// [lang] is the app's active language ('vi' or 'en'); WeatherAPI returns
  /// the description and city name already localised, so the card needs no
  /// further translation.
  Future<WeatherInfo> loadCurrentWeather({
    bool forceRefresh = false,
    String lang = 'vi',
  }) async {
    // Chặn ngay từ đầu: không có khoá thì mọi bước sau (xin quyền vị trí, gọi
    // mạng) đều vô ích, và API trả 401 với thông điệp tiếng Anh mà
    // người dùng không hiểu.
    if (_apiKey.isEmpty) {
      throw const WeatherException(
        'Chưa cấu hình khoá thời tiết cho bản cài đặt này.',
      );
    }

    final cached = _cached;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        _cachedLang == lang &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    // Hard cap on the whole location step: if the permission dialog is left
    // unanswered we still show weather for the fallback coordinates.
    final position = await _tryGetPosition().timeout(
      _locationBudget,
      onTimeout: () => null,
    );
    final info = await _fetch(
      lat: position?.latitude ?? fallbackLat,
      lon: position?.longitude ?? fallbackLon,
      fromDeviceLocation: position != null,
      lang: lang,
    );

    _cached = info;
    _cachedAt = DateTime.now();
    _cachedLang = lang;
    return info;
  }

  Future<WeatherInfo> _fetch({
    required double lat,
    required double lon,
    required bool fromDeviceLocation,
    required String lang,
  }) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': '$lat,$lon',
        'key': _apiKey,
        'aqi': 'no',
        'lang': lang,
      },
    );

    final response = await http.get(uri).timeout(_requestTimeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Khoá sai hoặc đã bị thu hồi - tách riêng để khỏi lẫn với lỗi mạng.
      throw const WeatherException('Khoá thời tiết không hợp lệ.');
    }
    if (response.statusCode != 200) {
      throw const WeatherException('Không tải được thời tiết hôm nay.');
    }

    return WeatherInfo.fromWeatherApi(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      fromDeviceLocation: fromDeviceLocation,
    );
  }

  /// Never throws — any location problem simply means "use the fallback".
  Future<Position?> _tryGetPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // A recent cached fix is good enough and far quicker than a new lock.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: _locationTimeout,
        ),
      ).timeout(_locationTimeout);
    } catch (_) {
      return null;
    }
  }
}

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

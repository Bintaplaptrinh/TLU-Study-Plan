import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:tlustudy_planner/models/weather_info.dart';

/// Loads current conditions from OpenWeatherMap.
///
/// Tries the device's GPS position first; if location is denied, disabled or
/// simply too slow, it falls back to fixed Ho Chi Minh City coordinates so the
/// card always shows something useful.
class WeatherService {
  static const String _apiKey = '5864a5ae48df5a6c66a80c0147077957';
  static const String _endpoint =
      'https://api.openweathermap.org/data/2.5/weather';

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

  /// [lang] is the app's active language ('vi' or 'en'); OpenWeather returns
  /// the description and city name already localised, so the card needs no
  /// further translation.
  Future<WeatherInfo> loadCurrentWeather({
    bool forceRefresh = false,
    String lang = 'vi',
  }) async {
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
    final position = await _tryGetPosition()
        .timeout(_locationBudget, onTimeout: () => null);
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
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': _apiKey,
        'units': 'metric',
        'lang': lang,
      },
    );

    final response = await http.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw const WeatherException('Không tải được thời tiết hôm nay.');
    }

    return WeatherInfo.fromOpenWeather(
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

/// A single current-conditions reading from WeatherAPI.com.
class WeatherInfo {
  final String city;
  final String condition; // "Clear", "Rain", ...
  final String description; // localised, e.g. "mây rải rác"
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final DateTime observedAt;
  final bool? isDay;

  /// True when the reading was taken from the device's own GPS position
  /// rather than the fallback coordinates.
  final bool fromDeviceLocation;

  const WeatherInfo({
    required this.city,
    required this.condition,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.observedAt,
    this.isDay,
    this.fromDeviceLocation = false,
  });

  factory WeatherInfo.fromWeatherApi(
    Map<String, dynamic> json, {
    bool fromDeviceLocation = false,
  }) {
    final location = json['location'] as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final condition = current['condition'] as Map<String, dynamic>;
    final code = (condition['code'] as num).toInt();
    // Numeric codes are independent of the selected response language.
    final category = switch (code) {
      1000 => 'Clear',
      1003 || 1006 || 1009 => 'Cloud',
      1030 || 1135 || 1147 => 'Mist',
      1087 || 1273 || 1276 || 1279 || 1282 => 'Thunder',
      1066 ||
      1069 ||
      1072 ||
      1114 ||
      1117 ||
      1168 ||
      1171 ||
      1204 ||
      1207 ||
      1210 ||
      1213 ||
      1216 ||
      1219 ||
      1222 ||
      1225 ||
      1237 ||
      1249 ||
      1252 ||
      1255 ||
      1258 ||
      1261 ||
      1264 => 'Snow',
      _ => 'Rain',
    };

    return WeatherInfo(
      city: location['name'].toString(),
      condition: category,
      description: condition['text'].toString(),
      temperature: (current['temp_c'] as num).toDouble(),
      feelsLike: (current['feelslike_c'] as num).toDouble(),
      humidity: (current['humidity'] as num).round(),
      windSpeed: (current['wind_kph'] as num).toDouble() / 3.6,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        (current['last_updated_epoch'] as num).toInt() * 1000,
      ),
      isDay: current['is_day'] == 1,
      fromDeviceLocation: fromDeviceLocation,
    );
  }

  /// Maps the condition category onto the illustration we paint.
  WeatherVisual get visual {
    final key = condition.toLowerCase();
    if (key.contains('rain') || key.contains('drizzle')) {
      return WeatherVisual.rain;
    }
    if (key.contains('thunder')) return WeatherVisual.thunder;
    if (key.contains('snow')) return WeatherVisual.snow;
    if (key.contains('cloud')) return WeatherVisual.cloud;
    if (key.contains('mist') ||
        key.contains('fog') ||
        key.contains('haze') ||
        key.contains('smoke') ||
        key.contains('dust')) {
      return WeatherVisual.mist;
    }
    return WeatherVisual.sun;
  }

  /// Night-time readings get a darker palette even under a clear sky.
  bool get isNight {
    if (isDay != null) return !isDay!;
    final h = observedAt.hour;
    return h >= 18 || h < 6;
  }
}

enum WeatherVisual { sun, cloud, rain, thunder, snow, mist }

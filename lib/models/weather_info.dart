/// A single current-conditions reading from OpenWeatherMap.
class WeatherInfo {
  final String city;
  final String condition; // "Clear", "Rain", ...
  final String description; // localised, e.g. "mây rải rác"
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final DateTime observedAt;

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
    this.fromDeviceLocation = false,
  });

  factory WeatherInfo.fromOpenWeather(
    Map<String, dynamic> json, {
    bool fromDeviceLocation = false,
  }) {
    final weather = (json['weather'] as List?)?.cast<Map<String, dynamic>>();
    final mainWeather = (weather != null && weather.isNotEmpty)
        ? weather.first
        : null;
    final main = (json['main'] as Map?)?.cast<String, dynamic>() ?? {};
    final wind = (json['wind'] as Map?)?.cast<String, dynamic>() ?? {};
    final dt = json['dt'] is int
        ? DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000)
        : DateTime.now();

    return WeatherInfo(
      city: (json['name'] ?? 'Vị trí hiện tại').toString(),
      condition: (mainWeather?['main'] ?? 'Clear').toString(),
      description: (mainWeather?['description'] ?? '').toString(),
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.round() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      observedAt: dt,
      fromDeviceLocation: fromDeviceLocation,
    );
  }

  /// Maps the raw OpenWeather condition onto the illustration we paint.
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
    final h = observedAt.hour;
    return h >= 18 || h < 6;
  }
}

enum WeatherVisual { sun, cloud, rain, thunder, snow, mist }

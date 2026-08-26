import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tlustudy_planner/i18n/locale_provider.dart';
import 'package:tlustudy_planner/models/weather_info.dart';
import 'package:tlustudy_planner/services/weather_service.dart';
import 'package:tlustudy_planner/theme/app_colors.dart';
import 'package:tlustudy_planner/i18n/tr_text.dart';

/// Animated weather card.
///
/// The background is a live [CustomPaint] scene (sun / clouds / rain / snow …)
/// with a little walking student who strolls in from the right once the data
/// lands — holding an umbrella when it rains, shading their eyes when it's
/// sunny. Swipe horizontally for the detail metrics.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, this.height = 178});

  final double height;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard>
    with TickerProviderStateMixin {
  final _service = WeatherService();
  final _pageController = PageController();

  late final AnimationController _motion;
  late final AnimationController _walkIn;

  Future<WeatherInfo>? _weatherFuture;
  int _page = 0;
  String _lang = 'vi';

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _walkIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pageController.addListener(() {
      final page = (_pageController.page ?? 0).round();
      if (page != _page && mounted) setState(() => _page = page);
    });
    _startWeather();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // OpenWeather localises the description and city name, so switching the
    // app language means asking for a fresh reading rather than translating.
    final lang = context.watch<LocaleProvider>().code;
    if (lang != _lang) {
      _lang = lang;
      _startWeather(force: true);
    }
  }

  void _startWeather({bool force = false}) {
    _walkIn.value = 0;
    final future =
        _service.loadCurrentWeather(forceRefresh: force, lang: _lang);
    _weatherFuture = future;
    future.then((_) {
      if (mounted && _weatherFuture == future) _walkIn.forward(from: 0);
    }).catchError((_) {});
  }

  void _reload() => setState(() => _startWeather(force: true));

  @override
  void dispose() {
    _pageController.dispose();
    _motion.dispose();
    _walkIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherInfo>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _WeatherShell(
            height: widget.height,
            visual: WeatherVisual.mist,
            night: false,
            motion: _motion,
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _WeatherShell(
            height: widget.height,
            visual: WeatherVisual.cloud,
            night: false,
            motion: _motion,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Symbols.cloud_off_rounded,
                      color: Colors.white, size: 30, weight: 500),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: TrText(
                      'Không tải được thời tiết.\nChạm để thử lại.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _reload,
                    icon: const Icon(Symbols.refresh_rounded, weight: 600),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final weather = snapshot.data!;
        return _WeatherShell(
          height: widget.height,
          visual: weather.visual,
          night: weather.isNight,
          motion: _motion,
          walkIn: _walkIn,
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                children: [
                  _TodayPage(weather: weather),
                  _DetailPage(weather: weather),
                ],
              ),
              Positioned(
                left: 20,
                bottom: 14,
                child: Row(
                  children: List.generate(2, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: active ? 0.95 : 0.38),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: IconButton(
                  onPressed: _reload,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Symbols.refresh_rounded,
                    color: Colors.white.withValues(alpha: 0.75),
                    weight: 600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────── shell ─────────────────────────────────

class _WeatherShell extends StatelessWidget {
  const _WeatherShell({
    required this.height,
    required this.visual,
    required this.night,
    required this.motion,
    required this.child,
    this.walkIn,
  });

  final double height;
  final WeatherVisual visual;
  final bool night;
  final Animation<double> motion;

  /// Progress of the walking student (null = don't draw, e.g. while loading).
  final Animation<double>? walkIn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedBuilder(
          animation:
              walkIn == null ? motion : Listenable.merge([motion, walkIn]),
          builder: (context, _) {
            return CustomPaint(
              painter: WeatherScenePainter(
                visual: visual,
                night: night,
                t: motion.value,
                walk: walkIn == null
                    ? -1
                    : Curves.easeOutQuad.transform(walkIn!.value),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────── pages ─────────────────────────────────

class _TodayPage extends StatelessWidget {
  const _TodayPage({required this.weather});

  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(weather.observedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(iconForVisual(weather.visual),
                        color: Colors.white, size: 21, weight: 500),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TrText(
                        _capitalize(
                          weather.description.isEmpty
                              ? weather.condition
                              : weather.description,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TrText(
                  '${weather.temperature.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 56,
                    height: 0.95,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                TrText(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                TrText(
                  DateFormat('dd/MM').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      weather.fromDeviceLocation
                          ? Symbols.my_location_rounded
                          : Symbols.location_on_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      weight: 600,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: TrText(
                        weather.city,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.weather});

  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              icon: Symbols.thermostat_rounded,
              label: 'Cảm giác',
              value: '${weather.feelsLike.round()}°',
            ),
          ),
          Expanded(
            child: _Metric(
              icon: Symbols.humidity_percentage_rounded,
              label: 'Độ ẩm',
              value: '${weather.humidity}%',
            ),
          ),
          Expanded(
            child: _Metric(
              icon: Symbols.air_rounded,
              label: 'Gió',
              value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 25, weight: 500),
        const SizedBox(height: 10),
        TrText(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        TrText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── painter ────────────────────────────────

/// Paints the animated weather scene. Exposed so other screens (e.g. a compact
/// header strip) can reuse the same illustration.
class WeatherScenePainter extends CustomPainter {
  WeatherScenePainter({
    required this.visual,
    required this.t,
    this.night = false,
    this.walk = -1,
  });

  final WeatherVisual visual;
  final bool night;

  /// Looping 0..1 clock driving every ambient animation.
  final double t;

  /// Walk-in progress of the student (0..1); -1 = don't draw.
  final double walk;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palette(),
        ).createShader(rect),
    );

    _drawOrbits(canvas, size);

    switch (visual) {
      case WeatherVisual.sun:
        night ? _drawMoon(canvas, size) : _drawSun(canvas, size);
        break;
      case WeatherVisual.cloud:
      case WeatherVisual.mist:
        _drawClouds(canvas, size, mist: visual == WeatherVisual.mist);
        break;
      case WeatherVisual.rain:
      case WeatherVisual.thunder:
        _drawClouds(canvas, size);
        _drawRain(canvas, size, thunder: visual == WeatherVisual.thunder);
        break;
      case WeatherVisual.snow:
        _drawSnow(canvas, size);
        break;
    }

    if (walk >= 0) _drawStudent(canvas, size);
  }

  // The little student walking in from the right edge.
  void _drawStudent(Canvas canvas, Size size) {
    final startX = size.width + 26.0;
    final endX = size.width * 0.62;
    final x = startX + (endX - startX) * walk;
    final walking = walk < 0.985;
    final groundY = size.height - 10.0;

    // A small stance while standing still keeps the legs readable.
    final stride = walking ? math.sin(t * math.pi * 2 * 10) : 0.45;
    final bob = walking ? (1 - stride.abs()) * 1.6 : 0.0;

    final hipY = groundY - 14 - bob;
    final shoulderY = groundY - 26 - bob;
    final headC = Offset(x, groundY - 33.5 - bob);
    const headR = 5.2;

    final body = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.94);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, groundY + 3),
        width: 26,
        height: 5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    canvas.drawLine(Offset(x, hipY), Offset(x - 5.5 * stride, groundY), body);
    canvas.drawLine(Offset(x, hipY), Offset(x + 5.5 * stride, groundY), body);
    canvas.drawLine(Offset(x, hipY), Offset(x, shoulderY), body);
    canvas.drawCircle(headC, headR, fill);

    final shoulder = Offset(x, shoulderY);
    final rainy =
        visual == WeatherVisual.rain || visual == WeatherVisual.thunder;

    if (rainy) {
      canvas.drawLine(
          shoulder, Offset(x + 4.5 * stride, shoulderY + 9), body);
      final hand = Offset(x - 3, shoulderY - 7 - bob * 0.3);
      canvas.drawLine(shoulder, hand, body);
      _drawUmbrella(canvas, hand, bob);
    } else if (visual == WeatherVisual.sun && !night) {
      canvas.drawLine(
          shoulder, Offset(x + 4.5 * stride, shoulderY + 9), body);
      final browY = headC.dy - 2.2;
      canvas.drawPath(
        Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..lineTo(x - 6.5, browY + 4)
          ..lineTo(x - 9.5, browY),
        body,
      );
    } else {
      canvas.drawLine(
          shoulder, Offset(x - 4.5 * stride, shoulderY + 9), body);
      canvas.drawLine(
          shoulder, Offset(x + 4.5 * stride, shoulderY + 9), body);
    }
  }

  void _drawUmbrella(Canvas canvas, Offset hand, double bob) {
    final open = (walk / 0.7).clamp(0.0, 1.0);
    final canopyR = 4.0 + 14.0 * open;
    final top = Offset(hand.dx - 2, hand.dy - 16 - bob * 0.3);

    final shaft = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hand, Offset(top.dx, top.dy + 2), shaft);

    canvas.save();
    canvas.translate(top.dx, top.dy);
    canvas.rotate(-0.12);
    canvas.drawPath(
      Path()
        ..moveTo(-canopyR, 0)
        ..arcToPoint(Offset(canopyR, 0), radius: Radius.circular(canopyR))
        ..close(),
      Paint()..color = const Color(0xFFFFD54F),
    );
    final rim = Paint()
      ..color = const Color(0xFFF9A825)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(canopyR * 0.62 * i, 0),
        Offset(canopyR * 0.62 * i, 1.6),
        rim,
      );
    }
    canvas.drawLine(
      Offset.zero,
      Offset(0, -canopyR - 3),
      shaft..strokeWidth = 1.6,
    );
    canvas.restore();
  }

  void _drawOrbits(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..color = Colors.white.withValues(alpha: 0.08);
    final dx = size.width * (0.74 + math.sin(t * math.pi * 2) * 0.025);
    canvas.drawCircle(Offset(dx, size.height * 0.18), 72, paint);
    canvas.drawCircle(Offset(dx + 18, size.height * 0.16), 116, paint);
  }

  void _drawSun(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (0.78 + math.cos(t * math.pi * 2) * 0.015),
      size.height * 0.18,
    );
    canvas.drawCircle(
      center,
      82,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 82)),
    );
    canvas.drawCircle(center, 32, Paint()..color = const Color(0xFFFFF3B0));
  }

  void _drawMoon(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (0.78 + math.cos(t * math.pi * 2) * 0.012),
      size.height * 0.20,
    );
    canvas.drawCircle(
      center,
      64,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 64)),
    );
    canvas.saveLayer(Rect.fromCircle(center: center, radius: 40), Paint());
    canvas.drawCircle(center, 26, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawCircle(
      center.translate(11, -8),
      24,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // A few stars.
    final star = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 12; i++) {
      final sx = (i * 61 % size.width.toInt()).toDouble();
      final sy = (i * 37 % (size.height * 0.6)).toDouble() + 8;
      final tw = 0.5 + 0.5 * math.sin(t * math.pi * 2 + i);
      canvas.drawCircle(Offset(sx, sy), 1.0 + tw, star);
    }
  }

  void _drawClouds(Canvas canvas, Size size, {bool mist = false}) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: mist ? 0.2 : 0.26);
    final y = size.height * 0.28;
    final shift = math.sin(t * math.pi * 2) * 10;
    _cloud(canvas, Offset(size.width * 0.58 + shift, y), 1.0, paint);
    _cloud(canvas, Offset(size.width * 0.18 - shift * 0.4, y + 24), 0.7, paint);
    if (mist) {
      final line = Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.18);
      for (var i = 0; i < 4; i++) {
        final yy = size.height * 0.47 + i * 18;
        canvas.drawLine(
            Offset(26 + shift, yy), Offset(size.width - 36, yy), line);
      }
    }
  }

  void _cloud(Canvas canvas, Offset origin, double scale, Paint paint) {
    canvas.drawCircle(origin + Offset(0, 16 * scale), 26 * scale, paint);
    canvas.drawCircle(origin + Offset(26 * scale, 0), 32 * scale, paint);
    canvas.drawCircle(
        origin + Offset(62 * scale, 18 * scale), 24 * scale, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx - 10 * scale,
          origin.dy + 18 * scale,
          98 * scale,
          30 * scale,
        ),
        Radius.circular(18 * scale),
      ),
      paint,
    );
  }

  void _drawRain(Canvas canvas, Size size, {required bool thunder}) {
    final rain = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.34);
    for (var i = 0; i < 16; i++) {
      final x = 24 + i * size.width / 13 + (t * 36 % 36);
      final y = 38 + ((t * 110 + i * 21) % size.height);
      canvas.drawLine(Offset(x, y), Offset(x - 13, y + 36), rain);
    }
    if (thunder) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.72, size.height * 0.36)
          ..lineTo(size.width * 0.64, size.height * 0.58)
          ..lineTo(size.width * 0.72, size.height * 0.58)
          ..lineTo(size.width * 0.61, size.height * 0.83),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFF176),
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.78);
    for (var i = 0; i < 28; i++) {
      final x = (i * 37 + math.sin(t * math.pi * 2 + i) * 14) % size.width;
      final y = (t * 90 + i * 23) % size.height;
      canvas.drawCircle(Offset(x, y), 1.8 + (i % 3), paint);
    }
  }

  /// Blue-family gradients so the card still belongs to the app's palette.
  List<Color> _palette() {
    if (night && visual == WeatherVisual.sun) {
      return const [Color(0xFF1E3A8A), Color(0xFF0B1220)];
    }
    switch (visual) {
      case WeatherVisual.sun:
        return const [Color(0xFF38BDF8), Color(0xFF2563EB)];
      case WeatherVisual.cloud:
        return const [Color(0xFF60A5FA), Color(0xFF1D4ED8)];
      case WeatherVisual.rain:
        return const [Color(0xFF3B4C7A), Color(0xFF111B3D)];
      case WeatherVisual.thunder:
        return const [Color(0xFF26355E), Color(0xFF0F172A)];
      case WeatherVisual.snow:
        return const [Color(0xFF93C5FD), Color(0xFF2D6CDF)];
      case WeatherVisual.mist:
        return const [Color(0xFF64748B), Color(0xFF334155)];
    }
  }

  @override
  bool shouldRepaint(covariant WeatherScenePainter old) =>
      old.visual != visual ||
      old.t != t ||
      old.walk != walk ||
      old.night != night;
}

IconData iconForVisual(WeatherVisual visual) {
  switch (visual) {
    case WeatherVisual.sun:
      return Symbols.sunny_rounded;
    case WeatherVisual.cloud:
      return Symbols.cloud_rounded;
    case WeatherVisual.rain:
      return Symbols.rainy_rounded;
    case WeatherVisual.thunder:
      return Symbols.thunderstorm_rounded;
    case WeatherVisual.snow:
      return Symbols.weather_snowy_rounded;
    case WeatherVisual.mist:
      return Symbols.foggy_rounded;
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

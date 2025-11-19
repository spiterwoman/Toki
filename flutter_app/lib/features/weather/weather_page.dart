import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';

// You can also inject this instead of using a global if you prefer
final api = Api('https://mytoki.app');

// === backend weather model =============================================

class Weather {
  final String location;
  final int high;
  final int low;
  final String sunrise;
  final String sunset;
  final int humid;
  final int vis;
  final int pressure;
  final int windSpeed;
  final String forecast;
  final String emoji;
  final DateTime? lastUpdated;

  Weather({
    required this.location,
    required this.high,
    required this.low,
    required this.sunrise,
    required this.sunset,
    required this.humid,
    required this.vis,
    required this.pressure,
    required this.windSpeed,
    required this.forecast,
    required this.emoji,
    required this.lastUpdated,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    final forecast = json['forecast']?.toString() ?? '';

    return Weather(
      location: json['location'] as String? ?? '',
      high: _toInt(json['high']),
      low: _toInt(json['low']),
      sunrise: json['sunrise']?.toString() ?? '',
      sunset: json['sunset']?.toString() ?? '',
      humid: _toInt(json['humid']),
      vis: _toInt(json['vis']),
      pressure: _toInt(json['pressure']),
      windSpeed: _toInt(json['windSpeed']),
      forecast: forecast,
      emoji: _forecastToEmoji(forecast),
      lastUpdated: _toDate(json['lastUpdated']),
    );
  }
}

String _forecastToEmoji(String forecast) {
  final f = forecast.toLowerCase();
  if (f.contains('storm') || f.contains('thunder')) return '⛈️';
  if (f.contains('rain') || f.contains('shower')) return '🌧️';
  if (f.contains('snow')) return '❄️';
  if (f.contains('cloud')) return '⛅';
  if (f.contains('sun') || f.contains('clear')) return '☀️';
  return '☁️';
}

// === page ==============================================================

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Weather? _weather;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // api.viewWeather() returns the `weather` map from the backend
      final map = await api.viewWeather();
      _weather = Weather.fromJson(map);
    } catch (e) {
      _error = 'Failed to load weather: $e';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatLastUpdated(DateTime? dt) {
    if (dt == null) return '';
    final t = TimeOfDay.fromDateTime(dt);
    return 'Last updated: ${t.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PageShell(
        title: 'Weather',
        subtitle: 'Loading…',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _weather == null) {
      return PageShell(
        title: 'Weather',
        subtitle: 'Error',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _error ?? 'Unknown error loading weather.',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final w = _weather!;

    // Map backend Weather -> UI model
    final current = _CurrentWeather(
      emoji: w.emoji,
      condition: w.forecast,
      high: w.high,
      low: w.low,
      humidity: w.humid,
      windSpeed: w.windSpeed,
      visibility: w.vis,
      pressure: w.pressure,
      sunrise: w.sunrise,
      sunset: w.sunset,
    );

    final lastUpdatedText = _formatLastUpdated(w.lastUpdated);

    return PageShell(
      title: 'Weather',
      subtitle: w.location.isNotEmpty ? w.location : 'Orlando, Florida',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CURRENT WEATHER
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 768;
                return GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: isSmall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CurrentWeatherLeft(current: current),
                              const SizedBox(height: 32),
                              _CurrentWeatherStats(current: current),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _CurrentWeatherLeft(current: current),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _CurrentWeatherStats(current: current),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),

            if (lastUpdatedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  lastUpdatedText,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// === data classes ======================================================

class _CurrentWeather {
  final String emoji;
  final String condition;
  final int high;
  final int low;
  final int humidity;
  final int windSpeed;
  final int visibility;
  final int pressure;
  final String sunrise;
  final String sunset;

  const _CurrentWeather({
    required this.emoji,
    required this.condition,
    required this.high,
    required this.low,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
  });
}

// === current weather widgets ==========================================

class _CurrentWeatherLeft extends StatelessWidget {
  final _CurrentWeather current;

  const _CurrentWeatherLeft({required this.current});

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: [
            Text(
              current.emoji,
              style: const TextStyle(fontSize: 96),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show high + low instead of fake "feels like"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${current.high}°',
                      style: const TextStyle(
                        fontSize: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'High',
                      style: TextStyle(
                        color: muted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Low ${current.low}°',
                  style: TextStyle(color: muted, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          current.condition,
          style: const TextStyle(
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  current.sunrise,
                  style: TextStyle(color: muted),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                const Icon(Icons.nightlight_round, size: 16),
                const SizedBox(width: 6),
                Text(
                  current.sunset,
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentWeatherStats extends StatelessWidget {
  final _CurrentWeather current;

  const _CurrentWeatherStats({required this.current});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Humidity',
        '${current.humidity}%',
        const Icon(Icons.water_drop, size: 16, color: Color(0xFF60A5FA)),
      ),
      (
        'Wind Speed',
        '${current.windSpeed} mph',
        const Icon(Icons.air, size: 16, color: Color(0xFF34D399)),
      ),
      (
        'Visibility',
        '${current.visibility} mi',
        const Icon(Icons.visibility, size: 16, color: Color(0xFFA78BFA)),
      ),
      (
        'Pressure',
        '${current.pressure} mb',
        const Icon(Icons.speed, size: 16, color: Color(0xFFFACC15)),
      ),
    ];

    final muted = Colors.white.withOpacity(0.8);

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  item.$3,
                  const SizedBox(width: 8),
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 14,
                      color: muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

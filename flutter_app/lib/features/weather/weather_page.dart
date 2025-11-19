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
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      location: json['location'] as String? ?? '',
      high: json['high'] as int? ?? 0,
      low: json['low'] as int? ?? 0,
      sunrise: json['sunrise']?.toString() ?? '',
      sunset: json['sunset']?.toString() ?? '',
      humid: json['humid'] as int? ?? 0,
      vis: json['vis'] as int? ?? 0,
      pressure: json['pressure'] as int? ?? 0,
      windSpeed: json['windSpeed'] as int? ?? 0,
      forecast: json['forecast']?.toString() ?? '',
      emoji: _forecastToEmoji(json['forecast']?.toString() ?? ''),
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

    // Map backend Weather -> your existing UI model
    final current = _CurrentWeather(
      emoji: w.emoji,
      condition: w.forecast,
      temperature: w.high, // you can change to "currentTemp" if you add it later
      feelsLike: w.high,
      humidity: w.humid,
      windSpeed: w.windSpeed,
      visibility: w.vis,
      pressure: w.pressure,
      sunrise: w.sunrise,
      sunset: w.sunset,
    );

    // Until the backend supports real hourly/weekly, we derive quick placeholders
    final hourly = <_HourlyWeather>[
      _HourlyWeather(time: 'Now', temp: w.high, emoji: w.emoji),
      _HourlyWeather(time: 'Later', temp: w.low, emoji: w.emoji),
    ];

    final weekly = <_DailyWeather>[
      _DailyWeather(day: 'Today', high: w.high, low: w.low, emoji: w.emoji),
    ];

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

            const SizedBox(height: 24),

            // HOURLY FORECAST
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hourly Forecast',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: hourly.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final h = hourly[index];
                          return _HourlyCard(hour: h);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // WEEKLY FORECAST
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_month, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          '7-Day Forecast',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: weekly
                          .map(
                            (d) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: _DailyRow(day: d),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
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
  final int temperature;
  final int feelsLike;
  final int humidity;
  final int windSpeed;
  final int visibility;
  final int pressure;
  final String sunrise;
  final String sunset;

  const _CurrentWeather({
    required this.emoji,
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
  });
}

class _HourlyWeather {
  final String time;
  final int temp;
  final String emoji;

  const _HourlyWeather({
    required this.time,
    required this.temp,
    required this.emoji,
  });
}

class _DailyWeather {
  final String day;
  final int high;
  final int low;
  final String emoji;

  const _DailyWeather({
    required this.day,
    required this.high,
    required this.low,
    required this.emoji,
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
                Text(
                  '${current.temperature}°',
                  style: const TextStyle(
                    fontSize: 64,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Feels like ${current.feelsLike}°',
                  style: TextStyle(color: muted),
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

// === hourly & weekly widgets ==========================================

class _HourlyCard extends StatelessWidget {
  final _HourlyWeather hour;

  const _HourlyCard({required this.hour});

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.6);

    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hour.time,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            hour.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '${hour.temp}°',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final _DailyWeather day;

  const _DailyRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(day.day),
              ),
              const SizedBox(width: 16),
              Text(
                day.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          Row(
            children: [
              Row(
                children: [
                  Text(
                    'High',
                    style: TextStyle(
                      color: muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${day.high}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Text(
                    'Low',
                    style: TextStyle(
                      color: muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${day.low}°',
                    style: TextStyle(
                      color: muted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

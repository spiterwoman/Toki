import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    const current = _CurrentWeather(
      emoji: '☀️',
      condition: 'Sunny',
      temperature: 75,
      feelsLike: 73,
      humidity: 45,
      windSpeed: 8,
      visibility: 10,
      pressure: 1013,
      sunrise: '7:12 AM',
      sunset: '7:45 PM',
    );

    const hourly = <_HourlyWeather>[
      _HourlyWeather(time: '9 AM', temp: 72, emoji: '☀️'),
      _HourlyWeather(time: '12 PM', temp: 78, emoji: '☀️'),
      _HourlyWeather(time: '3 PM', temp: 82, emoji: '🌤️'),
      _HourlyWeather(time: '6 PM', temp: 76, emoji: '🌤️'),
      _HourlyWeather(time: '9 PM', temp: 70, emoji: '🌙'),
    ];

    const weekly = <_DailyWeather>[
      _DailyWeather(day: 'Mon', high: 82, low: 68, emoji: '☀️'),
      _DailyWeather(day: 'Tue', high: 79, low: 66, emoji: '⛅'),
      _DailyWeather(day: 'Wed', high: 75, low: 64, emoji: '🌧️'),
      _DailyWeather(day: 'Thu', high: 73, low: 62, emoji: '🌧️'),
      _DailyWeather(day: 'Fri', high: 76, low: 65, emoji: '⛅'),
      _DailyWeather(day: 'Sat', high: 80, low: 67, emoji: '☀️'),
      _DailyWeather(day: 'Sun', high: 83, low: 69, emoji: '☀️'),
    ];

    return PageShell(
      title: 'Weather',
      subtitle: 'Orlando, Florida',
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
                          .map((d) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: _DailyRow(day: d),
                              ))
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
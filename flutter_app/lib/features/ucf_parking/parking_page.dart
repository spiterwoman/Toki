import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class UcfParkingPage extends StatefulWidget {
  const UcfParkingPage({super.key});

  @override
  State<UcfParkingPage> createState() => _UcfParkingPageState();
}

class _UcfParkingPageState extends State<UcfParkingPage> {
  List<Garage>? _garages;
  String? _error;
  bool _loading = true;
  DateTime? _lastUpdated;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await fetchUcfParking(); // <- hook this to API
      setState(() {
        _garages = data;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      debugPrint('Failed to load UCF parking: $e');
      setState(() {
        _error = 'Failed to load parking data.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _percentFull(Garage g) {
    if (g.capacity == null || g.capacity! <= 0) return 0;
    final cap = g.capacity!;
    final available = (g.available ?? 0).clamp(0, cap);
    final full = cap - available;
    final raw = (full / cap) * 100;
    return raw.clamp(0, 100).round();
  }

  Color _statusColor(GarageStatus status) {
    switch (status) {
      case GarageStatus.available:
        return Colors.greenAccent;
      case GarageStatus.limited:
        return Colors.orangeAccent;
      case GarageStatus.full:
        return Colors.redAccent;
    }
  }

  String _statusLabel(GarageStatus status) {
    switch (status) {
      case GarageStatus.available:
        return 'Available';
      case GarageStatus.limited:
        return 'Limited';
      case GarageStatus.full:
        return 'Full';
    }
  }

  @override
  Widget build(BuildContext context) {
    final garages = _garages ?? [];

    return PageShell(
      title: 'UCF Parking Tracker',
      subtitle: 'Real-time parking availability',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading && _garages == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Loading latest availability…',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$_error — showing any available data.',
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ),

            // list of garages
            Column(
              children: garages.map((g) {
                final p = _percentFull(g);
                final note = (g.capacity != null && g.capacity! > 0)
                    ? '$p% full of ${g.capacity}'
                    : '';

                return Padding(
                  key: ValueKey(g.id),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusBadge(
                                    color: _statusColor(g.status),
                                    label: _statusLabel(g.status),
                                  ),
                                ],
                              ),
                              Text(
                                '${g.available ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _ProgressBar(percent: p),
                          const SizedBox(height: 8),
                          Text(
                            note,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_garages != null && _lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Last updated: '
                  '${TimeOfDay.fromDateTime(_lastUpdated!).format(context)}',
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
        ),
      ),
    );
  }
}

// ===== models ==========================================================

enum GarageStatus { available, limited, full }

class Garage {
  final String id;
  final String name;
  final int? capacity;
  final int? available;
  final GarageStatus status;

  Garage({
    required this.id,
    required this.name,
    required this.status,
    this.capacity,
    this.available,
  });

  // Optional: helper for decoding from JSON
  factory Garage.fromJson(Map<String, dynamic> json) {
    GarageStatus parseStatus(String s) {
      switch (s) {
        case 'Available':
          return GarageStatus.available;
        case 'Limited':
          return GarageStatus.limited;
        case 'Full':
        default:
          return GarageStatus.full;
      }
    }

    return Garage(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown',
      capacity: json['capacity'] as int?,
      available: json['available'] as int?,
      status: parseStatus(json['status'] as String? ?? 'Full'),
    );
  }
}

// ===== widgets =========================================================

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusBadge({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int percent; // 0–100

  const _ProgressBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100).toDouble();

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.12),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped / 100.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF22C55E),
                  Color(0xFFEAB308),
                  Color(0xFFEF4444),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== service stub ====================================================

// TODO: Replace this with real UCF parking service implementation.
// For now, this is mock data

Future<List<Garage>> fetchUcfParking() async {
  // Example mock data:
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    Garage(
      id: 'A',
      name: 'Garage A',
      capacity: 1000,
      available: 250,
      status: GarageStatus.limited,
    ),
    Garage(
      id: 'B',
      name: 'Garage B',
      capacity: 800,
      available: 600,
      status: GarageStatus.available,
    ),
    Garage(
      id: 'C',
      name: 'Garage C',
      capacity: 900,
      available: 50,
      status: GarageStatus.full,
    ),
  ];
}
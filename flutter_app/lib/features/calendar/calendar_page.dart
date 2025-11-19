import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';

final api = Api('https://mytoki.app');

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late int _year;
  late int _month; // 1–12
  late DateTime _selectedDate;

  final List<_UiEvent> _events = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDate = now;
    _loadEventsFromServer();
  }

  // ===== utilities (month grid) =========================================

  List<DateTime> _buildMonth(int year, int month) {
    // First of the month, local time
    final firstOfMonth = DateTime(year, month, 1); // e.g. 2025-11-01 (Sat)

    // Dart weekday: Mon=1 ... Sun=7
    // For a grid that starts on SUNDAY, we want the Sunday on or before day 1.
    final int weekday = firstOfMonth.weekday;     // 1..7
    final int daysBefore = weekday % 7;           // Sun(7)->0, Mon(1)->1, etc.

    // This is the SUNDAY in the top-left cell of the grid
    final firstInGrid =
        DateTime(firstOfMonth.year, firstOfMonth.month, firstOfMonth.day - daysBefore);

    // Now generate 6 weeks (6 * 7 = 42 cells)
    return List<DateTime>.generate(
      42,
      (index) => DateTime(
        firstInGrid.year,
        firstInGrid.month,
        firstInGrid.day + index,
      ),
    );
  }


  // ===== derived data ====================================================

  List<_UiEvent> get _eventsToday =>
      _events.where((e) => _sameDate(e.date, _selectedDate)).toList();

  List<_UiEvent> get _upcoming {
    final copy = [..._events];
    copy.sort((a, b) => a.date.compareTo(b.date));
    return copy;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _go(int deltaMonths) {
    final d = DateTime(_year, _month + deltaMonths, 1);
    setState(() {
      _year = d.year;
      _month = d.month;
    });
  }

  // ===== API wiring ======================================================

  Future<void> _loadEventsFromServer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await api.viewCalendarEvents(); // no eventId => all events
      if (res['success'] == true) {
        final list = (res['events'] as List?) ?? [];
        final events = list
            .map((e) => _UiEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        setState(() {
          _events
            ..clear()
            ..addAll(events);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error']?.toString() ?? 'Failed to load events.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // map our EventTheme to a hex color string used in `color.value`
  String _hexFromTheme(EventTheme theme) {
    switch (theme) {
      case EventTheme.purple:
        return '#A855F7';
      case EventTheme.pink:
        return '#EC4899';
      case EventTheme.blue:
        return '#3B82F6';
    }
  }

  Future<void> _createEventOnServer(_UiEvent ev) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final isAllDay = ev.time == null || ev.time!.isEmpty;

    try {
      await api.createCalendarEvent(
        title: ev.title,
        description: ev.description,
        location: ev.location,
        startDate: ev.date,
        endDate: ev.endDate ?? ev.date,
        color: {
          'value': _hexFromTheme(ev.theme),
        },
        allDay: {
          'isAllDay': isAllDay,
        },
        reminder: {
          'minutesBefore': 30, // default reminder
        },
      );

      await _loadEventsFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeEvent(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.deleteCalendarEvent(eventId: id);
      await _loadEventsFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openAddEventDialog() async {
    final newEvent = await showDialog<_UiEvent>(
      context: context,
      builder: (ctx) => _AddEventDialog(
        initialDate: _selectedDate,
      ),
    );
    if (newEvent != null) {
      await _createEventOnServer(newEvent);
    }
  }

  Future<void> _openEditEventDialog(_UiEvent ev) async {
    final updated = await showDialog<_UiEvent>(
      context: context,
      builder: (ctx) => _EditEventDialog(event: ev),
    );
    if (updated == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final isAllDay = updated.time == null || updated.time!.isEmpty;

    try {
      await api.editCalendarEvent(
        eventId: ev.id,
        title: updated.title,
        description: updated.description,
        location: updated.location,
        startDate: updated.date,
        endDate: updated.endDate ?? updated.date,
        color: {
          'value': _hexFromTheme(updated.theme),
        },
        allDay: {
          'isAllDay': isAllDay,
        },
        reminder: {
          'minutesBefore': 30,
        },
      );

      await _loadEventsFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ===== UI ==============================================================

  @override
  Widget build(BuildContext context) {
    final days = _buildMonth(_year, _month);
    final monthLabel = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(_year, _month, 1));
    final selectedLabel =
        MaterialLocalizations.of(context).formatFullDate(_selectedDate);

    return PageShell(
      title: 'Calendar',
      subtitle: 'Plan your cosmic journey',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // left: month grid
                    Expanded(
                      flex: 6,
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Text('📅',
                                          style: TextStyle(fontSize: 20)),
                                      SizedBox(width: 10),
                                      Text(
                                        'Select Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _SmallGlassButton(
                                        onPressed: () => _go(-1),
                                        child: const Text('<'),
                                      ),
                                      const SizedBox(width: 8),
                                      _SmallGlassButton(
                                        onPressed: () => _go(1),
                                        child: const Text('>'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                monthLabel,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GridView.count(
                                crossAxisCount: 7,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                children: [
                                  // weekday labels
                                  ...['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                                      .map(
                                    (d) => Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // days
                                  ...days.map((d) {
                                    final inMonth = d.month == _month;
                                    final isSelected =
                                        _sameDate(d, _selectedDate);
                                    final hasEvent = _events.any(
                                        (e) => _sameDate(e.date, d));

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDate = d;
                                        });
                                      },
                                      child: Opacity(
                                        opacity: inMonth ? 1.0 : 0.45,
                                        child: Container(
                                          height: 60,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: isSelected
                                                ? Border.all(
                                                    color:
                                                        const Color.fromRGBO(
                                                      174,
                                                      70,
                                                      255,
                                                      0.45,
                                                    ),
                                                    width: 2,
                                                  )
                                                : null,
                                            color: Colors.white
                                                .withOpacity(0.03),
                                          ),
                                          child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: SizedBox(
                                                  width: 40,   // bigger pill so 2 digits fit comfortably
                                                  height: 40,
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(10),
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [
                                                                Color(0xFFA855F7),
                                                                Color(0xFFEC4899),
                                                              ],
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            )
                                                          : null,
                                                    ),
                                                    child: Center(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          '${d.day}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 18,     // nice and big
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              if (hasEvent)
                                                Positioned(
                                                  left: 8,
                                                  bottom: 8,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          Color(0xFF38BDF8),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // right: events for selected day
                    Expanded(
                      flex: 5,
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('📅', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              if (_eventsToday.isEmpty)
                                Text(
                                  'No events today.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                                )
                              else
                                Column(
                                  children: _eventsToday.map((ev) {
                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        color: Colors.white
                                            .withOpacity(0.03),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ev.title,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                if (ev.description != null &&
                                                    ev.description!
                                                        .trim()
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 3),
                                                    child: Text(
                                                      ev.description!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(
                                                                context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color
                                                            ?.withOpacity(
                                                                0.7),
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  ev.time ?? 'All day',
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
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              _SmallGlassButton(
                                                onPressed: () =>
                                                    _openEditEventDialog(ev),
                                                child: const Text('Edit'),
                                              ),
                                              const SizedBox(width: 8),
                                              _SmallGlassButton(
                                                onPressed: () =>
                                                    _removeEvent(ev.id),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upcoming events
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Events',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_upcoming.isEmpty)
                          Text(
                            'Add anticipated events to see them on your calendar.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          )
                        else
                          Column(
                            children: _upcoming.map((ev) {
                              final grad = _themeGradient(ev.theme);
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  gradient: grad,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ev.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatUpcomingLine(ev),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        _SmallGlassButton(
                                          onPressed: () =>
                                              _openEditEventDialog(ev),
                                          child: const Text('Edit'),
                                        ),
                                        const SizedBox(width: 8),
                                        _SmallGlassButton(
                                          onPressed: () =>
                                              _removeEvent(ev.id),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // floating + button
          Positioned(
            right: 26,
            bottom: 26,
            child: _FloatingAddButton(
              onPressed: _openAddEventDialog,
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpcomingLine(_UiEvent ev) {
    final dateStr = MaterialLocalizations.of(context)
        .formatShortMonthDay(ev.date);
    if (ev.time == null || ev.time!.trim().isEmpty) {
      return dateStr;
    }
    return '$dateStr at ${ev.time}';
  }

  Gradient? _themeGradient(EventTheme theme) {
    switch (theme) {
      case EventTheme.purple:
        return const LinearGradient(
          colors: [
            Color.fromRGBO(168, 85, 247, .18),
            Color.fromRGBO(236, 72, 153, .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EventTheme.pink:
        return const LinearGradient(
          colors: [
            Color.fromRGBO(244, 114, 182, .18),
            Color.fromRGBO(251, 113, 133, .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EventTheme.blue:
        return const LinearGradient(
          colors: [
            Color.fromRGBO(59, 130, 246, .18),
            Color.fromRGBO(99, 102, 241, .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

// ===== models ==========================================================

enum EventTheme { purple, pink, blue }

class _UiEvent {
  final String id;
  final String title;
  final DateTime date; // startDate
  final DateTime? endDate;
  final String? time; // display only
  final String? description;
  final String? location;
  final EventTheme theme;

  _UiEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.theme,
    this.endDate,
    this.time,
    this.description,
    this.location,
  });

  // map back from the JSON you showed:
  //  color: { value: "#FF0000" }
  //  reminder: { minutesBefore: 30 }
  //  allDay: { isAllDay: false }
  factory _UiEvent.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? '';
    final title = json['title'] as String? ?? '';
    final description = json['description'] as String?;
    final location = json['location'] as String?;

    DateTime? start;
    final startRaw = json['startDate'];
    if (startRaw != null) {
      try {
        start = DateTime.parse(startRaw.toString());
      } catch (_) {}
    }
    start ??= DateTime.now();

    DateTime? end;
    final endRaw = json['endDate'];
    if (endRaw != null) {
      try {
        end = DateTime.parse(endRaw.toString());
      } catch (_) {}
    }

    // time string from startDate if it has non-midnight time
    String? time;
    if (start.hour != 0 || start.minute != 0) {
      final hour12 = (start.hour % 12 == 0) ? 12 : start.hour % 12;
      final ampm = start.hour < 12 ? 'AM' : 'PM';
      time = '$hour12:${start.minute.toString().padLeft(2, '0')} $ampm';
    }

    // theme from color.value
    EventTheme theme = EventTheme.purple;
    final color = json['color'];
    if (color is Map && color['value'] is String) {
      final hex = (color['value'] as String).toUpperCase();
      if (hex == '#EC4899') {
        theme = EventTheme.pink;
      } else if (hex == '#3B82F6') {
        theme = EventTheme.blue;
      } else {
        theme = EventTheme.purple;
      }
    }

    return _UiEvent(
      id: id,
      title: title,
      date: start,
      endDate: end,
      time: time,
      description: description,
      location: location,
      theme: theme,
    );
  }

  _UiEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? endDate,
    String? time,
    String? description,
    String? location,
    EventTheme? theme,
  }) {
    return _UiEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      time: time ?? this.time,
      description: description ?? this.description,
      location: location ?? this.location,
      theme: theme ?? this.theme,
    );
  }
}

// ===== small widgets ===================================================

class _SmallGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _SmallGlassButton({
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FloatingAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withOpacity(0.18)),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .35),
              offset: Offset(0, 10),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Color.fromRGBO(236, 72, 153, .25),
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '+',
            style: TextStyle(fontSize: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ===== add-event dialog ================================================

class _AddEventDialog extends StatefulWidget {
  final DateTime initialDate;

  const _AddEventDialog({required this.initialDate});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  late DateTime _date;
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  EventTheme _theme = EventTheme.purple;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final ev = _UiEvent(
      id: UniqueKey().toString(),
      title: title,
      date: _date,
      endDate: _date,
      time: _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      theme: _theme,
    );

    Navigator.of(context).pop(ev);
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);

    return AlertDialog(
      title: const Text('Add New Event'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule a new event with a title, date, time, and color theme.',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Event Title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
              ),
            ),
            const SizedBox(height: 8),
            Text('Date',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(loc.formatShortDate(_date)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g., 9:00 AM',
              ),
            ),
            const SizedBox(height: 8),
            Text('Color Theme',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            DropdownButton<EventTheme>(
              value: _theme,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: EventTheme.purple,
                  child: Text('Purple'),
                ),
                DropdownMenuItem(
                  value: EventTheme.pink,
                  child: Text('Pink'),
                ),
                DropdownMenuItem(
                  value: EventTheme.blue,
                  child: Text('Blue'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _theme = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Event'),
        ),
      ],
    );
  }
}

// ===== edit-event dialog ===============================================

class _EditEventDialog extends StatefulWidget {
  final _UiEvent event;

  const _EditEventDialog({required this.event});

  @override
  State<_EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<_EditEventDialog> {
  late DateTime _date;
  late TextEditingController _titleCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late EventTheme _theme;

  @override
  void initState() {
    super.initState();
    _date = widget.event.date;
    _titleCtrl = TextEditingController(text: widget.event.title);
    _timeCtrl = TextEditingController(text: widget.event.time ?? '');
    _descCtrl =
        TextEditingController(text: widget.event.description ?? '');
    _locationCtrl =
        TextEditingController(text: widget.event.location ?? '');
    _theme = widget.event.theme;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final updated = widget.event.copyWith(
      title: title,
      date: _date,
      endDate: _date,
      time: _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      theme: _theme,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);

    return AlertDialog(
      title: const Text('Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Event Title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
              ),
            ),
            const SizedBox(height: 8),
            Text('Date',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(loc.formatShortDate(_date)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g., 9:00 AM',
              ),
            ),
            const SizedBox(height: 8),
            Text('Color Theme',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            DropdownButton<EventTheme>(
              value: _theme,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: EventTheme.purple,
                  child: Text('Purple'),
                ),
                DropdownMenuItem(
                  value: EventTheme.pink,
                  child: Text('Pink'),
                ),
                DropdownMenuItem(
                  value: EventTheme.blue,
                  child: Text('Blue'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _theme = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

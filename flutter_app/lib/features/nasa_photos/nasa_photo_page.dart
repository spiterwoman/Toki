import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';
final api = Api('https://mytoki.app');

class NasaPhotoPage extends StatefulWidget {
  const NasaPhotoPage({super.key});

  @override
  State<NasaPhotoPage> createState() => _NasaPhotoPageState();
}

class _NasaPhotoPageState extends State<NasaPhotoPage> {
  _NasaPhoto? _photo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApodForToday();
  }

  String _formatHumanDate(DateTime d) {
    // Simple "Month day, year" (e.g. October 9, 2025) without adding intl
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _loadApodForToday() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final now = DateTime.now();

    try {
      final res = await api.viewApod(date: now);
      print('APOD response: $res'); // Debug Log

      if (res['success'] == true) {
        final title = res['title'] as String? ?? 'NASA Photo of the Day';
        final hdurl = res['hdurl'] as String?;
        final thumb = res['thumbnailUrl'] as String?;
        final explanation = res['explanation'] as String? ?? '';
        final copyright = res['copyright'] as String? ?? 'NASA';

        setState(() {
          _photo = _NasaPhoto(
            title: title,
            date: _formatHumanDate(now),
            explanation: explanation,
            url: hdurl ?? thumb ?? '',
            copyright: copyright,
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error'] as String? ?? 'Failed to load APOD.';
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

  @override
  Widget build(BuildContext context) {
    // Fallback dummy if we have nothing yet
    final data = _photo ??
        const _NasaPhoto(
          title: 'Loading NASA Photo…',
          date: '',
          explanation: '',
          url:
              'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=1200&q=80',
          copyright: 'NASA',
        );

    return PageShell(
      title: 'NASA Photo of the Day',
      subtitle: "Explore the cosmos through NASA's lens",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading && _photo == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            // Main photo card
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // title + date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (data.date.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Color.fromRGBO(255, 255, 255, 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data.date,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromRGBO(255, 255, 255, 0.6),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // image
                    if (data.url.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            data.url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: const Text(
                          'No image available',
                          style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.6),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // about + copyright
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info,
                                size: 20,
                                color: Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'About this image',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.explanation.isNotEmpty
                                          ? data.explanation
                                          : 'Explanation not available.',
                                      style: const TextStyle(
                                        color: Color.fromRGBO(
                                            255, 255, 255, 0.8),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.photo_camera,
                              size: 16,
                              color: Color.fromRGBO(255, 255, 255, 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.copyright,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromRGBO(255, 255, 255, 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Optional: a tiny refresh button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _loading ? null : _loadApodForToday,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent photos card (still mock for now)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Photos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 700) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 450) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentPhotos.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 16 / 13,
                          ),
                          itemBuilder: (context, index) {
                            final photo = recentPhotos[index];
                            return _RecentPhotoCard(photo: photo);
                          },
                        );
                      },
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

// ===== data classes ====================================================

class _NasaPhoto {
  final String title;
  final String date;
  final String explanation;
  final String url;
  final String copyright;

  const _NasaPhoto({
    required this.title,
    required this.date,
    required this.explanation,
    required this.url,
    required this.copyright,
  });
}

class _RecentPhoto {
  final int id;
  final String title;
  final String date;
  final String thumbnail;

  const _RecentPhoto({
    required this.id,
    required this.title,
    required this.date,
    required this.thumbnail,
  });
}

// Recent mock thumbnails (unchanged)
const recentPhotos = <_RecentPhoto>[
  _RecentPhoto(
    id: 1,
    title: 'Jupiter\'s Great Red Spot',
    date: 'Oct 8, 2025',
    thumbnail:
        'https://images.unsplash.com/photo-1614732484003-ef9881555dc3?w=400',
  ),
  _RecentPhoto(
    id: 2,
    title: 'Andromeda Galaxy',
    date: 'Oct 7, 2025',
    thumbnail:
        'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=400',
  ),
  _RecentPhoto(
    id: 3,
    title: 'Saturn\'s Rings',
    date: 'Oct 6, 2025',
    thumbnail:
        'https://images.unsplash.com/photo-1614313913007-2b4ae8ce32d6?w=400',
  ),
];

// ===== recent photo card ===============================================

class _RecentPhotoCard extends StatelessWidget {
  final _RecentPhoto photo;

  const _RecentPhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              photo.thumbnail,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  photo.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromRGBO(255, 255, 255, 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
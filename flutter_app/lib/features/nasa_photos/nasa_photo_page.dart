import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class NasaPhotoPage extends StatelessWidget {
  const NasaPhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    const mockNasaData = _NasaPhoto(
      title: 'The Magnificent Nebula NGC 6302',
      date: 'October 9, 2025',
      explanation:
          'The bright clusters and nebulae of planet Earth\'s night sky are often named for flowers or insects. Though its wingspan covers over 3 light-years, NGC 6302 is no exception. With an estimated surface temperature of about 250,000 degrees C, the dying central star of this particular planetary nebula has become exceptionally hot, shining brightly in ultraviolet light but hidden from direct view by a dense torus of dust.',
      url:
          'https://images.unsplash.com/photo-1642635715930-b3a1eba9c99f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzcGFjZSUyMHN0YXJzJTIwbmVidWxhfGVufDF8fHx8MTc1OTk3OTAxMXww&ixlib=rb-4.1.0&q=80&w=1080',
      copyright: 'NASA/ESA Hubble Space Telescope',
    );

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

    return PageShell(
      title: 'NASA Photo of the Day',
      subtitle: "Explore the cosmos through NASA's lens",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                            mockNasaData.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16,
                                color: Color.fromRGBO(255, 255, 255, 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              mockNasaData.date,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          mockNasaData.url,
                          fit: BoxFit.cover,
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
                                      mockNasaData.explanation,
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
                              mockNasaData.copyright,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromRGBO(255, 255, 255, 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent photos card
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
                        // adapt columns based on width
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
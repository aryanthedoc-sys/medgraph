import 'package:flutter/material.dart';

const Color _teal = Color(0xFF17C3B2);

class LandingFeeds extends StatelessWidget {
  const LandingFeeds({super.key, required this.isMobile});
  final bool isMobile;

  static const _feeds = [
    _Feed(
      'Rounds',
      Icons.video_camera_back_outlined,
      '60-second clinical video',
      'Short-form clinical videos by verified doctors. Watch, learn, and share what you know.',
      _teal,
    ),
    _Feed(
      'Cases',
      Icons.article_outlined,
      'Clinical case discussions',
      'Anonymised cases discussed by the community. MCQ polls, differential diagnoses, and teaching moments.',
      Color(0xFF007AFF),
    ),
    _Feed(
      'Life',
      Icons.photo_outlined,
      'The human side of medicine',
      'The stress, the milestones, the NEET grind. Real stories from real medical people.',
      Color(0xFFAF52DE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isMobile ? 20 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _teal,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Three feeds. One community.',
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: _feeds
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _FeedCard(feed: f),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _feeds
                      .expand((f) => [
                            Expanded(child: _FeedCard(feed: f)),
                            if (f != _feeds.last) const SizedBox(width: 20),
                          ])
                      .toList(),
                ),
          const SizedBox(height: 32),
          // Trust banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: _teal, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No anonymous accounts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Every person on MedGraph is verified — students by institution, doctors by MCI/NMC registration. No bots, no fakes.',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF666666), height: 1.4),
                      ),
                    ],
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

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.feed});
  final _Feed feed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(color: feed.color, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: feed.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feed.icon, color: feed.color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            feed.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            feed.subtitle,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: feed.color,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            feed.description,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF666666), height: 1.5),
          ),
          const SizedBox(height: 20),
          // Mini phone mockup
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(feed.icon,
                  color: feed.color.withValues(alpha: 0.4), size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feed {
  const _Feed(this.name, this.icon, this.subtitle, this.description, this.color);
  final String name, subtitle, description;
  final IconData icon;
  final Color color;
}

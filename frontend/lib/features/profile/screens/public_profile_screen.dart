import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_avatar.dart';
import '../../../shared/widgets/mg_badge.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/services/api_service.dart';

/// Public doctor profile — no auth required. Google-indexable.
/// Reached at /dr/:handle
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.handle});
  final String handle;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.get('/api/profiles/${widget.handle}');
      setState(() { _profile = data['profile'] as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Profile not found'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }

    final p = _profile!;
    final name      = p['full_name'] as String? ?? '';
    final specialty = p['specialty'] as String? ?? '';
    final hospital  = p['hospital']  as String? ?? '';
    final city      = p['city']      as String? ?? '';
    final bio       = p['bio']       as String? ?? '';
    final followers = p['follower_count'] as int? ?? 0;
    final posts     = p['post_count'] as int? ?? 0;
    final fameTier  = p['fame_tier'] as String? ?? 'none';
    final avatarUrl = p['avatar_url'] as String?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(name),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MGAvatar(
                        name: name,
                        imageUrl: avatarUrl,
                        size: AvatarSize.large,
                        isVerifiedDoctor: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title2.copyWith(color: text)),
                            if (specialty.isNotEmpty)
                              Text(specialty,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.subheadline.copyWith(color: sub)),
                            if (hospital.isNotEmpty)
                              Text(hospital,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.footnote.copyWith(color: sub)),
                            if (city.isNotEmpty)
                              Text(city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.footnote.copyWith(color: sub)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const MGBadge(type: BadgeType.verified),
                                const SizedBox(width: 6),
                                if (fameTier != 'none')
                                  MGBadge(type: _tierToBadge(fameTier)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(value: followers, label: 'Followers'),
                      const SizedBox(width: 24),
                      _Stat(value: posts, label: 'Posts'),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(bio,
                        style: AppTextStyles.body.copyWith(color: text)),
                  ],
                  const SizedBox(height: 20),
                  MGButton(label: 'Follow', onPressed: () {}),
                  const SizedBox(height: 12),
                  // Consultation waitlist
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consultations',
                            style: AppTextStyles.headline.copyWith(color: text)),
                        const SizedBox(height: 6),
                        Text(
                          'We\'ll notify you when consultations launch with this doctor.',
                          style: AppTextStyles.subheadline.copyWith(color: sub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BadgeType _tierToBadge(String tier) {
    switch (tier) {
      case 'rising':        return BadgeType.rising;
      case 'notable':       return BadgeType.notable;
      case 'top_educator':  return BadgeType.topEducator;
      case 'medgraph_fellow': return BadgeType.fellow;
      default:              return BadgeType.verified;
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    return Column(
      children: [
        Text('$value', style: AppTextStyles.title3.copyWith(color: text)),
        Text(label, style: AppTextStyles.caption.copyWith(color: sub)),
      ],
    );
  }
}

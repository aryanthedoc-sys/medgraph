import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/mg_avatar.dart';
import '../../../shared/widgets/mg_badge.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_card.dart';
import '../../../shared/widgets/mg_secondary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Profile',
                              style: AppTextStyles.largeTitle.copyWith(color: text)),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_outlined, color: text),
                          onPressed: () => _showSettingsSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Avatar + name row
                    Row(
                      children: [
                        MGAvatar(
                          name: user.fullName,
                          imageUrl: user.avatarUrl,
                          size: AvatarSize.large,
                          isVerifiedDoctor: user.isDoctor && user.isVerified,
                          isVerifiedStudent: user.isStudent && user.isVerified,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName,
                                  style: AppTextStyles.title2.copyWith(color: text)),
                              if (user.college != null)
                                Text(user.college!,
                                    style: AppTextStyles.subheadline.copyWith(color: sub)),
                              if (user.specialty != null)
                                Text(user.specialty!,
                                    style: AppTextStyles.subheadline.copyWith(color: sub)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (user.isVerified) ...[
                                    MGBadge(
                                      type: user.isDoctor
                                          ? BadgeType.verified
                                          : BadgeType.verified,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (ref.read(currentUserProvider.notifier).isPro)
                                    const MGBadge(type: BadgeType.pro),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (user.bio != null && user.bio!.isNotEmpty)
                      Text(user.bio!,
                          style: AppTextStyles.body.copyWith(color: text)),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        _StatItem(value: user.followerCount, label: 'Followers'),
                        const SizedBox(width: 24),
                        _StatItem(value: user.followingCount, label: 'Following'),
                        const SizedBox(width: 24),
                        _StatItem(value: user.postCount, label: 'Posts'),
                        const SizedBox(width: 24),
                        _StatItem(value: user.currentStreak, label: 'Streak 🔥'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pro upgrade banner (free users only)
                    if (!ref.read(currentUserProvider.notifier).isPro)
                      MGCard(
                        onTap: () => context.go('/upgrade'),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.proGold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Upgrade to Pro',
                                      style: AppTextStyles.headline.copyWith(color: text)),
                                  Text('Search profiles, unlimited sessions · ₹99/month',
                                      style: AppTextStyles.footnote.copyWith(color: sub)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: sub),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Search button
                    MGSecondaryButton(
                      label: 'Search profiles',
                      onPressed: () => context.go('/search'),
                    ),
                    const SizedBox(height: 12),
                    MGSecondaryButton(
                      label: 'Leaderboard',
                      onPressed: () => context.go('/leaderboard'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    return Column(
      children: [
        Text(
          value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value',
          style: AppTextStyles.title3.copyWith(color: text),
        ),
        Text(label, style: AppTextStyles.caption.copyWith(color: sub)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/mg_avatar.dart';
import '../../../shared/widgets/mg_badge.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_card.dart';
import '../../../shared/widgets/mg_secondary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 18 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
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
                    const SizedBox(height: 20),

                    // Verification banner
                    if (!user.isVerified)
                      _VerificationBanner(user: user),

                    const SizedBox(height: 16),

                    // Avatar + name
                    isMobile
                        ? _avatarColumnLayout(user, isDark, text, sub)
                        : _avatarRowLayout(user, isDark, text, sub, ref),

                    if (!isMobile) const SizedBox(height: 16),
                    if (isMobile) ...[
                      const SizedBox(height: 12),
                      _badgesRow(user, ref),
                    ],

                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(user.bio!, style: AppTextStyles.body.copyWith(color: text)),
                    ],
                    const SizedBox(height: 20),

                    // Stats row
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        _StatItem(value: user.followerCount, label: 'Followers'),
                        _StatItem(value: user.followingCount, label: 'Following'),
                        _StatItem(value: user.postCount, label: 'Posts'),
                        _StatItem(value: user.currentStreak, label: 'Streak 🔥'),
                        if (user.vouchCount > 0)
                          _StatItem(value: user.vouchCount, label: 'Vouched'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pro upgrade banner
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

                    MGSecondaryButton(
                      label: 'Search profiles',
                      onPressed: () => context.go('/search'),
                    ),
                    const SizedBox(height: 10),
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

  Widget _avatarRowLayout(UserModel user, bool isDark, Color text, Color sub, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MGAvatar(
          name: user.fullName,
          imageUrl: user.avatarUrl,
          size: AvatarSize.large,
          isVerifiedDoctor:  user.isDoctor  && user.isVerified,
          isVerifiedStudent: user.isStudent && user.isVerified,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: AppTextStyles.title2.copyWith(color: text)),
              if (user.collegeName != null)
                Text(user.collegeName!, style: AppTextStyles.subheadline.copyWith(color: sub))
              else if (user.college != null)
                Text(user.college!, style: AppTextStyles.subheadline.copyWith(color: sub)),
              if (user.specialty != null)
                Text(user.specialty!, style: AppTextStyles.subheadline.copyWith(color: sub)),
              const SizedBox(height: 6),
              _badgesRow(user, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarColumnLayout(UserModel user, bool isDark, Color text, Color sub) {
    return Row(
      children: [
        MGAvatar(
          name: user.fullName,
          imageUrl: user.avatarUrl,
          size: AvatarSize.large,
          isVerifiedDoctor:  user.isDoctor  && user.isVerified,
          isVerifiedStudent: user.isStudent && user.isVerified,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: AppTextStyles.title2.copyWith(color: text)),
              Text(user.roleLabel, style: AppTextStyles.footnote.copyWith(color: sub)),
              if (user.collegeName != null || user.college != null)
                Text(
                  user.collegeName ?? user.college ?? '',
                  style: AppTextStyles.footnote.copyWith(color: sub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badgesRow(UserModel user, WidgetRef ref) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _verificationBadge(user),
        if (ref.read(currentUserProvider.notifier).isPro)
          const MGBadge(type: BadgeType.pro),
      ],
    );
  }

  Widget _verificationBadge(UserModel user) {
    if (user.isVerified) {
      return _StatusBadge(
        label: 'Verified',
        icon: Icons.verified,
        color: AppColors.teal,
      );
    }
    if (user.isProofSubmitted) {
      return _StatusBadge(
        label: 'Under Review',
        icon: Icons.hourglass_empty,
        color: Colors.amber,
      );
    }
    if (user.isSuspended) {
      return _StatusBadge(
        label: 'Suspended',
        icon: Icons.block,
        color: AppColors.danger,
      );
    }
    return _StatusBadge(
      label: 'Unverified',
      icon: Icons.shield_outlined,
      color: Colors.grey,
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
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Upload verification proof'),
              onTap: () {
                Navigator.pop(context);
                context.push('/register/proof-upload');
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
                await AuthStorage.clear();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = user.isProofSubmitted;

    return GestureDetector(
      onTap: isSubmitted ? null : () => context.push('/register/proof-upload'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSubmitted
              ? const Color(0xFFFFF8E1)
              : Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSubmitted
                    ? 'Verification under review — we\'ll notify you within 24h'
                    : 'Verification pending — Upload your proof to get your verified badge',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A5600),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isSubmitted) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.amber, size: 18),
            ],
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
    final sub  = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
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

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AvatarSize { small, medium, large }

/// Circular avatar with URL image and initials fallback.
class MGAvatar extends StatelessWidget {
  const MGAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AvatarSize.medium,
    this.isVerifiedDoctor = false,
    this.isVerifiedStudent = false,
  });

  final String? imageUrl;
  final String name;
  final AvatarSize size;
  final bool isVerifiedDoctor;
  final bool isVerifiedStudent;

  double get _diameter {
    switch (size) {
      case AvatarSize.small:  return 32;
      case AvatarSize.medium: return 44;
      case AvatarSize.large:  return 72;
    }
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final d = _diameter;
    final fontSize = d * 0.35;

    Widget avatar = Container(
      width: d,
      height: d,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkSurface2,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: d,
                height: d,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initialsWidget(fontSize),
              ),
            )
          : _initialsWidget(fontSize),
    );

    // Wrap with verified badge overlay if needed
    if (isVerifiedDoctor || isVerifiedStudent) {
      final badgeColor = isVerifiedDoctor
          ? AppColors.verifiedGreen
          : AppColors.verifiedBlue;
      final badgeSize = d * 0.32;

      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(
                Icons.check,
                size: badgeSize * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _initialsWidget(double fontSize) => Center(
    child: Text(
      _initials,
      style: AppTextStyles.body.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

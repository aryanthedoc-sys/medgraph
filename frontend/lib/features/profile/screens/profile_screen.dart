import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/api_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  UserModel? _user;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;
  bool _avatarLoading = false;
  bool _hasVouched = false;
  bool _isBlocked  = false;
  int _tab = 0;

  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) setState(() => _tab = _tabCtrl.index);
      });
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_isOwnProfile) {
      final cached = ref.read(currentUserProvider);
      if (cached != null) setState(() { _user = cached; _loading = false; });
      try {
        final data = await ApiService.get('/api/profiles/me');
        final u = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        ref.read(currentUserProvider.notifier).setUser(u);
        if (mounted) setState(() { _user = u; _loading = false; });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      try {
        final data = await ApiService.get('/api/profiles/${widget.userId}');
        if (mounted) {
          setState(() {
            _user = UserModel.fromJson(data['profile'] as Map<String, dynamic>);
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null || _followLoading) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await ApiService.delete('/api/profiles/${_user!.id}/follow');
        setState(() {
          _isFollowing = false;
          _user = _user!.copyWith(followerCount: _user!.followerCount - 1);
        });
      } else {
        await ApiService.post('/api/profiles/${_user!.id}/follow', {});
        setState(() {
          _isFollowing = true;
          _user = _user!.copyWith(followerCount: _user!.followerCount + 1);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _followLoading = false);
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if ((f.size) > 5 * 1024 * 1024) {
        _showSnack('Image too large. Max 5 MB.');
        return;
      }
      setState(() => _avatarLoading = true);
      final ext = f.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final res = await ApiService.uploadFile(
        path: '/api/profiles/avatar',
        fieldName: 'file',
        fileBytes: f.bytes ?? Uint8List(0),
        filename: f.name,
        mimeType: mime,
      );
      final url = res['avatar_url'] as String?;
      if (url != null && mounted) {
        final updated = _user!.copyWith(avatarUrl: url);
        ref.read(currentUserProvider.notifier).setUser(updated);
        setState(() { _user = updated; _avatarLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _avatarLoading = false);
      _showSnack('Could not update photo.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAvatarSheet() {
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
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pickAvatar(); },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () { Navigator.pop(context); _pickAvatar(); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _vouch() async {
    if (_user == null) return;
    try {
      final data = await ApiService.post('/api/profiles/${_user!.id}/vouch', {});
      final newCount = data['vouch_count'] as int? ?? _user!.vouchCount + 1;
      setState(() {
        _hasVouched = true;
        _user = _user!.copyWith(vouchCount: newCount);
      });
      _showSnack('You vouched for ${_user!.fullName} ✓');
    } on ApiException catch (e) {
      _showSnack(e.statusCode == 409 ? 'Already vouched' : e.message);
    } catch (_) {
      _showSnack('Could not vouch. Please try again.');
    }
  }

  Future<void> _block() async {
    if (_user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Block ${_user!.fullName}?'),
        content: const Text(
          'They won\'t be able to see your profile, match with you, or message you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.post('/api/profiles/${_user!.id}/block', {});
      setState(() => _isBlocked = true);
      _showSnack('${_user!.fullName} blocked');
    } catch (_) {
      _showSnack('Could not block. Please try again.');
    }
  }

  void _showMoreSheet() {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.read(currentUserProvider);
    final canVouch    = currentUser?.isVerified == true && !_hasVouched;

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
            if (canVouch)
              ListTile(
                leading: const Icon(Icons.verified_user_outlined, color: AppColors.teal),
                title: Text('Vouch for ${_user?.fullName ?? 'this user'}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Confirm you know this person is a real med student/doctor'),
                onTap: () { Navigator.pop(context); _vouch(); },
              ),
            if (_hasVouched)
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.teal),
                title: const Text('Vouched ✓',
                    style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w500)),
                subtitle: const Text('You have already vouched for this profile'),
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
              title: const Text('Report this profile',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () { Navigator.pop(context); _showSnack('Report submitted.'); },
            ),
            ListTile(
              leading: Icon(
                _isBlocked ? Icons.do_not_disturb_off : Icons.block,
                color: AppColors.danger,
              ),
              title: Text(
                _isBlocked ? 'Unblock ${_user?.fullName ?? 'user'}' : 'Block ${_user?.fullName ?? 'user'}',
                style: const TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (_isBlocked) {
                  try {
                    await ApiService.delete('/api/profiles/${_user!.id}/block');
                    setState(() => _isBlocked = false);
                    _showSnack('Unblocked');
                  } catch (_) {
                    _showSnack('Could not unblock.');
                  }
                } else {
                  _block();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? Colors.black : Colors.white;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    if (_loading && _user == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 48, color: sub),
              const SizedBox(height: 12),
              Text('Profile not found', style: AppTextStyles.headline.copyWith(color: text)),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user, isDark, text),
          SliverToBoxAdapter(child: _buildHeader(user, isDark, text, sub)),
          SliverPersistentHeader(
            delegate: _TabBarDelegate(
              tabCtrl: _tabCtrl,
              isDark: isDark,
              bg: bg,
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: _buildTabContent(user, isDark, text, sub),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(UserModel user, bool isDark, Color text) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      foregroundColor: text,
      elevation: 0,
      automaticallyImplyLeading: !_isOwnProfile,
      leading: _isOwnProfile
          ? null
          : IconButton(
              icon: Icon(Icons.arrow_back, color: text),
              onPressed: () => context.pop(),
            ),
      title: Text(user.fullName,
          style: AppTextStyles.headline.copyWith(color: text)),
      centerTitle: false,
      actions: [
        if (_isOwnProfile)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: text),
            onPressed: () => context.push('/settings'),
          )
        else
          IconButton(
            icon: Icon(Icons.more_vert, color: text),
            onPressed: _showMoreSheet,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildHeader(UserModel user, bool isDark, Color text, Color sub) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 20, isMobile ? 16 : 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + identity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarWidget(
                user: user,
                loading: _avatarLoading,
                onTap: _isOwnProfile ? _showAvatarSheet : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.fullName,
                        style: AppTextStyles.title2.copyWith(color: text)),
                    const SizedBox(height: 4),
                    _VerificationChip(user: user),
                    const SizedBox(height: 6),
                    _roleInstitutionLine(user, sub),
                    if (user.fameTier != 'none' && user.fameTier.isNotEmpty && user.isDoctor)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _FameBadge(tier: user.fameTier),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          _StatsRow(user: user, onFollowers: _goToFollowers, onFollowing: _goToFollowing),
          const SizedBox(height: 16),

          // Action buttons (other profile only)
          if (!_isOwnProfile)
            _ActionButtons(
              isFollowing: _isFollowing,
              loading: _followLoading,
              onFollow: _toggleFollow,
              onSession: () => context.push('/sessions?userId=${user.id}'),
            ),
          if (!_isOwnProfile) const SizedBox(height: 16),

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            Text(user.bio!,
                style: AppTextStyles.body.copyWith(color: text, height: 1.5)),
            const SizedBox(height: 12),
          ] else if (_isOwnProfile) ...[
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Text('Add a bio…',
                  style: AppTextStyles.body
                      .copyWith(color: sub, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 12),
          ],

          // Tags
          if (user.tags.isNotEmpty) ...[
            _TagsRow(tags: user.tags, isOwn: _isOwnProfile),
            const SizedBox(height: 12),
          ] else if (_isOwnProfile) ...[
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: sub),
                    const SizedBox(width: 4),
                    Text('Add tags', style: AppTextStyles.footnote.copyWith(color: sub)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // College + location
          if (_hasLocation(user)) ...[
            _LocationLine(user: user, sub: sub),
            const SizedBox(height: 8),
          ],

          // Joined
          if (user.createdAt != null) ...[
            Text(_joinedLabel(user.createdAt!),
                style: AppTextStyles.caption.copyWith(color: sub)),
            const SizedBox(height: 12),
          ],

          // Verification card
          _VerificationCard(user: user, isOwn: _isOwnProfile, isDark: isDark, sub: sub),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _roleInstitutionLine(UserModel user, Color sub) {
    final parts = <String>[];
    if (user.isStudent) {
      if (user.yearOfStudy != null) parts.add('${user.yearOfStudy} ${user.roleLabel}');
      else parts.add(user.roleLabel);
      final inst = user.collegeName ?? user.college;
      if (inst != null) parts.add(inst);
    } else {
      if (user.specialty != null) parts.add(user.specialty!);
      final inst = user.hospital ?? user.collegeName ?? user.college;
      if (inst != null) parts.add(inst);
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTextStyles.subheadline.copyWith(color: sub),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool _hasLocation(UserModel user) =>
      (user.collegeName ?? user.college) != null ||
      (user.collegeCity ?? user.city) != null;

  String _joinedLabel(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Member since ${m[dt.month - 1]} ${dt.year}';
  }

  void _goToFollowers() {
    if (_user == null) return;
    context.push('/profile/${_user!.id}/followers');
  }

  void _goToFollowing() {
    if (_user == null) return;
    context.push('/profile/${_user!.id}/following');
  }

  Widget _buildTabContent(UserModel user, bool isDark, Color text, Color sub) {
    switch (_tab) {
      case 0:
        return _PostsTab(user: user, isDark: isDark, text: text, sub: sub, isOwn: _isOwnProfile);
      case 1:
        return _isOwnProfile
            ? _SessionsTab(isDark: isDark, text: text, sub: sub)
            : _AboutTab(user: user, isDark: isDark, text: text, sub: sub);
      case 2:
        return _AboutTab(user: user, isDark: isDark, text: text, sub: sub);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Avatar widget ─────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.user, required this.loading, this.onTap});
  final UserModel user;
  final bool loading;
  final VoidCallback? onTap;

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
            ),
            child: ClipOval(
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsWidget(),
                    )
                  : _initialsWidget(),
            ),
          ),
          if (onTap != null)
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black : Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(Icons.camera_alt, size: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black : Colors.white),
              ),
            ),
          if (loading)
            Positioned.fill(
              child: ClipOval(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialsWidget() => Container(
    color: AppColors.teal,
    child: Center(
      child: Text(_initials,
          style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
    ),
  );
}

// ─── Verification chip ─────────────────────────────────────────────────────────

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (user.isVerified) {
      return _chip(Icons.verified, 'Verified', AppColors.teal);
    }
    if (user.isProofSubmitted) {
      return _chip(Icons.hourglass_empty, 'Under Review', Colors.amber);
    }
    if (user.isSuspended) {
      return _chip(Icons.block, 'Suspended', AppColors.danger);
    }
    return GestureDetector(
      onTap: () => context.push('/register/proof-upload'),
      child: _chip(Icons.shield_outlined, 'Unverified · Upload proof', Colors.grey),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── Fame badge ────────────────────────────────────────────────────────────────

class _FameBadge extends StatelessWidget {
  const _FameBadge({required this.tier});
  final String tier;

  Color get _color {
    switch (tier) {
      case 'fellow': return const Color(0xFFFFCC00);
      case 'top_educator': return const Color(0xFFFFCC00);
      case 'notable': return const Color(0xFF007AFF);
      default: return Colors.grey;
    }
  }

  String get _label {
    switch (tier) {
      case 'fellow': return 'MedGraph Fellow';
      case 'top_educator': return 'Top Educator';
      case 'notable': return 'Notable';
      default: return 'Rising';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(_label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.user,
    required this.onFollowers,
    required this.onFollowing,
  });
  final UserModel user;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(value: _fmt(user.followerCount), label: 'Followers',
                onTap: onFollowers),
            _vDivider(border),
            _StatCell(value: _fmt(user.followingCount), label: 'Following',
                onTap: onFollowing),
            _vDivider(border),
            _StatCell(value: _fmt(user.sessionCount), label: 'Sessions'),
            _vDivider(border),
            _StatCell(
              value: user.leaderboardRank != null ? '#${user.leaderboardRank}' : '—',
              label: 'Rank',
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider(Color color) =>
      Container(width: 0.5, color: color);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.onTap});
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: sub)),
          ],
        ),
      ),
    );
  }
}

// ─── Action buttons (other profiles) ──────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isFollowing,
    required this.loading,
    required this.onFollow,
    required this.onSession,
  });
  final bool isFollowing;
  final bool loading;
  final VoidCallback onFollow;
  final VoidCallback onSession;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: loading ? null : onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.transparent
                    : AppColors.teal,
                foregroundColor: isFollowing ? text : Colors.white,
                elevation: 0,
                side: isFollowing
                    ? BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isFollowing ? text : Colors.white),
                    )
                  : Text(isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onSession,
              style: OutlinedButton.styleFrom(
                foregroundColor: text,
                side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Session',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tags row ──────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags, required this.isOwn});
  final List<String> tags;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...tags.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                    color: AppColors.teal.withValues(alpha: 0.08),
                  ),
                  child: Text(t,
                      style: AppTextStyles.footnote.copyWith(
                          color: AppColors.teal, fontWeight: FontWeight.w500)),
                ),
              )),
          if (isOwn)
            GestureDetector(
              onTap: () => GoRouter.of(context).push('/profile/edit'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.add, size: 14, color: AppColors.teal),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Location line ─────────────────────────────────────────────────────────────

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.user, required this.sub});
  final UserModel user;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    final college = user.collegeName ?? user.college;
    final city    = user.collegeCity ?? user.city;
    final state   = user.collegeState ?? user.state;
    if (college != null) parts.add('🏛 $college');
    final loc = [city, state].where((e) => e != null).join(', ');
    if (loc.isNotEmpty) parts.add('📍 $loc');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join('  '),
        style: AppTextStyles.footnote.copyWith(color: sub));
  }
}

// ─── Verification card ─────────────────────────────────────────────────────────

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.user,
    required this.isOwn,
    required this.isDark,
    required this.sub,
  });
  final UserModel user;
  final bool isOwn;
  final bool isDark;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    Widget? card;

    if (!user.isVerified && isOwn) {
      card = GestureDetector(
        onTap: () => context.push('/register/proof-upload'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: sub, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Get verified',
                        style: AppTextStyles.footnote.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black)),
                    Text('Upload your credentials to get your verified badge',
                        style: AppTextStyles.caption.copyWith(color: sub)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: sub, size: 18),
            ],
          ),
        ),
      );
    } else if (user.isProofSubmitted && isOwn) {
      card = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty, color: Colors.amber, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verification under review',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A5600))),
                  const Text('Usually within 24 hours',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7A5600))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (user.vouchCount > 0) {
      final vouchRow = Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '✓ ${user.vouchCount} peer${user.vouchCount == 1 ? '' : 's'} vouched for this profile',
          style: AppTextStyles.caption.copyWith(color: sub),
        ),
      );
      if (card != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [card, vouchRow],
        );
      }
      return vouchRow;
    }

    return card ?? const SizedBox.shrink();
  }
}

// ─── Tab bar delegate ──────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.tabCtrl, required this.isDark, required this.bg});
  final TabController tabCtrl;
  final bool isDark;
  final Color bg;

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text   = isDark ? Colors.white : Colors.black;
    return Container(
      color: bg,
      child: Column(
        children: [
          Container(height: 0.5, color: border),
          TabBar(
            controller: tabCtrl,
            labelColor: text,
            unselectedLabelColor:
                isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
            indicatorColor: text,
            indicatorWeight: 2,
            labelStyle: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.footnote,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Sessions'),
              Tab(text: 'About'),
            ],
          ),
          Container(height: 0.5, color: border),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.isDark != isDark || old.tabCtrl != tabCtrl;
}

// ─── Posts tab ─────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.user,
    required this.isDark,
    required this.text,
    required this.sub,
    required this.isOwn,
  });
  final UserModel user;
  final bool isDark, isOwn;
  final Color text, sub;

  @override
  Widget build(BuildContext context) {
    if (user.postCount == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.video_camera_back_outlined, size: 48, color: sub),
            const SizedBox(height: 12),
            Text('No posts yet',
                style: AppTextStyles.headline.copyWith(color: text)),
            if (isOwn) ...[
              const SizedBox(height: 8),
              Text('Share your first Round',
                  style: AppTextStyles.subheadline.copyWith(color: sub)),
            ],
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: user.postCount.clamp(0, 30),
      itemBuilder: (_, i) => Container(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 28),
        ),
      ),
    );
  }
}

// ─── Sessions tab ──────────────────────────────────────────────────────────────

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.isDark, required this.text, required this.sub});
  final bool isDark;
  final Color text, sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 40, color: sub),
          const SizedBox(height: 12),
          Text('No upcoming sessions',
              style: AppTextStyles.headline.copyWith(color: text)),
          const SizedBox(height: 8),
          Text('Book a 1-on-1 session to study with peers',
              style: AppTextStyles.subheadline.copyWith(color: sub),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.push('/sessions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: text,
              side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Browse sessions'),
          ),
        ],
      ),
    );
  }
}

// ─── About tab ─────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.user,
    required this.isDark,
    required this.text,
    required this.sub,
  });
  final UserModel user;
  final bool isDark;
  final Color text, sub;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border  = isDark ? AppColors.darkBorder  : AppColors.lightBorder;

    final rows = <_AboutRow>[];

    if (user.isStudent) {
      rows.add(_AboutRow('📚', 'Program', user.roleLabel));
      if (user.yearOfStudy != null)
        rows.add(_AboutRow('📅', 'Year', user.yearOfStudy!));
      final college = user.collegeName ?? user.college;
      if (college != null) rows.add(_AboutRow('🏛', 'College', college));
      if (user.university != null)
        rows.add(_AboutRow('🎓', 'University', user.university!));
      final city  = user.collegeCity ?? user.city;
      final state = user.collegeState ?? user.state;
      final loc   = [city, state].where((e) => e != null).join(', ');
      if (loc.isNotEmpty) rows.add(_AboutRow('📍', 'Location', loc));
    } else {
      if (user.specialty != null)
        rows.add(_AboutRow('🩺', 'Specialty', user.specialty!));
      final inst = user.hospital ?? user.collegeName ?? user.college;
      if (inst != null) rows.add(_AboutRow('🏥', 'Institution', inst));
      final city  = user.city;
      final state = user.state;
      final loc   = [city, state].where((e) => e != null).join(', ');
      if (loc.isNotEmpty) rows.add(_AboutRow('📍', 'Location', loc));
      if (user.isVerified)
        rows.add(_AboutRow('✓', 'NMC', 'Verified'));
    }

    if (user.languages.isNotEmpty)
      rows.add(_AboutRow('🗣', 'Languages', user.languages.join(', ')));

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text('No details added yet.',
              style: AppTextStyles.body.copyWith(color: sub)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Column(
          children: List.generate(rows.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Divider(height: 0.5, thickness: 0.5, color: border,
                  indent: 16, endIndent: 0);
            }
            final r = rows[i ~/ 2];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Text(r.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Text(r.label,
                      style: AppTextStyles.footnote.copyWith(color: sub)),
                  const Spacer(),
                  Text(r.value,
                      style: AppTextStyles.footnote.copyWith(
                          color: text, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AboutRow {
  const _AboutRow(this.emoji, this.label, this.value);
  final String emoji, label, value;
}

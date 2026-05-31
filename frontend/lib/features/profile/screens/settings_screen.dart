import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/services/auth_storage.dart';
import '../../../shared/services/api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _matchBds           = false;
  bool _sameCollege        = false;
  bool _sameCity           = false;
  bool _sameState          = false;
  bool _savingFilter       = false;
  String _profileVisibility = 'public';
  bool _showOnlineStatus   = true;
  bool _showSessionCount   = true;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider);
    if (u != null) {
      _matchBds             = u.proFilterMatchBds;
      _sameCollege          = u.proFilterSameCollege;
      _sameCity             = u.proFilterSameCity;
      _sameState            = u.proFilterSameState;
    }
  }

  Future<void> _savePref(String key, dynamic val) async {
    if (_savingFilter) return;
    setState(() => _savingFilter = true);
    try {
      await ApiService.put('/api/profiles/me', {key: val});
    } catch (_) {}
    if (mounted) setState(() => _savingFilter = false);
  }

  Future<void> _saveFilter(String key, bool val) => _savePref(key, val);

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(currentUserProvider.notifier).clearUser();
      await AuthStorage.clear();
      if (mounted) context.go('/');
    }
  }

  Future<void> _deactivate() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
          'Your profile will be hidden from other users.\n'
          'Contact support to reactivate your account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse(
                  'mailto:aryandevagarwal89000@gmail.com?subject=Account Deactivation'));
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bg     = isDark ? Colors.black : Colors.white;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border  = isDark ? AppColors.darkBorder  : AppColors.lightBorder;

    final isPro = ref.read(currentUserProvider.notifier).isPro;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: AppTextStyles.headline.copyWith(color: text)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [

          // ── ACCOUNT ─────────────────────────────────────────────────────────
          _SectionHeader('ACCOUNT', sub),
          _SettingsTile(
            surface: surface, border: border, isDark: isDark, isFirst: true,
            children: [
              _NavRow(icon: Icons.person_outline, label: 'Edit Profile',
                  text: text, sub: sub,
                  onTap: () => context.push('/profile/edit')),
              _Divider(border),
              _NavRow(
                icon: Icons.verified_outlined,
                label: 'Verification',
                subtitle: user?.isVerified == true
                    ? 'Verified ✓'
                    : user?.isProofSubmitted == true
                        ? 'Under Review'
                        : 'Not verified',
                text: text, sub: sub,
                onTap: () => context.push('/register/proof-upload'),
              ),
              _Divider(border),
              _NavRow(icon: Icons.notifications_outlined, label: 'Notifications',
                  text: text, sub: sub,
                  onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),

          // ── SUBSCRIPTION ────────────────────────────────────────────────────
          _SectionHeader('SUBSCRIPTION', sub),
          _SettingsTile(
            surface: surface, border: border, isDark: isDark,
            children: [
              if (!isPro)
                _NavRow(
                  icon: Icons.star_outline,
                  label: 'Upgrade to Pro',
                  subtitle: '₹99/month — unlimited sessions + filters',
                  text: text, sub: sub,
                  onTap: () => context.push('/upgrade'),
                  trailingColor: AppColors.teal,
                )
              else
                _NavRow(
                  icon: Icons.star,
                  label: 'Pro Plan Active',
                  subtitle: user?.proExpiresAt != null
                      ? 'Expires ${_fmtDate(user!.proExpiresAt!)}'
                      : 'Active',
                  text: text, sub: sub,
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── MATCHING FILTERS (available during free Pro period) ──────────────
          _SectionHeader('MATCHING FILTERS', sub),
          _SettingsTile(
            surface: surface, border: border, isDark: isDark,
            children: [
              _ToggleRow(
                icon: Icons.diversity_3_outlined,
                label: 'Match with BDS students',
                text: text, sub: sub,
                value: _matchBds,
                onChanged: (v) { setState(() => _matchBds = v); _saveFilter('pro_filter_match_bds', v); },
              ),
              _Divider(border),
              _ToggleRow(
                icon: Icons.school_outlined,
                label: 'Same college only',
                text: text, sub: sub,
                value: _sameCollege,
                onChanged: (v) { setState(() => _sameCollege = v); _saveFilter('pro_filter_same_college', v); },
              ),
              _Divider(border),
              _ToggleRow(
                icon: Icons.location_city_outlined,
                label: 'Same city only',
                text: text, sub: sub,
                value: _sameCity,
                onChanged: (v) { setState(() => _sameCity = v); _saveFilter('pro_filter_same_city', v); },
              ),
              _Divider(border),
              _ToggleRow(
                icon: Icons.map_outlined,
                label: 'Same state only',
                text: text, sub: sub,
                value: _sameState,
                onChanged: (v) { setState(() => _sameState = v); _saveFilter('pro_filter_same_state', v); },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── PRIVACY ─────────────────────────────────────────────────────────
          _SectionHeader('PRIVACY', sub),
          _SettingsTile(
            surface: surface, border: border, isDark: isDark,
            children: [
              ListTile(
                leading: Icon(Icons.visibility_outlined, color: text, size: 20),
                title: Text('Profile Visibility',
                    style: AppTextStyles.subheadline.copyWith(color: text)),
                subtitle: Text(
                  _profileVisibility == 'public' ? 'Public' : 'Connections only',
                  style: AppTextStyles.caption.copyWith(color: sub),
                ),
                trailing: Icon(Icons.chevron_right, color: sub, size: 18),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Profile Visibility',
                            style: AppTextStyles.headline.copyWith(color: text)),
                        const SizedBox(height: 16),
                        RadioListTile<String>(
                          title: Text('Public', style: AppTextStyles.subheadline.copyWith(color: text)),
                          subtitle: Text('Anyone can view your profile',
                              style: AppTextStyles.caption.copyWith(color: sub)),
                          value: 'public',
                          groupValue: _profileVisibility,
                          activeColor: AppColors.teal,
                          onChanged: (v) {
                            setState(() => _profileVisibility = v!);
                            Navigator.pop(context);
                            _savePref('profile_visibility', v);
                          },
                        ),
                        RadioListTile<String>(
                          title: Text('Connections only',
                              style: AppTextStyles.subheadline.copyWith(color: text)),
                          subtitle: Text('Only followers can view your profile',
                              style: AppTextStyles.caption.copyWith(color: sub)),
                          value: 'connections',
                          groupValue: _profileVisibility,
                          activeColor: AppColors.teal,
                          onChanged: (v) {
                            setState(() => _profileVisibility = v!);
                            Navigator.pop(context);
                            _savePref('profile_visibility', v);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              _Divider(border),
              _ToggleRow(
                icon: Icons.circle_outlined,
                label: 'Show online status',
                text: text, sub: sub,
                value: _showOnlineStatus,
                onChanged: (v) { setState(() => _showOnlineStatus = v); _savePref('show_online_status', v); },
              ),
              _Divider(border),
              _ToggleRow(
                icon: Icons.bar_chart_outlined,
                label: 'Show session count',
                text: text, sub: sub,
                value: _showSessionCount,
                onChanged: (v) { setState(() => _showSessionCount = v); _savePref('show_session_count', v); },
              ),
              _Divider(border),
              _NavRow(
                icon: Icons.block_outlined,
                label: 'Blocked Accounts',
                text: text, sub: sub,
                onTap: () => context.push('/settings/blocked'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── SUPPORT ─────────────────────────────────────────────────────────
          _SectionHeader('SUPPORT', sub),
          _SettingsTile(
            surface: surface, border: border, isDark: isDark,
            children: [
              _NavRow(icon: Icons.help_outline, label: 'Help & FAQ',
                  text: text, sub: sub,
                  onTap: () {}),
              _Divider(border),
              _NavRow(icon: Icons.email_outlined, label: 'Contact Support',
                  text: text, sub: sub,
                  onTap: () => launchUrl(Uri.parse(
                      'mailto:aryandevagarwal89000@gmail.com?subject=MedGraph Support'))),
              _Divider(border),
              _NavRow(icon: Icons.article_outlined, label: 'Terms of Service',
                  text: text, sub: sub,
                  onTap: () => context.push('/legal/terms')),
              _Divider(border),
              _NavRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy',
                  text: text, sub: sub,
                  onTap: () => context.push('/legal/privacy')),
              _Divider(border),
              _NavRow(icon: Icons.info_outline, label: 'About MedGraph',
                  text: text, sub: sub,
                  onTap: () => context.push('/about')),
            ],
          ),
          const SizedBox(height: 24),

          // ── ACCOUNT ACTIONS ──────────────────────────────────────────────────
          _SectionHeader('ACCOUNT ACTIONS', sub),
          _SettingsTile(
            surface: surface, border: border, isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Log out',
                    style: TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.w500)),
                onTap: _logout,
              ),
              _Divider(border),
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: sub),
                title: Text('Deactivate Account',
                    style: AppTextStyles.subheadline.copyWith(color: sub)),
                onTap: _deactivate,
              ),
            ],
          ),
          const SizedBox(height: 48),

          // ── Footer ───────────────────────────────────────────────────────────
          Center(
            child: Text('MedGraph v1.0 · Built in India 🇮🇳',
                style: AppTextStyles.caption.copyWith(color: sub)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.year}';
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: 0.6)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.surface,
    required this.border,
    required this.isDark,
    required this.children,
    this.isFirst = false,
  });
  final Color surface, border;
  final bool isDark, isFirst;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.sub,
    required this.onTap,
    this.subtitle,
    this.trailingColor,
  });
  final IconData icon;
  final String label;
  final Color text, sub;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: text, size: 20),
      title: Text(label, style: AppTextStyles.subheadline.copyWith(color: text)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption.copyWith(color: sub))
          : null,
      trailing: Icon(Icons.chevron_right,
          color: trailingColor ?? sub, size: 18),
      onTap: onTap,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final Color text, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: text, size: 20),
      title: Text(label, style: AppTextStyles.subheadline.copyWith(color: text)),
      value: value,
      activeColor: AppColors.teal,
      onChanged: onChanged,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 0.5, thickness: 0.5, indent: 16, color: color);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../shared/widgets/disclaimer_overlay.dart';

/// Shell that wraps authenticated screens with bottom nav (mobile)
/// or left sidebar (desktop ≥ 600px).
/// Loads the current user profile once on first mount so all child
/// screens can read currentUserProvider without it being null.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/home'),
    _TabItem(icon: Icons.play_circle_outline, activeIcon: Icons.play_circle, label: 'Feed', path: '/feed'),
    _TabItem(icon: Icons.radio_button_unchecked, activeIcon: Icons.radio_button_checked, label: 'Match', path: '/roulette'),
    _TabItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Sessions', path: '/sessions'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    // Load user profile once when the authenticated shell first mounts.
    // This ensures currentUserProvider is never null inside any tab screen.
    if (ref.read(currentUserProvider) == null) {
      ref.read(currentUserProvider.notifier).loadUser('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileScaffold(tabs: _tabs, child: widget.child),
      desktop: _DesktopScaffold(tabs: _tabs, child: widget.child),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({required this.tabs, required this.child});
  final Widget child;
  final List<_TabItem> tabs;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isActive = i == idx;
                final isCenter = i == 2; // Match button

                if (isCenter) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context.go(tab.path),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tab.activeIcon,
                            color: isDark ? Colors.black : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          size: 22,
                          color: isActive
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? AppColors.darkTertiary : AppColors.lightTertiary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? AppColors.darkTertiary : AppColors.lightTertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({required this.tabs, required this.child});
  final Widget child;
  final List<_TabItem> tabs;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idx = _currentIndex(context);
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 220,
            color: bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'MedGraph',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ...List.generate(tabs.length, (i) {
                  final tab = tabs[i];
                  final isActive = i == idx;
                  return ListTile(
                    leading: Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      color: isActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                    ),
                    title: Text(
                      tab.label,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
                      ),
                    ),
                    onTap: () => context.go(tab.path),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
                const Spacer(),
                // Legal links + disclaimer footer
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/legal/terms'),
                            child: Text(
                              'Terms',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTertiary
                                    : AppColors.lightTertiary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTertiary
                                  : AppColors.lightTertiary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/legal/privacy'),
                            child: Text(
                              'Privacy',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTertiary
                                    : AppColors.lightTertiary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DisclaimerOverlay(
                        variant: DisclaimerVariant.footer,
                        onDismiss: () => context.push('/legal/terms'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(width: 0.5, color: border),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import '../focus/focus_screen.dart';
import '../planner/planner_screen.dart';
import '../growth/growth_screen.dart';
import '../profile/profile_screen.dart';

enum NavItem { home, habits, growth, profile }

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppProvider, ThemeProvider, ProgressionProvider>(
      builder: (context, app, theme, progression, _) {
        final p = theme.paletteData;
        final day = progression.appDayNumber;

        final tabs = _buildTabs(day);
        final screens = _buildScreens(day);
        final currentIndex = app.currentNavIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          backgroundColor: p.bg,
          body: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
          bottomNavigationBar: _ProgressiveNavBar(
            tabs: tabs,
            currentIndex: currentIndex,
            p: p,
            day: day,
            onTap: (i) => app.setNavIndex(i),
          ),
        );
      },
    );
  }

  List<_NavTab> _buildTabs(int day) {
    return [
      _NavTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        item: NavItem.home,
        available: true,
      ),
      _NavTab(
        icon: Icons.timer_outlined,
        activeIcon: Icons.timer_rounded,
        item: NavItem.habits,
        available: day >= 4,
        unlockDay: 4,
      ),
      _NavTab(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        item: NavItem.growth,
        available: day >= 14,
        unlockDay: 14,
      ),
      _NavTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        item: NavItem.profile,
        available: true,
      ),
    ];
  }

  List<Widget> _buildScreens(int day) {
    return [
      const HomeScreen(),
      day >= 4 ? const FocusScreen() : _ComingSoonScreen(item: NavItem.habits, unlockDay: 4),
      day >= 14 ? const PlannerScreen() : _ComingSoonScreen(item: NavItem.growth, unlockDay: 14),
      const ProfileScreen(),
    ];
  }
}

// ── Tab data ──────────────────────────────────────────────────────────────────
class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final NavItem item;
  final bool available;
  final int? unlockDay;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.item,
    required this.available,
    this.unlockDay,
  });
}

// ── Nav Bar progressiva ───────────────────────────────────────────────────────
class _ProgressiveNavBar extends StatelessWidget {
  final List<_NavTab> tabs;
  final int currentIndex;
  final BwPaletteData p;
  final int day;
  final ValueChanged<int> onTap;

  const _ProgressiveNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.p,
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.nav,
        border: Border(top: BorderSide(color: p.navBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isActive = i == currentIndex;
              final isAvailable = tab.available;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isAvailable) {
                      onTap(i);
                    } else {
                      _showUnlockHint(context, tab);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    opacity: isAvailable ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              size: 22,
                              color: isActive ? p.primary : p.textMut,
                            ),
                            if (!isAvailable)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: p.bg2,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: p.cardBorder, width: 0.5),
                                  ),
                                  child: Icon(Icons.lock_outline,
                                      size: 8, color: p.textMut),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _translateLabel(context, tab.item),
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? p.primary : p.textMut,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? p.primary : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _translateLabel(BuildContext context, NavItem item) {
    final s = context.sL;
    switch (item) {
      case NavItem.home:    return s.navHome;
      case NavItem.habits:  return s.navHabits;
      case NavItem.growth:  return s.navGrowth;
      case 'Focus':   return s.navFocus;
      case 'Plan':    return s.navPlan;
      case NavItem.profile: return s.navProfile;
    }
  }

  void _showUnlockHint(BuildContext context, _NavTab tab) {
    if (tab.unlockDay == null) return;
    final daysLeft = tab.unlockDay! - day;
    final s = context.sL;
    final label = _translateLabel(context, tab.item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          daysLeft <= 1
              ? '$label ${s.unlocksTomorrow}'
              : '$label ${s.unlocksIn} $daysLeft ${s.days}.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Coming Soon ───────────────────────────────────────────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  final NavItem item;
  final int unlockDay;
  const _ComingSoonScreen({required this.item, required this.unlockDay});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final progression = context.read<ProgressionProvider>();
    final daysLeft = (unlockDay - progression.appDayNumber).clamp(0, 99);
    final s = context.sL;
    final translatedLabel = item == NavItem.habits ? s.navHabits : s.navGrowth;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/companion/companion_base.png',
                  width: 120,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.lock_outline, size: 48, color: p.textMut),
                ),
                const SizedBox(height: 24),
                Text(
                  '$translatedLabel...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  daysLeft <= 1
                      ? '$translatedLabel ${s.unlocksTomorrow}'
                      : '${s.unlocksIn} $daysLeft ${s.days}.',
                  style: TextStyle(
                    fontSize: 15,
                    color: p.textSec,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import 'home_screen.dart';
import '../focus/focus_screen.dart';
import '../planner/planner_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _screens = [
    HomeScreen(),
    FocusScreen(),
    PlannerScreen(),
    MarketplaceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, ThemeProvider>(
      builder: (context, app, theme, _) {
        final p = theme.paletteData;
        return Scaffold(
          backgroundColor: p.bg,
          body: IndexedStack(
            index: app.currentNavIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: p.nav,
              border: Border(
                top: BorderSide(color: p.navBorder, width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: app.currentNavIndex,
              onTap: app.setNavIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: p.primary,
              unselectedItemColor: p.textMut,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  activeIcon: Icon(Icons.timer_rounded),
                  label: 'Focus',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today_rounded),
                  label: 'Piano',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined),
                  activeIcon: Icon(Icons.storefront_rounded),
                  label: 'Premi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profilo',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

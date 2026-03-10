import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import '../planner/planner_screen.dart';
import '../focus/focus_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _screens = [
    HomeScreen(),
    PlannerScreen(),
    FocusScreen(),
    MarketplaceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, p, _) {
        return Scaffold(
          body: IndexedStack(
            index: p.currentNavIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BwColors.panelBorder)),
            ),
            child: BottomNavigationBar(
              currentIndex: p.currentNavIndex,
              onTap: p.setNavIndex,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today_rounded),
                  label: 'Piano',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  activeIcon: Icon(Icons.timer_rounded),
                  label: 'Focus',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined),
                  activeIcon: Icon(Icons.storefront_rounded),
                  label: 'Market',
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

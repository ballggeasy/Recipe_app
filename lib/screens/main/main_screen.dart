import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../search/advanced_search_screen.dart';
import '../meal_planner/meal_planner_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';

/// หน้าหลักพร้อม Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AdvancedSearchScreen(),
    MealPlannerScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surf(context),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primLight(context),
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
          destinations: [
            _navDest(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'หน้าแรก',
              index: 0,
            ),
            _navDest(
              icon: Icons.search_rounded,
              selectedIcon: Icons.search_rounded,
              label: 'ค้นหา',
              index: 1,
            ),
            _navDest(
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_today_rounded,
              label: 'แผนมื้อ',
              index: 2,
            ),
            _navDest(
              icon: Icons.favorite_border_rounded,
              selectedIcon: Icons.favorite_rounded,
              label: 'โปรด',
              index: 3,
            ),
            _navDest(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'โปรไฟล์',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _navDest({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.prim(context) : AppTheme.txtSecondary(context);
    return NavigationDestination(
      icon: Icon(icon, color: color),
      selectedIcon: Icon(selectedIcon, color: AppTheme.prim(context)),
      label: label,
    );
  }
}

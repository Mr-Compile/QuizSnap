import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.style),
          label: 'Decks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome),
          label: 'AI Generate',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Study',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

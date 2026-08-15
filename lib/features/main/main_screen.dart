import 'package:flutter/material.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../core/navigation/back_button_handler.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../study/study_home_screen.dart';
import '../ai_generate/ai_generate_home_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // NOTE: PIN lock is handled exclusively by the GoRouter redirect in
  // AppRouter.  This screen must NOT show its own PinLockScreen or call
  // SecurityProvider.initialize() — doing so caused a relock loop where
  // initialize() re-set _isLocked = _isPinEnabled after every unlock.
  //
  // Each tab screen renders its own AppBar (with its title and contextual
  // actions).  MainScreen intentionally does NOT add an AppBar so that the
  // active tab's title is shown exactly once (previously the Library tab
  // displayed a duplicate "Library" title).

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler.withExitProtection(
      context: context,
      message: 'Press back again to exit QuizSnap',
      child: Scaffold(
        body: SafeArea(
          child: _buildCurrentScreen(),
        ),
        bottomNavigationBar: MainBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1200 ? 1200.0 : double.infinity;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _getScreenForIndex(_currentIndex),
        );
      },
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const AnalyticsDashboardScreen();
      case 1:
        return const LibraryScreen();
      case 2:
        return const StudyHomeScreen();
      case 3:
        return const AiGenerateHomeScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const AnalyticsDashboardScreen();
    }
  }
}

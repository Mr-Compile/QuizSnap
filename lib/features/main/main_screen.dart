import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../core/providers/security_provider.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../core/navigation/app_routes.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../study/study_home_screen.dart';
import '../ai_generate/ai_generate_home_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../settings/pin_lock_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    final securityProvider = context.read<SecurityProvider>();
    await securityProvider.initialize();
    
    if (mounted && securityProvider.isLocked) {
      _showPinLock();
    }
  }

  void _showPinLock() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinLockScreen(),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Recheck lock state after returning
      if (mounted) {
        final securityProvider = context.read<SecurityProvider>();
        if (securityProvider.isLocked) {
          _showPinLock();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, securityProvider, child) {
        // Show PIN lock if the app is locked
        if (securityProvider.isLocked) {
          return const PinLockScreen();
        }

        return BackButtonHandler.withExitProtection(
          context: context,
          message: 'Press back again to exit QuizSnap',
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _getAppBarTitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    GoRouter.of(context).push(AppRoutes.settings);
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: _buildCurrentScreen(),
            ),
            bottomNavigationBar: MainBottomNavigation(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        );
      },
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
        return const LibraryScreen();
      case 1:
        return const AiGenerateHomeScreen();
      case 2:
        return const StudyHomeScreen();
      case 3:
        return const AnalyticsDashboardScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const LibraryScreen();
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Library';
      case 1:
        return 'AI Generate';
      case 2:
        return 'Study';
      case 3:
        return 'Progress';
      case 4:
        return 'Settings';
      default:
        return 'QuizSnap';
    }
  }
}

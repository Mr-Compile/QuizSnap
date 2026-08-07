import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../core/providers/security_provider.dart';
import '../../core/navigation/back_button_handler.dart';
import '../decks/deck_list_screen.dart';
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
            body: _buildCurrentScreen(),
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
    switch (_currentIndex) {
      case 0:
        return const DeckListScreen();
      case 1:
        return const AiGenerateHomeScreen();
      case 2:
        return const StudyHomeScreen();
      case 3:
        return const AnalyticsDashboardScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DeckListScreen();
    }
  }
}

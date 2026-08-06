import 'package:flutter/material.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../decks/deck_list_screen.dart';
import '../search/global_search_screen.dart';
import '../trash/trash_screen.dart';
import '../tags/tag_management_screen.dart';
import '../folders/folder_list_screen.dart';
import '../settings/appearance_screen.dart';
import '../exam/cached_explanations_screen.dart';
import '../study/study_home_screen.dart';
import '../ai_generate/ai_generate_home_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('Folders'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FolderListScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.local_offer),
          title: const Text('Tags'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TagManagementScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('Search'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GlobalSearchScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Trash'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TrashScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Appearance'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AppearanceScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lightbulb_outline),
          title: const Text('Cached Explanations'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CachedExplanationsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Show about dialog
          },
        ),
      ],
    );
  }
}

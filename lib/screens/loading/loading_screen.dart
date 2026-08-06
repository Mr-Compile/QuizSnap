import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/database_provider.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Load theme preference
      await Future.delayed(const Duration(milliseconds: 500));
      final themeProvider = context.read<ThemeProvider>();
      await themeProvider.loadThemePreference();

      // Step 2: Open SQLite database
      await Future.delayed(const Duration(milliseconds: 500));
      final databaseProvider = context.read<DatabaseProvider>();
      await databaseProvider.initialize();

      // Step 3: Load folders/decks
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Load folders and decks from database

      // Step 4: Check secure storage for Groq API key
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Check for Groq API key in secure storage

      // Step 5: Prepare prompt templates
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Load prompt templates

      // Step 6: Navigate to appropriate screen
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Check if this is first launch
        final isFirstLaunch = await _checkFirstLaunch();
        
        if (isFirstLaunch) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<bool> _checkFirstLaunch() async {
    // TODO: Implement first launch check using shared_preferences
    return true; // For now, always show onboarding
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text('Failed to initialize the app: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.slate900 : AppTheme.slate50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bambooGreen600,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.bambooGreen600.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flash_on,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'QuizSnap',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.slate800,
              ),
            ),
            const SizedBox(height: 32),

            // Loading steps
            const _LoadingStep(text: 'Loading theme preference...'),
            const _LoadingStep(text: 'Opening database...'),
            const _LoadingStep(text: 'Loading flashcard decks...'),
            const _LoadingStep(text: 'Checking API configuration...'),
            const _LoadingStep(text: 'Preparing prompt templates...'),
            const SizedBox(height: 32),

            // Progress indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bambooGreen600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingStep extends StatelessWidget {
  final String text;

  const _LoadingStep({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bambooGreen600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.slate400
                    : AppTheme.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
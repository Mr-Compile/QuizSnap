import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/groq_provider.dart';
import 'core/providers/exam_provider.dart';
import 'core/services/explanation_cache_service.dart';
import 'features/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(QuizSnapApp(prefs: prefs));
}

class QuizSnapApp extends StatelessWidget {
  final SharedPreferences prefs;

  const QuizSnapApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => GroqProvider()),
        ProxyProvider2<DatabaseProvider, GroqProvider, ExamProvider>(
          update: (context, dbProvider, groqProvider, previous) {
            final cacheService = ExplanationCacheService(prefs);
            return previous ?? ExamProvider(
              flashcardRepository: dbProvider.flashcardRepository,
              cacheService: cacheService,
              groqService: groqProvider.service,
            );
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'QuizSnap',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
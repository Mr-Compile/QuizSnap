import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/groq_provider.dart';
import 'core/providers/ai_quota_provider.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/reminder_provider.dart';
import 'core/providers/exam_provider.dart';
import 'core/providers/export_provider.dart';
import 'core/services/explanation_cache_service.dart';
import 'core/navigation/app_router.dart';

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
        // GroqProvider will auto-initialize from secure storage in its constructor
        ChangeNotifierProvider(create: (_) => GroqProvider()),
        ChangeNotifierProxyProvider<DatabaseProvider, AiQuotaProvider>(
          create: (context) => AiQuotaProvider(context.read<DatabaseProvider>()),
          update: (context, dbProvider, previous) {
            return previous ?? AiQuotaProvider(dbProvider);
          },
        ),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ProxyProvider2<DatabaseProvider, GroqProvider, ExamProvider>(
          update: (context, dbProvider, groqProvider, previous) {
            return previous ?? ExamProvider(
              flashcardRepository: dbProvider.flashcardRepository,
              cacheService: ExplanationCacheService(prefs),
              groqService: groqProvider.service,
            );
          },
        ),
        ProxyProvider<DatabaseProvider, ExportProvider>(
          update: (context, dbProvider, previous) {
            return previous ?? ExportProvider(dbProvider.database);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'QuizSnap',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
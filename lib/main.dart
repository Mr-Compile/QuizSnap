import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'core/providers/deck_bookmark_provider.dart';
import 'core/providers/flashcard_reveal_provider.dart';
import 'core/providers/study_session_controller.dart';
import 'core/providers/backup_provider.dart';
import 'core/services/explanation_cache_service.dart';
import 'core/services/study_session_persistence.dart';
import 'core/repositories/recent_generation_repository.dart';
import 'core/repositories/cached_document_repository.dart';
import 'core/providers/highlighted_selection_provider.dart';
import 'core/providers/page_selection_provider.dart';
import 'core/providers/trash_provider.dart';
import 'core/providers/flashcard_selection_provider.dart';
import 'core/services/cleanup_scheduler.dart';
import 'core/services/trash_service.dart';
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize database for both Provider and Riverpod
  final dbProvider = DatabaseProvider();
  final database = await dbProvider.initializeDatabase();

  // Schedule a one-time trash cleanup in the background; the scheduler starts the daily timer disabled by default.
  unawaited(CleanupScheduler(database: database, prefs: prefs).runNow());

  runApp(
    ProviderScope(
      overrides: [
        // Override the Riverpod database provider with the actual database instance
        databaseProvider.overrideWithValue(database),
      ],
      child: QuizSnapApp(prefs: prefs, dbProvider: dbProvider),
    ),
  );
}

class QuizSnapApp extends StatelessWidget {
  final SharedPreferences prefs;
  final DatabaseProvider dbProvider;

  const QuizSnapApp({super.key, required this.prefs, required this.dbProvider});

  @override
  Widget build(BuildContext context) {
    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => ThemeProvider()),
        provider_pkg.ChangeNotifierProvider.value(value: dbProvider),
        // GroqProvider will auto-initialize from secure storage in its constructor
        provider_pkg.ChangeNotifierProvider(create: (_) => GroqProvider()),
        provider_pkg.ChangeNotifierProxyProvider<DatabaseProvider, AiQuotaProvider>(
          create: (context) => AiQuotaProvider(context.read<DatabaseProvider>()),
          update: (context, dbProvider, previous) {
            return previous ?? AiQuotaProvider(dbProvider);
          },
        ),
        provider_pkg.ChangeNotifierProvider(create: (_) => SecurityProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => ReminderProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => DeckBookmarkProvider(prefs)),
        provider_pkg.ChangeNotifierProvider(create: (_) => FlashcardRevealProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => StudySessionController(
          persistence: StudySessionPersistence(prefs),
        )),
        provider_pkg.ChangeNotifierProvider(create: (_) => RecentGenerationRepository(prefs)),
        provider_pkg.ChangeNotifierProxyProvider<DatabaseProvider, CachedDocumentRepository>(
          create: (context) => CachedDocumentRepository(context.read<DatabaseProvider>()),
          update: (context, db, previous) => previous ?? CachedDocumentRepository(db),
        ),
        provider_pkg.ChangeNotifierProvider(create: (_) => HighlightedSelectionProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => PageSelectionProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => FlashcardSelectionProvider()),
        provider_pkg.ChangeNotifierProvider(
          create: (context) => TrashProvider(
            TrashService(
              deckRepository: context.read<DatabaseProvider>().deckRepository,
              flashcardRepository: context.read<DatabaseProvider>().flashcardRepository,
            ),
          ),
        ),
        provider_pkg.ChangeNotifierProxyProvider2<DatabaseProvider, GroqProvider, ExamProvider>(
          create: (context) => ExamProvider(
            flashcardRepository: context.read<DatabaseProvider>().flashcardRepository,
            cacheService: ExplanationCacheService(prefs),
            groqService: context.read<GroqProvider>().service,
          ),
          update: (context, dbProvider, groqProvider, previous) {
            return previous ?? ExamProvider(
              flashcardRepository: dbProvider.flashcardRepository,
              cacheService: ExplanationCacheService(prefs),
              groqService: groqProvider.service,
            );
          },
        ),
        provider_pkg.ProxyProvider<DatabaseProvider, ExportProvider>(
          update: (context, dbProvider, previous) {
            return previous ?? ExportProvider(dbProvider.database);
          },
        ),
      ],
      child: provider_pkg.Consumer<ThemeProvider>(
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
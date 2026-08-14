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

  // Create SecurityProvider early so we can initialize it before runApp
  // and wire up the GoRouter refresh listener + lifecycle observer.
  final securityProvider = SecurityProvider();
  await securityProvider.initialize();

  // Schedule a one-time trash cleanup in the background; the scheduler starts the daily timer disabled by default.
  unawaited(CleanupScheduler(database: database, prefs: prefs).runNow());

  runApp(
    ProviderScope(
      overrides: [
        // Override the Riverpod database provider with the actual database instance
        databaseProvider.overrideWithValue(database),
      ],
      child: QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
      ),
    ),
  );
}

class QuizSnapApp extends StatefulWidget {
  final SharedPreferences prefs;
  final DatabaseProvider dbProvider;
  final SecurityProvider securityProvider;

  const QuizSnapApp({
    super.key,
    required this.prefs,
    required this.dbProvider,
    required this.securityProvider,
  });

  @override
  State<QuizSnapApp> createState() => _QuizSnapAppState();
}

class _QuizSnapAppState extends State<QuizSnapApp> with WidgetsBindingObserver {
  late final SecurityProvider _securityProvider;

  @override
  void initState() {
    super.initState();
    _securityProvider = widget.securityProvider;
    WidgetsBinding.instance.addObserver(this);

    // Bridge SecurityProvider state changes to GoRouter so the redirect
    // re-evaluates when the app is locked/unlocked (e.g. lifecycle events).
    _securityProvider.addListener(_onSecurityChanged);
  }

  @override
  void dispose() {
    _securityProvider.removeListener(_onSecurityChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onSecurityChanged() {
    // Trigger GoRouter to re-evaluate its redirect whenever the
    // SecurityProvider notifies (lock/unlock state changes).
    AppRouter.refresh();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background — lock on resume if PIN is enabled.
        // We don't lock here; we lock on resume to avoid locking during
        // transient inactive states (e.g. system dialogs).
        debugPrint('[QuizSnapApp] lifecycle: ${state.name}');
        break;
      case AppLifecycleState.detached:
        debugPrint('[QuizSnapApp] lifecycle: detached');
        break;
      case AppLifecycleState.resumed:
        // Lock the app once when returning from background, but only if
        // PIN is enabled and the app is not already locked.  This prevents
        // re-locking immediately after unlock (race condition guard).
        debugPrint('[QuizSnapApp] lifecycle: resumed');
        if (_securityProvider.isPinEnabled && !_securityProvider.isLocked) {
          debugPrint('[QuizSnapApp] locking app on resume');
          _securityProvider.lockApp();
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => ThemeProvider()),
        provider_pkg.ChangeNotifierProvider.value(value: widget.dbProvider),
        // GroqProvider will auto-initialize from secure storage in its constructor
        provider_pkg.ChangeNotifierProvider(create: (_) => GroqProvider()),
        provider_pkg.ChangeNotifierProxyProvider<DatabaseProvider, AiQuotaProvider>(
          create: (context) => AiQuotaProvider(context.read<DatabaseProvider>()),
          update: (context, dbProvider, previous) {
            return previous ?? AiQuotaProvider(dbProvider);
          },
        ),
        // SecurityProvider is created early in main() so it can be
        // initialized before runApp and wired to the router refresh.
        provider_pkg.ChangeNotifierProvider.value(value: _securityProvider),
        provider_pkg.ChangeNotifierProvider(create: (_) => ReminderProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => DeckBookmarkProvider(widget.prefs)),
        provider_pkg.ChangeNotifierProvider(create: (_) => FlashcardRevealProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => StudySessionController(
          persistence: StudySessionPersistence(widget.prefs),
        )),
        provider_pkg.ChangeNotifierProvider(create: (_) => RecentGenerationRepository(widget.prefs)),
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
            cacheService: ExplanationCacheService(widget.prefs),
            groqService: context.read<GroqProvider>().service,
          ),
          update: (context, dbProvider, groqProvider, previous) {
            return previous ?? ExamProvider(
              flashcardRepository: dbProvider.flashcardRepository,
              cacheService: ExplanationCacheService(widget.prefs),
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
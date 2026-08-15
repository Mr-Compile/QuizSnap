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
import 'core/services/session_inactivity_service.dart';
import 'core/database/database.dart';
import 'core/services/backup_service_enhanced.dart';
import 'core/providers/focus_mode_provider.dart';
import 'core/navigation/app_router.dart';
import 'features/settings/pin_lock_screen.dart';
import 'shared/widgets/activity_detector.dart';
import 'shared/widgets/dialogs/inactivity_warning_dialog.dart';

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

  // Create SessionInactivityService — depends on SecurityProvider.
  final sessionInactivityService = SessionInactivityService(securityProvider);

  // Create FocusModeProvider — tracks study/exam focus sessions.
  final focusModeProvider = FocusModeProvider();

  // Wire FocusModeProvider into the inactivity service so it suspends
  // during study/exam sessions.
  sessionInactivityService.attachFocusModeProvider(focusModeProvider);

  // Schedule a one-time trash cleanup in the background; the scheduler starts the daily timer disabled by default.
  unawaited(CleanupScheduler(database: database, prefs: prefs).runNow());

  // Check if automatic backup is due and perform it in the background.
  unawaited(_checkAndPerformAutoBackup(database));

  runApp(
    ProviderScope(
      overrides: [
        // Override the Riverpod database holder with the actual database
        // instance. Using a mutable holder lets us swap the AppDatabase in
        // place after a .db restore without restarting the app.
        databaseHolderProvider.overrideWithValue(DatabaseHolder(database)),
      ],
      child: QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ),
    ),
  );
}

class QuizSnapApp extends StatefulWidget {
  final SharedPreferences prefs;
  final DatabaseProvider dbProvider;
  final SecurityProvider securityProvider;
  final SessionInactivityService sessionInactivityService;
  final FocusModeProvider focusModeProvider;

  const QuizSnapApp({
    super.key,
    required this.prefs,
    required this.dbProvider,
    required this.securityProvider,
    required this.sessionInactivityService,
    required this.focusModeProvider,
  });

  @override
  State<QuizSnapApp> createState() => _QuizSnapAppState();
}

class _QuizSnapAppState extends State<QuizSnapApp> with WidgetsBindingObserver {
  late final SecurityProvider _securityProvider;
  late final SessionInactivityService _sessionInactivityService;

  /// Tracks whether the app was actually backgrounded (paused) before
  /// the next `resumed` event.  This prevents re-locking on transient
  /// `inactive → resumed` cycles such as keyboard show/hide, system
  /// dialogs, or permission prompts — which fire `inactive` without
  /// ever going through `paused`.
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    _securityProvider = widget.securityProvider;
    _sessionInactivityService = widget.sessionInactivityService;
    WidgetsBinding.instance.addObserver(this);

    // Bridge SecurityProvider state changes to GoRouter so the redirect
    // re-evaluates when the app is locked/unlocked (e.g. lifecycle events).
    _securityProvider.addListener(_onSecurityChanged);

    // Start inactivity tracking once the app is running.
    _sessionInactivityService.start();
  }

  @override
  void dispose() {
    _sessionInactivityService.stop();
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
    debugPrint('[QuizSnapApp] lifecycle event: ${state.name}');
    switch (state) {
      case AppLifecycleState.paused:
        // App fully backgrounded — record this so we know to re-lock
        // on resume, and stop inactivity tracking.
        _wasBackgrounded = true;
        _sessionInactivityService.stop();
        break;
      case AppLifecycleState.inactive:
        // Transient state (keyboard, system dialog, permission prompt).
        // Do NOT mark as backgrounded — we only stop the inactivity
        // timer here.  Locking on `inactive → resumed` caused the PIN
        // lock to appear during normal usage (e.g. opening the keyboard).
        _sessionInactivityService.stop();
        break;
      case AppLifecycleState.detached:
        _sessionInactivityService.stop();
        break;
      case AppLifecycleState.resumed:
        // Only re-lock if the app was actually backgrounded (paused),
        // not just transiently inactive.  lockApp() also has internal
        // guards (PIN not enabled, already locked, unlock grace period,
        // lock screen visible) that prevent spurious re-locks.
        if (_wasBackgrounded) {
          debugPrint('[QuizSnapApp] lifecycle: resumed from background — checking lock');
          _securityProvider.lockApp();
        } else {
          debugPrint('[QuizSnapApp] lifecycle: resumed from transient inactive — no lock');
        }
        _wasBackgrounded = false;

        // Restart inactivity tracking.
        // If app lock was applied, the session timer will be idle until
        // the user unlocks (the service checks isLocked and skips ticks).
        _sessionInactivityService.start();
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
            final old = previous;
            if (old == null || old.dbEpoch != dbProvider.dbEpoch) {
              return AiQuotaProvider(dbProvider);
            }
            return old;
          },
        ),
        // SecurityProvider is created early in main() so it can be
        // initialized before runApp and wired to the router refresh.
        provider_pkg.ChangeNotifierProvider.value(value: _securityProvider),
        // SessionInactivityService tracks foreground inactivity.
        provider_pkg.ChangeNotifierProvider.value(value: _sessionInactivityService),
        // FocusModeProvider tracks study/exam focus sessions.
        provider_pkg.ChangeNotifierProvider.value(value: widget.focusModeProvider),
        provider_pkg.ChangeNotifierProvider(create: (_) => ReminderProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => DeckBookmarkProvider(widget.prefs)),
        provider_pkg.ChangeNotifierProvider(create: (_) => FlashcardRevealProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => StudySessionController(
          persistence: StudySessionPersistence(widget.prefs),
        )),
        provider_pkg.ChangeNotifierProvider(create: (_) => RecentGenerationRepository(widget.prefs)),
        provider_pkg.ChangeNotifierProxyProvider<DatabaseProvider, CachedDocumentRepository>(
          create: (context) => CachedDocumentRepository(context.read<DatabaseProvider>()),
          update: (context, db, previous) {
            final old = previous;
            if (old == null || old.dbEpoch != db.dbEpoch) {
              return CachedDocumentRepository(db);
            }
            return old;
          },
        ),
        provider_pkg.ChangeNotifierProvider(create: (_) => HighlightedSelectionProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => PageSelectionProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => FlashcardSelectionProvider()),
        provider_pkg.ChangeNotifierProxyProvider<DatabaseProvider, TrashProvider>(
          create: (context) => TrashProvider(
            TrashService(
              deckRepository: context.read<DatabaseProvider>().deckRepository,
              flashcardRepository: context.read<DatabaseProvider>().flashcardRepository,
              folderRepository: context.read<DatabaseProvider>().folderRepository,
            ),
            dbEpoch: context.read<DatabaseProvider>().dbEpoch,
          ),
          update: (context, dbProvider, previous) {
            final old = previous;
            if (old == null || old.dbEpoch != dbProvider.dbEpoch) {
              return TrashProvider(
                TrashService(
                  deckRepository: dbProvider.deckRepository,
                  flashcardRepository: dbProvider.flashcardRepository,
                  folderRepository: dbProvider.folderRepository,
                ),
                dbEpoch: dbProvider.dbEpoch,
              );
            }
            return old;
          },
        ),
        provider_pkg.ChangeNotifierProxyProvider2<DatabaseProvider, GroqProvider, ExamProvider>(
          create: (context) => ExamProvider(
            flashcardRepository: context.read<DatabaseProvider>().flashcardRepository,
            cacheService: ExplanationCacheService(widget.prefs),
            groqService: context.read<GroqProvider>().service,
            dbEpoch: context.read<DatabaseProvider>().dbEpoch,
          ),
          update: (context, dbProvider, groqProvider, previous) {
            final old = previous;
            if (old == null || old.dbEpoch != dbProvider.dbEpoch) {
              return ExamProvider(
                flashcardRepository: dbProvider.flashcardRepository,
                cacheService: ExplanationCacheService(widget.prefs),
                groqService: groqProvider.service,
                dbEpoch: dbProvider.dbEpoch,
              );
            }
            return old;
          },
        ),
        provider_pkg.ProxyProvider<DatabaseProvider, ExportProvider>(
          update: (context, dbProvider, previous) {
            final old = previous;
            if (old == null || old.dbEpoch != dbProvider.dbEpoch) {
              return ExportProvider(dbProvider.database, dbEpoch: dbProvider.dbEpoch);
            }
            return old;
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
            builder: (context, child) {
              return ActivityDetector(
                child: _AppLockHandler(
                  child: _SessionWarningHandler(
                    child: child!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Listens to [SessionInactivityService] and shows/dismisses the
/// [InactivityWarningDialog] with a live countdown.
///
/// This widget must be inside the [MaterialApp.router] builder so its
/// context has access to the root navigator for showing dialogs.
class _SessionWarningHandler extends StatefulWidget {
  final Widget child;

  const _SessionWarningHandler({required this.child});

  @override
  State<_SessionWarningHandler> createState() => _SessionWarningHandlerState();
}

class _SessionWarningHandlerState extends State<_SessionWarningHandler> {
  SessionInactivityService? _service;
  SecurityProvider? _securityProvider;
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??= context.read<SessionInactivityService>();
    _securityProvider ??= context.read<SecurityProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service?.addListener(_onServiceChanged);
    });
  }

  @override
  void dispose() {
    _service?.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    final service = _service;
    if (service == null || !mounted) return;

    // Focus mode guard: never show warning dialog during study/exam.
    if (service.isFocusMode) {
      if (_dialogShown) {
        _dialogShown = false;
        _dismissDialog();
      }
      return;
    }

    if (service.isWarningPhase && !_dialogShown) {
      _dialogShown = true;
      _showWarningDialog(service);
    } else if (!service.isWarningPhase && _dialogShown) {
      _dialogShown = false;
      _dismissDialog();
    }
  }

  void _dismissDialog() {
    if (!mounted) return;
    // Use the GoRouter's navigator key — same reason as
    // _showWarningDialog (this widget's context is above the router
    // Navigator).
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showWarningDialog(SessionInactivityService service) {
    // Use the GoRouter's navigator key because this widget's context
    // sits above the router Navigator inside the MaterialApp.router
    // builder.  Using `context` directly throws "Navigator operation
    // requested with a context that does not include a Navigator".
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[SessionWarningHandler] navigator not ready — skipping dialog');
      return;
    }
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            if (!service.isWarningPhase) {
              return const SizedBox.shrink();
            }
            return InactivityWarningDialog(
              countdown: service.countdown,
              onStillHere: () => service.dismissWarning(),
              onLockNow: (_securityProvider?.isPinEnabled ?? false)
                  ? () => service.lockNow()
                  : null,
            );
          },
        );
      },
    ).then((_) {
      _dialogShown = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Checks if an automatic backup is due on app launch and performs it
/// silently in the background.  The schedule is stored in SharedPreferences
/// by [BackupServiceEnhanced].  This runs after the database is initialized
/// and does not block the UI.
Future<void> _checkAndPerformAutoBackup(AppDatabase database) async {
  try {
    final backupService = BackupServiceEnhanced(database);
    final isDue = await backupService.isAutomaticBackupDue();
    if (isDue) {
      debugPrint('[AutoBackup] Backup is due — performing automatic backup');
      await backupService.performAutomaticBackup();
      debugPrint('[AutoBackup] Automatic backup completed');
    }
  } catch (e) {
    debugPrint('[AutoBackup] Failed to perform automatic backup: $e');
  }
}

/// Watches [SecurityProvider.isLocked] and renders a full-screen
/// [PinLockScreen] overlay on top of the entire application when the
/// app is locked.
///
/// This replaces the previous dialog-based [AppLockDialog] approach.
/// The full-screen overlay completely hides and blocks interaction
/// with the underlying application content (Dashboard, Library, Study,
/// Settings, etc.) until the user enters the correct PIN.
///
/// The overlay sits inside a [Stack] above the router output.  When
/// [SecurityProvider.verifyPin] succeeds it clears `isLocked`, the
/// [Consumer] rebuilds, and the overlay disappears — the user returns
/// to the exact screen they were on.  No route navigation is needed.
///
/// This widget must be inside the [MaterialApp.router] builder so it
/// wraps the router output.
class _AppLockHandler extends StatefulWidget {
  final Widget child;

  const _AppLockHandler({required this.child});

  @override
  State<_AppLockHandler> createState() => _AppLockHandlerState();
}

class _AppLockHandlerState extends State<_AppLockHandler> {
  SecurityProvider? _securityProvider;
  bool _overlayVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _securityProvider ??= context.read<SecurityProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _securityProvider?.addListener(_onSecurityChanged);
      // Check initial state — the app may start locked.
      _onSecurityChanged();
    });
  }

  @override
  void dispose() {
    _securityProvider?.removeListener(_onSecurityChanged);
    super.dispose();
  }

  void _onSecurityChanged() {
    final provider = _securityProvider;
    if (provider == null || !mounted) return;

    final locked = provider.isLocked;
    if (locked && !_overlayVisible) {
      _overlayVisible = true;
      // Mark the lock screen as visible so lockApp()/lockSession()
      // guards prevent stacking duplicate lock requests.
      provider.setLockScreenVisible(true);
      debugPrint('[AppLockHandler] full-screen lock overlay shown');
    } else if (!locked && _overlayVisible) {
      _overlayVisible = false;
      provider.setLockScreenVisible(false);
      debugPrint('[AppLockHandler] full-screen lock overlay removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _securityProvider;
    if (provider == null) {
      return widget.child;
    }
    return provider_pkg.Consumer<SecurityProvider>(
      builder: (context, security, child) {
        final locked = security.isLocked;
        // Keep the visibility flag in sync with the lock state so the
        // listener and the Consumer agree (the listener handles the
        // setLockScreenVisible side-effects).
        if (locked != _overlayVisible) {
          _overlayVisible = locked;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              security.setLockScreenVisible(locked);
              debugPrint('[AppLockHandler] lock overlay ${locked ? 'shown' : 'removed'} (consumer)');
            }
          });
        }
        // The full-screen lock overlay is rendered ABOVE the app
        // content in a Stack.  It is fully opaque so the underlying
        // screens are hidden and not interactable.
        return Stack(
          children: [
            child!,
            if (locked) const PinLockScreen(isOverlay: true),
          ],
        );
      },
      child: widget.child,
    );
  }
}
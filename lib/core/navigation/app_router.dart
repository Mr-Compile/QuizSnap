import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/main/main_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/decks/deck_details_screen.dart';
import '../../features/decks/create_deck_screen.dart';
import '../../features/decks/edit_deck_screen.dart';
import '../../features/flashcards/flashcard_list_screen.dart';
import '../../features/flashcards/create_flashcard_screen.dart';
import '../../features/flashcards/edit_flashcard_screen.dart';
import '../../features/flashcards/move_flashcard_screen.dart';
import '../../features/study/study_home_screen.dart';
import '../../features/study/deck_study_screen.dart';
import '../../features/study/flashcard_card_screen.dart';
import '../../features/study/quiz_practice_screen.dart';
import '../../features/study/today_review_screen.dart';
import '../../features/study/bookmark_list_screen.dart';
import '../../features/exam/exam_setup_screen.dart';
import '../../features/exam/countdown_screen.dart';
import '../../features/exam/exam_question_screen.dart';
import '../../features/exam/exam_result_screen.dart';
import '../../features/exam/cached_explanations_screen.dart';
import '../../features/ai_generate/ai_generate_home_screen.dart';
import '../../features/ai_generate/ai_generation_config_screen.dart';
import '../../features/ai_generate/camera_ocr_screen.dart';
import '../../features/ai_generate/pdf_preview_screen.dart' as ai;
import '../../features/ai_generate/text_preview_screen.dart';
import '../../features/ai_generate/question_review_screen.dart';
import '../../core/models/prompt_template.dart';
import '../../core/models/exam.dart';
import '../../core/models/export.dart';
import '../../features/analytics/analytics_dashboard_screen.dart';
import '../../features/analytics/daily_activity_chart_screen.dart';
import '../../features/analytics/insights_screen.dart';
import '../../features/analytics/mastery_breakdown_screen.dart';
import '../../features/analytics/quiz_performance_screen.dart';
import '../../features/analytics/study_time_screen.dart';
import '../../features/analytics/subject_accuracy_screen.dart';
import '../../features/analytics/weak_topics_screen.dart';
import '../../features/export/export_center_screen.dart';
import '../../features/export/export_options_screen.dart';
import '../../features/export/export_success_screen.dart';
import '../../features/export/pdf_preview_screen.dart' as export_screen;
import '../../features/export/backup_history_screen.dart';
import '../../features/export/backup_restore_screen_enhanced.dart';
import '../../features/export/import_preview_screen.dart';
import '../../features/export/change_backup_folder_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/security_settings_screen.dart';
import '../../features/settings/api_configuration_screen.dart';
import '../../features/settings/ai_usage_screen.dart';
import '../../features/settings/authorized_quota_screen.dart';
import '../../features/settings/pin_lock_screen.dart';
import '../../features/settings/set_pin_screen.dart';
import '../../features/settings/reminder_settings_screen.dart';
import '../../features/settings/database_maintenance_screen.dart';
import '../../features/settings/trash_settings_screen.dart';
import '../../features/folders/folder_list_screen.dart';
import '../../features/folders/create_folder_screen.dart';
import '../../features/folders/folder_details_screen.dart';
import '../../features/tags/tag_management_screen.dart';
import '../../features/search/global_search_screen.dart';
import '../../features/trash/trash_screen.dart';
import '../../core/providers/security_provider.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/navigation/error_screens/not_found_screen.dart';
import '../../core/navigation/error_screens/database_error_screen.dart';
import '../../core/navigation/error_screens/network_error_screen.dart';

/// Application router configuration using GoRouter
/// 
/// This router handles all navigation within the app, providing:
/// - Type-safe route parameters
/// - Deep linking support
/// - Route guards for authentication
/// - Error handling and fallback screens
/// - Consistent navigation patterns
/// - State preservation for bottom navigation tabs
/// A lightweight [ChangeNotifier] used as a [GoRouter.refreshListenable]
/// bridge.  [AppRouter.refresh] is called whenever the [SecurityProvider]
/// changes state so the router re-evaluates its redirect (e.g. when the
/// app is locked on resume from background).
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class AppRouter {
  AppRouter._();

  static final _RouterRefreshNotifier _refreshNotifier =
      _RouterRefreshNotifier();

  /// Triggers a GoRouter redirect re-evaluation.  Called after
  /// [SecurityProvider] state changes that affect locking.
  static void refresh() {
    debugPrint('[AppRouter] refresh() triggered');
    _refreshNotifier.notify();
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _refreshNotifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      // Security check - redirect to PIN lock if app or session is locked.
      // Guard: don't redirect while an unlock transaction is in progress
      // (verifyPin sets isUnlocking=true before clearing isLocked).
      final securityProvider = context.read<SecurityProvider>();
      if (securityProvider.isUnlocking) {
        // Unlock in progress — don't interfere with navigation.
        return null;
      }
      // Guard: don't redirect if the lock screen is already visible
      // (prevents duplicate navigation when both lock systems fire).
      if (securityProvider.lockScreenVisible) {
        return null;
      }
      if (securityProvider.isLocked && state.uri.path != AppRoutes.pinLock) {
        // Save the route the user was on so it can be restored after unlock.
        securityProvider.setRouteBeforeLock(state.uri.path);
        debugPrint('[AppRouter] redirect to pin-lock from ${state.uri.path} '
            '(appLocked=${securityProvider.isAppLocked}, '
            'sessionLocked=${securityProvider.isSessionLocked})');
        return AppRoutes.pinLock;
      }
      return null;
    },
    routes: [
      // Main screen with bottom navigation (using shell route for state preservation)
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainScreen(),
      ),

      // Deck / Library routes
      GoRoute(
        path: AppRoutes.decks,
        builder: (context, state) => const LibraryScreen(),
        routes: [
          GoRoute(
            path: ':deckId',
            builder: (context, state) {
              final deckId = int.parse(state.pathParameters['deckId']!);
              return DeckDetailsScreen(deckId: deckId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final deckId = int.parse(state.pathParameters['deckId']!);
                  return EditDeckScreen(deckId: deckId);
                },
              ),
              GoRoute(
                path: 'flashcards',
                builder: (context, state) {
                  final deckId = int.parse(state.pathParameters['deckId']!);
                  return FlashcardListScreen(deckId: deckId);
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) {
                      final deckId = int.parse(state.pathParameters['deckId']!);
                      return CreateFlashcardScreen(deckId: deckId);
                    },
                  ),
                  GoRoute(
                    path: ':flashcardId/edit',
                    builder: (context, state) {
                      final flashcardId = int.parse(state.pathParameters['flashcardId']!);
                      return EditFlashcardScreen(flashcardId: flashcardId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateDeckScreen(),
          ),
        ],
      ),

      // AI Generate routes
      GoRoute(
        path: AppRoutes.aiGenerate,
        builder: (context, state) => const AiGenerateHomeScreen(),
        routes: [
          GoRoute(
            path: 'config',
            builder: (context, state) => AiGenerationConfigScreen(
              sourceText: state.uri.queryParameters['sourceText'] ?? '',
              source: state.uri.queryParameters['source'] ?? '',
            ),
          ),
          GoRoute(
            path: 'camera-ocr',
            builder: (context, state) => const CameraOcrScreen(),
          ),
          GoRoute(
            path: 'pdf-preview',
            builder: (context, state) {
              // File should be passed via state.extra
              final file = state.extra as File?;
              if (file == null) {
                return const Scaffold(body: Center(child: Text('Error: No file provided')));
              }
              return ai.PdfPreviewScreen(file: file);
            },
          ),
          GoRoute(
            path: 'text-preview',
            builder: (context, state) => TextPreviewScreen(
              text: state.uri.queryParameters['text'] ?? '',
              source: state.uri.queryParameters['source'] ?? '',
            ),
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) {
              // These should be passed via state.extra
              final extra = state.extra as Map<String, dynamic>?;
              return QuestionReviewScreen(
                questions: extra?['questions'] ?? [],
                type: extra?['type'] ?? PromptType.multipleChoice,
                difficulty: extra?['difficulty'] ?? Difficulty.medium,
                source: extra?['source'] ?? '',
                sourceText: extra?['sourceText'] ?? '',
              );
            },
          ),
        ],
      ),

      // Study routes
      GoRoute(
        path: AppRoutes.study,
        builder: (context, state) => const StudyHomeScreen(),
        routes: [
          GoRoute(
            path: 'decks',
            builder: (context, state) => const DeckStudyScreen(),
          ),
          GoRoute(
            path: 'cards',
            builder: (context, state) {
              // Note: This will need additional parameters for flashcard list
              return FlashcardCardScreen(
                flashcards: [], // Will need to be passed via state.extra
                currentIndex: 0,
                onCardRated: (rating) {},
              );
            },
          ),
          GoRoute(
            path: 'quiz',
            builder: (context, state) {
              final deckId = int.tryParse(state.uri.queryParameters['deckId'] ?? '') ?? 0;
              final deckName = state.uri.queryParameters['deckName'] ?? 'Quiz';
              return QuizPracticeScreen(deckId: deckId, deckName: deckName);
            },
          ),
          GoRoute(
            path: 'today',
            builder: (context, state) => const TodayReviewScreen(),
          ),
          GoRoute(
            path: 'bookmarks',
            builder: (context, state) => const BookmarkListScreen(),
          ),
        ],
      ),

      // Exam routes
      GoRoute(
        path: '/exam/:deckId/setup',
        builder: (context, state) {
          final deckId = int.parse(state.pathParameters['deckId']!);
          final deckName = state.uri.queryParameters['deckName'] ?? 'Unknown Deck';
          return ExamSetupScreen(
            deckId: deckId,
            deckName: deckName,
          );
        },
      ),
      GoRoute(
        path: '/exam/:examId/countdown',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          return CountdownScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/exam/:examId/question',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          return ExamQuestionScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/exam/:examId/result',
        builder: (context, state) {
          // ExamResultScreen needs an ExamResult, not examId
          // This should be passed via state.extra
          final extra = state.extra as ExamResult?;
          if (extra == null) {
            return const Scaffold(body: Center(child: Text('Error: No exam result provided')));
          }
          return ExamResultScreen(examId: extra.exam.id);
        },
      ),
      GoRoute(
        path: AppRoutes.cachedExplanations,
        builder: (context, state) => const CachedExplanationsScreen(),
      ),

      // Analytics routes
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsDashboardScreen(),
        routes: [
          GoRoute(
            path: 'daily-activity',
            builder: (context, state) => const DailyActivityChartScreen(),
          ),
          GoRoute(
            path: 'insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: 'mastery',
            builder: (context, state) => const MasteryBreakdownScreen(),
          ),
          GoRoute(
            path: 'quiz-performance',
            builder: (context, state) => const QuizPerformanceScreen(),
          ),
          GoRoute(
            path: 'study-time',
            builder: (context, state) => const StudyTimeScreen(),
          ),
          GoRoute(
            path: 'subject-accuracy',
            builder: (context, state) => const SubjectAccuracyScreen(),
          ),
          GoRoute(
            path: 'weak-topics',
            builder: (context, state) => const WeakTopicsScreen(),
          ),
        ],
      ),

      // Export routes
      GoRoute(
        path: AppRoutes.exportCenter,
        builder: (context, state) => const ExportCenterScreen(),
        routes: [
          GoRoute(
            path: 'options',
            builder: (context, state) => const ExportOptionsScreen(
              initialType: ExportType.flashcards,
              initialFormat: ExportFormat.pdf,
            ),
          ),
          GoRoute(
            path: 'success',
            builder: (context, state) {
              final exportResult = state.extra as ExportResult?;
              if (exportResult == null) {
                return const Scaffold(
                  body: Center(child: Text('No export result provided')),
                );
              }
              return ExportSuccessScreen(exportResult: exportResult);
            },
          ),
          GoRoute(
            path: 'pdf-preview',
            builder: (context, state) {
              final filePath = state.uri.queryParameters['filePath'] ?? '';
              return export_screen.PdfPreviewScreen(
                filePath: filePath,
              );
            },
          ),
          GoRoute(
            path: 'backups',
            builder: (context, state) => const BackupHistoryScreen(),
            routes: [
              GoRoute(
                path: 'restore',
                builder: (context, state) => const BackupRestoreScreenEnhanced(),
              ),
              GoRoute(
                path: 'import-preview',
                builder: (context, state) {
                  final filePath = state.uri.queryParameters['filePath'] ?? '';
                  if (filePath.isEmpty) {
                    return const Scaffold(
                      body: Center(child: Text('No file path provided')),
                    );
                  }
                  return ImportPreviewScreen(filePath: filePath);
                },
              ),
              GoRoute(
                path: 'change-folder',
                builder: (context, state) => const ChangeBackupFolderScreen(),
              ),
            ],
          ),
        ],
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearanceScreen(),
          ),
          GoRoute(
            path: 'security',
            builder: (context, state) => const SecuritySettingsScreen(),
          ),
          GoRoute(
            path: 'api-config',
            builder: (context, state) => const ApiConfigurationScreen(),
          ),
          GoRoute(
            path: 'ai-usage',
            builder: (context, state) => const AiUsageScreen(),
          ),
          GoRoute(
            path: 'authorized-quota',
            builder: (context, state) => const AuthorizedQuotaScreen(),
          ),
          GoRoute(
            path: 'pin-lock',
            builder: (context, state) => const PinLockScreen(),
          ),
          GoRoute(
            path: 'pin-set',
            builder: (context, state) => const SetPinScreen(),
          ),
          GoRoute(
            path: 'reminders',
            builder: (context, state) => const ReminderSettingsScreen(),
          ),
          GoRoute(
            path: 'database',
            builder: (context, state) => const DatabaseMaintenanceScreen(),
          ),
          GoRoute(
            path: 'trash',
            builder: (context, state) => const TrashSettingsScreen(),
          ),
        ],
      ),

      // Folder routes
      GoRoute(
        path: AppRoutes.folders,
        builder: (context, state) => const FolderListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateFolderScreen(),
          ),
          GoRoute(
            path: ':folderId',
            builder: (context, state) {
              final folderId = int.parse(state.pathParameters['folderId']!);
              return FolderDetailsScreen(folderId: folderId);
            },
          ),
        ],
      ),

      // Tag routes
      GoRoute(
        path: AppRoutes.tags,
        builder: (context, state) => const TagManagementScreen(),
      ),

      // Search route
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const GlobalSearchScreen(),
      ),

      // Trash route
      GoRoute(
        path: AppRoutes.trash,
        builder: (context, state) => const TrashScreen(),
      ),

      // Move flashcards route
      GoRoute(
        path: AppRoutes.moveFlashcards,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final flashcardIds = (extra?['flashcardIds'] as List?)?.cast<int>() ?? [];
          final sourceDeckId = extra?['sourceDeckId'] as int? ?? 0;
          return MoveFlashcardScreen(
            flashcardIds: flashcardIds,
            sourceDeckId: sourceDeckId,
          );
        },
      ),

      // Error routes
      GoRoute(
        path: AppRoutes.databaseError,
        builder: (context, state) => const DatabaseErrorScreen(),
      ),
      GoRoute(
        path: AppRoutes.networkError,
        builder: (context, state) => const NetworkErrorScreen(),
      ),
    ],
  );
}

/// Extension to add navigation helper methods to BuildContext
extension AppRouterNavigation on BuildContext {
  void navigateToDeck(int deckId) {
    go('${AppRoutes.decks}/$deckId');
  }

  void navigateToCreateDeck() {
    go('${AppRoutes.decks}/create');
  }

  void navigateToEditDeck(int deckId) {
    go('${AppRoutes.decks}/$deckId/edit');
  }

  void navigateToFlashcards(int deckId) {
    go('${AppRoutes.decks}/$deckId/flashcards');
  }

  void navigateToAddFlashcard(int deckId) {
    go('${AppRoutes.decks}/$deckId/flashcards/add');
  }

  void navigateToExamSetup(int deckId, String deckName) {
    go('/exam/$deckId/setup?deckName=$deckName');
  }

  void navigateToStudy() {
    go(AppRoutes.study);
  }

  void navigateToTodayReview() {
    go('${AppRoutes.study}/today');
  }

  void navigateToBookmarks() {
    go('${AppRoutes.study}/bookmarks');
  }

  void navigateToAnalytics() {
    go(AppRoutes.analytics);
  }

  void navigateToSettings() {
    go(AppRoutes.settings);
  }

  void navigateToSearch() {
    go(AppRoutes.search);
  }

  void navigateToTrash() {
    go(AppRoutes.trash);
  }

  void navigateToMoveFlashcards(List<int> flashcardIds, int sourceDeckId) {
    go(AppRoutes.moveFlashcards, extra: {
      'flashcardIds': flashcardIds,
      'sourceDeckId': sourceDeckId,
    });
  }
}
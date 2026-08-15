/// Application route constants for type-safe navigation
/// 
/// This file defines all route paths used throughout the application.
/// Use these constants instead of hardcoded strings to ensure consistency
/// and enable compile-time checking of route paths.
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Root and main navigation
  static const String home = '/';
  static const String decks = '/decks';
  static const String aiGenerate = '/ai-generate';
  static const String study = '/study';
  static const String analytics = '/analytics';
  static const String settings = '/settings';

  // Deck routes
  static const String deckDetails = '/decks/:deckId';
  static const String createDeck = '/decks/create';
  static const String editDeck = '/decks/:deckId/edit';

  // Flashcard routes
  static const String flashcardList = '/decks/:deckId/flashcards';
  static const String addFlashcard = '/decks/:deckId/flashcards/add';
  static const String editFlashcard = '/decks/:deckId/flashcards/:flashcardId/edit';
  static const String deleteFlashcard = '/decks/:deckId/flashcards/:flashcardId/delete';

  // Study routes
  static const String studyHome = '/study';
  static const String deckStudy = '/study/decks/:deckId';
  static const String flashcardCard = '/study/cards/:cardId';
  static const String quizPractice = '/study/quiz/:deckId';
  static const String todayReview = '/study/today';
  static const String bookmarks = '/study/bookmarks';

  // Exam routes
  static const String examSetup = '/exam/:deckId/setup';
  static const String examCountdown = '/exam/:examId/countdown';
  static const String examQuestion = '/exam/:examId/question';
  static const String examResult = '/exam/:examId/result';
  static const String examReview = '/exam/:examId/review';

  // AI Generation routes
  static const String aiHome = '/ai-generate';
  static const String aiConfig = '/ai-generate/config';
  static const String cameraOcr = '/ai-generate/camera-ocr';
  static const String pdfPreview = '/ai-generate/pdf-preview';
  static const String textPreview = '/ai-generate/text-preview';
  static const String questionReview = '/ai-generate/review';

  // Analytics routes
  static const String analyticsDashboard = '/analytics';
  static const String dailyActivity = '/analytics/daily-activity';
  static const String insights = '/analytics/insights';
  static const String masteryBreakdown = '/analytics/mastery';
  static const String quizPerformance = '/analytics/quiz-performance';
  static const String studyTime = '/analytics/study-time';
  static const String subjectAccuracy = '/analytics/subject-accuracy';
  static const String weakTopics = '/analytics/weak-topics';

  // Export routes
  static const String exportCenter = '/export';
  static const String exportOptions = '/export/options';
  static const String exportSuccess = '/export/success';
  static const String exportPdfPreview = '/export/pdf-preview';
  static const String backupHistory = '/export/backups';
  static const String backupRestore = '/export/backups/restore';
  static const String backupRestoreEnhanced = '/export/backups/restore-enhanced';
  static const String importPreview = '/export/backups/import-preview';
  static const String changeBackupFolder = '/export/backups/change-folder';

  // Settings routes
  static const String settingsHome = '/settings';
  static const String appearance = '/settings/appearance';
  static const String security = '/settings/security';
  static const String apiConfiguration = '/settings/api-config';
  static const String aiUsage = '/settings/ai-usage';
  static const String authorizedQuota = '/settings/authorized-quota';
  static const String pinLock = '/settings/pin-lock';
  static const String setPin = '/settings/pin-set';
  static const String reminderSettings = '/settings/reminders';
  static const String databaseMaintenance = '/settings/database';
  static const String trashSettings = '/settings/trash';
  static const String userManual = '/settings/user-manual';

  // Folder routes
  static const String folders = '/folders';
  static const String createFolder = '/folders/create';
  static const String folderDetails = '/folders/:folderId';

  // Tag routes
  static const String tags = '/tags';
  static const String tagManagement = '/tags/manage';

  // Search routes
  static const String search = '/search';

  // Trash routes
  static const String trash = '/trash';

  // Move flashcards route
  static const String moveFlashcards = '/move-flashcards';

  // Error routes
  static const String notFound = '/404';
  static const String databaseError = '/error/database';
  static const String networkError = '/error/network';
}

/// Route parameter names for type-safe parameter extraction
class RouteParams {
  RouteParams._();

  static const String deckId = 'deckId';
  static const String flashcardId = 'flashcardId';
  static const String cardId = 'cardId';
  static const String examId = 'examId';
  static const String folderId = 'folderId';
  static const String tagId = 'tagId';
}

/// Query parameter names for type-safe query parameter extraction
class QueryParams {
  QueryParams._();

  static const String tab = 'tab';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String sort = 'sort';
  static const String page = 'page';
  static const String limit = 'limit';
}
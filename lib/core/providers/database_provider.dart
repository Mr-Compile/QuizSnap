import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../repositories/folder_repository.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/study_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/backup_repository.dart';

class DatabaseProvider extends ChangeNotifier {
  AppDatabase? _database;
  late final FolderRepository _folderRepository;
  late final DeckRepository _deckRepository;
  late final FlashcardRepository _flashcardRepository;
  late final TagRepository _tagRepository;
  late final StudyRepository _studyRepository;
  late final AnalyticsRepository _analyticsRepository;
  late final BackupRepository _backupRepository;

  AppDatabase get database => _database!;
  FolderRepository get folderRepository => _folderRepository;
  DeckRepository get deckRepository => _deckRepository;
  FlashcardRepository get flashcardRepository => _flashcardRepository;
  TagRepository get tagRepository => _tagRepository;
  StudyRepository get studyRepository => _studyRepository;
  AnalyticsRepository get analyticsRepository => _analyticsRepository;
  BackupRepository get backupRepository => _backupRepository;

  DatabaseProvider();

  /// Named constructor for in-memory widget and integration tests.
  DatabaseProvider.test(AppDatabase database) {
    _database = database;
    _folderRepository = FolderRepository(_database!);
    _deckRepository = DeckRepository(_database!);
    _flashcardRepository = FlashcardRepository(_database!);
    _tagRepository = TagRepository(_database!);
    _studyRepository = StudyRepository(_database!);
    _analyticsRepository = AnalyticsRepository(_database!);
    _backupRepository = BackupRepository(_database!);
  }

  Future<AppDatabase> initializeDatabase() async {
    if (_database != null) return _database!;
    
    _database = AppDatabase(openConnection());
    _folderRepository = FolderRepository(_database!);
    _deckRepository = DeckRepository(_database!);
    _flashcardRepository = FlashcardRepository(_database!);
    _tagRepository = TagRepository(_database!);
    _studyRepository = StudyRepository(_database!);
    _analyticsRepository = AnalyticsRepository(_database!);
    _backupRepository = BackupRepository(_database!);
    
    return _database!;
  }

  Future<void> initialize() async {
    await initializeDatabase();
  }

  /// Publicly triggers a rebuild for widgets listening to this provider.
  void refreshDecks() => notifyListeners();
  void refreshAnalytics() => notifyListeners();

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}

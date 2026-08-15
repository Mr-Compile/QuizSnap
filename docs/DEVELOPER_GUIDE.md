# QuizSnap Developer Guide

**Version:** 1.0.0  
**Platform:** Flutter (Android, iOS, Windows, macOS, Linux, Web)  
**Last Updated:** 2026-08-15

This guide provides comprehensive documentation for developers working on the QuizSnap codebase, including architecture, features, setup instructions, and development guidelines.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Core Features](#core-features)
6. [Database Schema](#database-schema)
7. [State Management](#state-management)
8. [Navigation](#navigation)
9. [API Integration](#api-integration)
10. [Development Setup](#development-setup)
11. [Build & Deployment](#build--deployment)
12. [Testing](#testing)
13. [Code Style & Conventions](#code-style--conventions)
14. [Troubleshooting](#troubleshooting)

---

## Project Overview

QuizSnap is an offline-first flashcard and study application built with Flutter. It helps users learn effectively using spaced repetition, AI-powered question generation, and detailed analytics.

### Key Capabilities

- **Flashcard Management**: Create, organize, and study flashcards manually or via AI
- **Study Modes**: List Mode, Quiz Mode, and Today's Review with SM-2 spaced repetition
- **Exam Mode**: Timed exams generated from deck content
- **AI Integration**: Generate questions from PDF, TXT, DOCX, or camera OCR using Groq AI
- **Analytics**: Track study time, accuracy, streaks, and mastery
- **Data Management**: Backup/restore, export to PDF, trash/restore system
- **Security**: Optional PIN lock and session management
- **Organization**: Folders, tags, and bookmarks for content organization

### Offline vs Online Features

**Offline (Fully Functional):**
- Study sessions and flashcard management
- Exam generation and taking
- Analytics and progress tracking
- Library and folder management
- Backup and restore operations
- Trash management

**Online Required:**
- AI question generation
- AI question regeneration
- AI explanation generation
- API key validation

---

## Architecture

QuizSnap follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                       │
│  (Features - UI Screens, Widgets, Dialogs, Bottom Sheets)   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    State Management Layer                    │
│           (Providers - Riverpod & Provider)                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  (Business Logic - AI services, Backup, Study, etc.)        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
│         (Data Access - Database queries, caching)             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│              (Drift Database - SQLite)                       │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer (`lib/features/`)**
- UI screens and widgets organized by feature
- User interaction handling
- Navigation between screens
- Display data from providers

**State Management Layer (`lib/core/providers/`)**
- Riverpod and Provider state management
- Business logic coordination
- Data transformation for UI
- State persistence

**Service Layer (`lib/core/services/`)**
- Business logic implementation
- External API integration (Groq AI)
- File operations and document processing
- Background task scheduling

**Repository Layer (`lib/core/repositories/`)**
- Database query abstraction
- Data caching strategies
- Complex data operations
- Transaction management

**Data Layer (`lib/core/database/`)**
- Drift database schema definition
- Database migrations
- SQLite connection management
- Raw SQL operations when needed

---

## Tech Stack

### Core Framework
- **Flutter**: ^3.12.2 (UI framework)
- **Dart**: ^3.12.2 (programming language)

### Database & Storage
- **Drift**: ^2.14.0 (SQLite ORM)
- **sqlite3_flutter_libs**: ^0.5.18 (SQLite native libraries)
- **path_provider**: ^2.1.1 (File system paths)
- **shared_preferences**: ^2.2.2 (Key-value storage)
- **flutter_secure_storage**: ^9.0.0 (Secure storage for API keys)

### State Management
- **Provider**: ^6.1.1 (Legacy state management)
- **flutter_riverpod**: ^2.4.9 (Modern state management)

### Navigation
- **go_router**: ^13.0.0 (Declarative routing)

### UI Components
- **google_fonts**: ^6.1.0 (Typography)
- **flutter_slidable**: ^3.0.1 (Swipe actions)
- **flutter_card_swiper**: ^3.0.1 (Card swiping)
- **fl_chart**: ^0.66.0 (Charts and graphs)

### AI & Document Processing
- **groq**: ^1.1.1 (AI API client)
- **file_picker**: ^8.3.7 (File selection)
- **pdfx**: ^2.0.0 (PDF rendering)
- **syncfusion_flutter_pdf**: ^29.2.11 (PDF processing)
- **camera**: ^0.10.5+5 (Camera access)
- **google_mlkit_text_recognition**: ^0.11.0 (OCR)

### Utilities
- **intl**: ^0.18.1 (Internationalization)
- **crypto**: ^3.0.3 (Hashing and encryption)
- **connectivity_plus**: ^5.0.0 (Network connectivity)
- **permission_handler**: ^11.0.1 (Runtime permissions)

### Export & Sharing
- **pdf**: ^3.10.7 (PDF generation)
- **csv**: ^5.0.2 (CSV export)
- **share_plus**: ^7.2.1 (Native sharing)
- **printing**: ^5.11.0 (Printing functionality)
- **open_filex**: ^4.3.2 (File opening)

### Notifications
- **flutter_local_notifications**: ^17.0.0 (Local notifications)
- **timezone**: ^0.9.2 (Timezone handling)

### Development Tools
- **build_runner**: ^2.4.6 (Code generation)
- **drift_dev**: ^2.14.0 (Database code generation)
- **flutter_lints**: ^6.0.0 (Linting rules)

---

## Project Structure

```
QuizSnap/
├── android/                    # Android-specific code
├── ios/                        # iOS-specific code
├── lib/                        # Main Dart source code
│   ├── core/                   # Core application logic
│   │   ├── database/          # Database schema and queries
│   │   │   ├── database.dart  # Main database definition
│   │   │   ├── database.g.dart # Generated database code
│   │   │   └── database_json_extensions.dart # JSON serialization
│   │   ├── models/            # Data models
│   │   │   ├── exam.dart      # Exam-related models
│   │   │   ├── backup.dart    # Backup models
│   │   │   ├── groq_models.dart # AI response models
│   │   │   └── ...
│   │   ├── providers/         # State management
│   │   │   ├── database_provider.dart
│   │   │   ├── exam_provider.dart
│   │   │   ├── groq_provider.dart
│   │   │   └── ...
│   │   ├── repositories/       # Data access layer
│   │   │   ├── deck_repository.dart
│   │   │   ├── flashcard_repository.dart
│   │   │   └── ...
│   │   ├── services/          # Business logic
│   │   │   ├── groq_service.dart # AI integration
│   │   │   ├── backup_service_enhanced.dart
│   │   │   ├── study_session_persistence.dart
│   │   │   └── ...
│   │   ├── navigation/        # Routing configuration
│   │   │   ├── app_router.dart
│   │   │   ├── app_routes.dart
│   │   │   └── error_screens/
│   │   ├── theme/             # App theming
│   │   │   └── app_theme.dart
│   │   └── utils/             # Utility functions
│   │       ├── explanation_sanitizer.dart
│   │       ├── flashcard_answer_codec.dart
│   │       └── ...
│   ├── features/              # Feature-based UI organization
│   │   ├── ai_generate/       # AI question generation
│   │   ├── analytics/         # Analytics dashboard
│   │   ├── decks/             # Deck management
│   │   ├── exam/              # Exam functionality
│   │   ├── export/            # Backup and export
│   │   ├── flashcards/        # Flashcard management
│   │   ├── folders/           # Folder organization
│   │   ├── study/             # Study modes
│   │   ├── settings/          # App settings
│   │   └── ...
│   ├── shared/                # Shared widgets and utilities
│   │   └── widgets/
│   └── main.dart              # App entry point
├── assets/                     # Static assets
│   └── branding/              # App icons and splash screens
├── docs/                      # Documentation
├── test/                      # Unit and integration tests
├── integration_test/          # Integration tests
├── pubspec.yaml               # Dependencies and configuration
└── analysis_options.yaml      # Dart analyzer configuration
```

---

## Core Features

### 1. Flashcard System

**Components:**
- `lib/features/flashcards/` - UI for flashcard CRUD operations
- `lib/core/repositories/flashcard_repository.dart` - Data access
- `lib/core/models/` - Flashcard data models

**Key Features:**
- Multiple question types: Identification, Enumeration, Multiple Choice
- SM-2 spaced repetition algorithm
- Bookmark/favorite system
- Tag-based organization
- Shuffle functionality for study sessions

**Question Types:**
- **Identification**: Simple question-answer pairs
- **Enumeration**: List-based answers with multiple items
- **Multiple Choice**: Questions with A-D options

### 2. Study Modes

**Components:**
- `lib/features/study/` - Study mode screens
- `lib/core/services/study_session_persistence.dart` - Session management
- `lib/core/repositories/study_repository.dart` - Study data access

**Study Modes:**
- **List Mode**: Browse all cards with study functionality
- **Quiz Mode**: Self-graded quiz with immediate feedback
- **Today's Review**: SM-2 algorithm-based review scheduling

**Spaced Repetition (SM-2 Algorithm):**
- Each flashcard has: ease factor, interval, repetitions
- Rating system: Again, Hard, Good, Easy
- Next review date calculated based on performance
- Confidence tracking before answer reveal

### 3. Exam System

**Components:**
- `lib/features/exam/` - Exam UI and logic
- `lib/core/services/exam_service.dart` - Exam business logic
- `lib/core/models/exam.dart` - Exam data models

**Exam Features:**
- Configurable question count (5-100)
- Time limits (1-120 minutes)
- Shuffle option for randomization
- Multiple question type support
- Real-time countdown timer
- Pause/resume functionality
- Detailed results and review
- AI explanation integration

### 4. AI Integration

**Components:**
- `lib/features/ai_generate/` - AI generation UI
- `lib/core/services/groq_service.dart` - Groq API integration
- `lib/core/providers/groq_provider.dart` - AI state management
- `lib/core/models/groq_models.dart` - AI response models

**AI Features:**
- Question generation from documents (PDF, TXT, DOCX)
- Camera OCR for text extraction
- Question regeneration options
- Difficulty levels (Easy, Medium, Hard)
- Question type selection
- Answer explanation generation
- Daily quota management

**Document Processing:**
- PDF text extraction with Syncfusion
- Heading detection and selection
- Page range selection
- Text highlighting and selection
- Document caching for reuse

### 5. Analytics System

**Components:**
- `lib/features/analytics/` - Analytics UI screens
- `lib/core/repositories/analytics_repository.dart` - Analytics data access
- `lib/core/models/analytics_data.dart` - Analytics models

**Analytics Features:**
- Daily activity tracking
- Study time analysis
- Quiz performance history
- Mastery breakdown per deck
- Subject accuracy metrics
- Weak topic identification
- Streak tracking
- AI-powered insights

### 6. Backup & Restore

**Components:**
- `lib/features/export/` - Backup/restore UI
- `lib/core/services/backup_service_enhanced.dart` - Backup logic
- `lib/core/repositories/backup_repository.dart` - Backup data access

**Backup Features:**
- Automatic scheduled backups
- Manual backup creation
- Backup history management
- Custom backup folder selection
- Import preview before restore
- Merge and replace restore options
- Enhanced file manager integration

### 7. Security System

**Components:**
- `lib/core/providers/security_provider.dart` - Security state management
- `lib/core/services/secure_storage_service.dart` - Secure storage
- `lib/core/services/session_inactivity_service.dart` - Session management
- `lib/features/settings/pin_lock_screen.dart` - PIN lock UI

**Security Features:**
- PIN lock with configurable timeout
- Session inactivity detection
- Automatic app locking
- Secure API key storage
- Focus mode (suspend lock during study/exam)
- Biometric authentication support (platform-specific)

### 8. Trash System

**Components:**
- `lib/features/trash/` - Trash management UI
- `lib/core/services/trash_service.dart` - Trash logic
- `lib/core/services/trash_cleanup_service.dart` - Auto-cleanup

**Trash Features:**
- Soft delete with retention period
- Restore functionality
- Permanent delete option
- Configurable retention period (default 30 days)
- Automatic cleanup scheduling
- Cascade delete (decks delete related flashcards)

---

## Database Schema

QuizSnap uses Drift (SQLite) with the following schema version 5:

### Tables

#### Folders
```dart
- id: Integer (Primary Key, Auto-increment)
- name: Text (1-100 characters)
- description: Text (Nullable)
- color: Text (Default: '#4CAF50')
- createdAt: DateTime
- updatedAt: DateTime
- deletedAt: DateTime (Nullable, for soft delete)
```

#### Decks
```dart
- id: Integer (Primary Key, Auto-increment)
- name: Text (1-100 characters)
- description: Text (Nullable)
- folderId: Integer (Foreign Key → Folders.id, Nullable)
- color: Text (Default: '#4CAF50')
- cardCount: Integer (Default: 0)
- createdAt: DateTime
- updatedAt: DateTime
- deletedAt: DateTime (Nullable, for soft delete)
```

#### Flashcards
```dart
- id: Integer (Primary Key, Auto-increment)
- question: Text (Minimum 1 character)
- answer: Text (Minimum 1 character)
- deckId: Integer (Foreign Key → Decks.id)
- order: Integer (Default: 0)
- isFavorite: Boolean (Default: false)
- reviewCount: Integer (Default: 0)
- correctCount: Integer (Default: 0)
- lastReviewedAt: DateTime (Nullable)
- nextReviewAt: DateTime (Nullable)
- easeFactor: Real (Default: 2.5) - SM-2 algorithm
- interval: Integer (Default: 0) - SM-2 algorithm
- repetitions: Integer (Default: 0) - SM-2 algorithm
- questionType: Text (Default: 'identification')
- optionA: Text (Nullable) - For multiple choice
- optionB: Text (Nullable) - For multiple choice
- optionC: Text (Nullable) - For multiple choice
- optionD: Text (Nullable) - For multiple choice
- correctOption: Text (Nullable) - 'A', 'B', 'C', or 'D'
- enumerationItems: Text (Nullable) - JSON array of items
- explanation: Text (Nullable) - AI-generated explanation
- createdAt: DateTime
- updatedAt: DateTime
- deletedAt: DateTime (Nullable, for soft delete)
```

#### Tags
```dart
- id: Integer (Primary Key, Auto-increment)
- name: Text (1-50 characters)
- color: Text (Default: '#4CAF50')
- createdAt: DateTime
- updatedAt: DateTime
```

#### FlashcardTags (Junction Table)
```dart
- flashcardId: Integer (Foreign Key → Flashcards.id)
- tagId: Integer (Foreign Key → Tags.id)
- Primary Key: (flashcardId, tagId)
```

#### StudySessions
```dart
- id: Integer (Primary Key, Auto-increment)
- deckId: Integer (Foreign Key → Decks.id, Nullable)
- cardsStudied: Integer (Default: 0)
- cardsCorrect: Integer (Default: 0)
- durationSeconds: Integer (Default: 0)
- studyMode: Text (Default: 'review') - 'review', 'quiz', 'flashcard'
- startedAt: DateTime
- endedAt: DateTime (Nullable)
- createdAt: DateTime
```

#### QuizResults
```dart
- id: Integer (Primary Key, Auto-increment)
- deckId: Integer (Foreign Key → Decks.id, Nullable)
- totalQuestions: Integer (Default: 0)
- correctAnswers: Integer (Default: 0)
- score: Real (Default: 0.0)
- durationSeconds: Integer (Default: 0)
- quizType: Text (Default: 'practice') - 'practice', 'exam'
- completedAt: DateTime
- createdAt: DateTime
```

#### AiUsage
```dart
- id: Integer (Primary Key, Auto-increment)
- date: Text (YYYY-MM-DD format)
- usedCount: Integer (Default: 0)
- dailyLimit: Integer (Default: 15)
- lastResetAt: DateTime
- createdAt: DateTime
- updatedAt: DateTime
```

#### ExtractedDocuments
```dart
- id: Integer (Primary Key, Auto-increment)
- fileName: Text (1-255 characters)
- filePath: Text (1-500 characters)
- extractedText: Text
- selectedScope: Text (Default: 'all') - 'all', 'pages', 'headings', 'highlighted'
- scopeDetails: Text (Nullable) - JSON with page numbers, heading names, etc.
- totalPages: Integer (Default: 0)
- characterCount: Integer (Default: 0)
- createdAt: DateTime
- lastUsedAt: DateTime (Nullable)
```

### Database Migrations

The database has undergone 5 schema versions:

- **Version 1 → 2**: Added SM-2 algorithm fields (easeFactor, interval, repetitions)
- **Version 2 → 3**: Added analytics tables (StudySessions, QuizResults)
- **Version 3 → 4**: Added AI usage and document extraction tables
- **Version 4 → 5**: Added manual flashcard question type system

---

## State Management

QuizSnap uses a hybrid approach with both Provider (legacy) and Riverpod (modern):

### Provider (Legacy)
Used for:
- Theme management (`ThemeProvider`)
- Database provider (`DatabaseProvider`)
- Some legacy providers being migrated

### Riverpod (Modern)
Used for:
- AI features (`GroqProvider`, `AiQuotaProvider`)
- Study session management (`StudySessionController`)
- Security (`SecurityProvider`)
- Backup operations (`BackupProvider`)
- Most new features

### Provider Examples

**Riverpod Provider (AI Quota):**
```dart
final aiQuotaProvider = StateNotifierProvider<AiQuotaNotifier, AiQuotaState>((ref) {
  final database = ref.watch(databaseHolderProvider).database;
  return AiQuotaNotifier(database);
});
```

**Provider (Theme):**
```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
```

### State Management Patterns

**Repository Pattern:**
- Repositories handle data access logic
- Providers coordinate between repositories and UI
- Services handle business logic

**Optimistic Updates:**
- UI updates immediately on user action
- Database updates in background
- Rollback on failure

**Database Epoch Pattern:**
- `dbEpoch` tracks database version
- Providers reset when database changes
- Handles backup/restore scenarios

---

## Navigation

QuizSnap uses `go_router` for declarative routing:

### Router Configuration
**File:** `lib/core/navigation/app_router.dart`

**Key Routes:**
- `/` - Main screen with bottom navigation
- `/folders` - Folder management
- `/decks/create` - Create new deck
- `/decks/:deckId` - Deck details
- `/decks/:deckId/flashcards` - Flashcard list
- `/study` - Study home
- `/exam/:deckId/setup` - Exam setup
- `/ai-generate` - AI generation home
- `/analytics` - Analytics dashboard
- `/settings` - Settings
- `/trash` - Trash management

### Navigation Guards

**Security Guard:**
- Redirects to PIN lock if `SecurityProvider.isLocked`
- Applied globally in router redirect

**Focus Mode Guard:**
- Suspends auto-lock during study/exam
- Controlled by `FocusModeProvider`

**Error Handling:**
- Database error screen
- Network error screen
- Not found screen
- Invalid ID screen

### Back Button Handling
**File:** `lib/core/navigation/back_button_handler.dart`

Custom back button behavior for:
- Study sessions (confirm exit)
- Exam in progress (confirm exit)
- AI generation (confirm abort)

---

## API Integration

### Groq AI Service

**File:** `lib/core/services/groq_service.dart`

**Configuration:**
- API key stored securely using `flutter_secure_storage`
- Configurable model selection
- Daily quota management

**Endpoints Used:**
- Chat completion for question generation
- Text explanation generation

**Request Format:**
```dart
final response = await groq.chat.completions.create(
  model: 'llama3-8b-8192',
  messages: [
    ChatMessage(role: 'system', content: systemPrompt),
    ChatMessage(role: 'user', content: userPrompt),
  ],
  temperature: 0.7,
  maxTokens: 1000,
);
```

**Error Handling:**
- Connectivity guard before API calls
- Graceful degradation when offline
- User-friendly error messages
- Automatic retry on transient failures

### Prompt Templates

**File:** `lib/core/models/prompt_template.dart`

Pre-defined prompts for:
- Multiple choice question generation
- Identification question generation
- Enumeration question generation
- Answer explanation generation
- Question regeneration

---

## Development Setup

### Prerequisites

1. **Flutter SDK**: ^3.12.2
   ```bash
   flutter --version
   ```

2. **Dart SDK**: ^3.12.2 (included with Flutter)

3. **Platform-specific requirements:**
   - **Android**: Android Studio, Android SDK
   - **iOS**: Xcode (macOS only)
   - **Web**: Chrome/Edge browser

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd QuizSnap
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Environment Configuration

**API Keys:**
- Groq API key: Set via in-app settings (stored securely)
- No environment variables required

**Debug Configuration:**
```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run with specific device
flutter run -d <device-id>
```

### Code Generation

The project uses code generation for:
- Drift database (`database.g.dart`)
- JSON serialization
- Some provider classes

**Run code generation:**
```bash
# One-time generation
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## Build & Deployment

### Android

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**App Bundle (Play Store):**
```bash
flutter build appbundle --release
```

**Output Location:**
- APK: `build/app/outputs/flutter-apk/`
- Bundle: `build/app/outputs/bundle/release/`

### iOS

**Debug Build:**
```bash
flutter build ios --debug
```

**Release Build:**
```bash
flutter build ios --release
```

**Requirements:**
- Xcode installed
- Apple Developer account for App Store
- Proper code signing configuration

### Web

**Build:**
```bash
flutter build web
```

**Output Location:** `build/web/`

**Deployment:**
- Upload to any web server
- Supports Firebase Hosting, Netlify, Vercel, etc.

### Windows/macOS/Linux

**Build:**
```bash
flutter build windows  # or macos, linux
```

**Output Location:** `build/windows/runner/Release/`

---

## Testing

### Unit Tests

**Run unit tests:**
```bash
flutter test
```

**Test Location:** `test/`

**Coverage:**
- Repository layer tests
- Service layer tests
- Utility function tests

### Integration Tests

**Run integration tests:**
```bash
flutter test integration_test/
```

**Test Location:** `integration_test/`

**Existing Tests:**
- `selection_flow_test.dart` - UI flow testing
- Backup integration tests

### Widget Tests

**Run widget tests:**
```bash
flutter test test/widgets/
```

**Test Location:** `test/widgets/`

### Test Guidelines

1. **Arrange-Act-Assert Pattern:**
   ```dart
   test('should return flashcards by deck', () async {
     // Arrange
     final deck = await database.createDeck(testDeck);
     await database.createFlashcard(testFlashcard);
     
     // Act
     final flashcards = await database.getFlashcardsByDeck(deck.id);
     
     // Assert
     expect(flashcards.length, 1);
     expect(flashcards.first.question, testFlashcard.question);
   });
   ```

2. **Mock External Dependencies:**
   - Mock Groq API calls
   - Mock file system operations
   - Mock secure storage

3. **Test Database Operations:**
   - Use in-memory database for tests
   - Clean up after each test
   - Test migrations

---

## Code Style & Conventions

### Dart Style

**Follow Dart official guidelines:**
- `dart format` for formatting
- `dart analyze` for static analysis
- Effective Dart: https://dart.dev/guides/language/effective-dart

### Naming Conventions

**Files:**
- `snake_case.dart` for all files
- Feature-based organization

**Classes:**
- `PascalCase` for classes
- `camelCase` for methods and variables
- `_leadingUnderscore` for private members

**Constants:**
- `lowerCamelCase` for local constants
- `UPPER_SNAKE_CASE` for global constants

### File Organization

**Import Order:**
1. Dart imports
2. Package imports
3. Relative imports

**Example:**
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/my_service.dart';
import 'features/my_feature/my_screen.dart';
```

### Documentation

**Public APIs:**
```dart
/// Generates quiz questions from the provided text.
/// 
/// [text] is the source text to generate questions from.
/// [questionCount] is the number of questions to generate (5-50).
/// [difficulty] is the difficulty level (easy, medium, hard).
/// 
/// Returns a list of generated [Question] objects.
/// 
/// Throws [GroqException] if the API call fails.
Future<List<Question>> generateQuestions({
  required String text,
  required int questionCount,
  required String difficulty,
}) async {
  // Implementation
}
```

### Error Handling

**Try-catch patterns:**
```dart
try {
  final result = await riskyOperation();
  return result;
} on SocketException catch (e) {
  throw NetworkException('No internet connection');
} on FormatException catch (e) {
  throw DataException('Invalid data format');
} catch (e) {
  throw GenericException('An error occurred: $e');
}
```

### Async/Await

**Prefer async/await over futures:**
```dart
// Good
final flashcards = await database.getFlashcardsByDeck(deckId);

// Avoid
database.getFlashcardsByDeck(deckId).then((flashcards) {
  // Handle
});
```

---

## Troubleshooting

### Common Issues

**1. Database migration errors:**
```bash
# Clear app data
flutter clean
flutter pub get
flutter run
```

**2. Code generation issues:**
```bash
# Clean and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**3. Build errors on Android:**
```bash
# Clean Gradle cache
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**4. iOS build issues:**
```bash
# Clean Xcode build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**5. Groq API errors:**
- Verify API key is valid
- Check daily quota not exceeded
- Ensure internet connectivity
- Check Groq service status

### Debugging

**Enable debug logging:**
```dart
// In main.dart or relevant service
import 'package:flutter/foundation.dart';

debugPrint('Debug message: $variable');
```

**Database inspection:**
- Use Drift Inspector for development
- Check SQLite database files in device storage

**Network debugging:**
- Check connectivity guard logs
- Verify API key configuration
- Monitor quota usage

### Performance Optimization

**Database queries:**
- Use indexes on frequently queried columns
- Batch operations when possible
- Avoid N+1 query problems

**UI performance:**
- Use `const` widgets where possible
- Implement lazy loading for long lists
- Optimize image loading and caching

**Memory management:**
- Dispose controllers properly
- Close database connections
- Clear caches when not needed

---

## Contributing Guidelines

### Pull Request Process

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes and test:**
   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit changes:**
   ```bash
   git commit -m "Add your feature description"
   ```

5. **Push and create pull request**

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No linting errors
- [ ] All tests pass
- [ ] No breaking changes (or documented)

### Feature Request Template

```markdown
## Feature Description
Brief description of the feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should it be implemented?

## Alternatives
What alternatives were considered?

## Additional Context
Any additional information
```

---

## Additional Resources

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://gorouter.dev/)

### Tools
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
- [Drift Inspector](https://drift.simonbinder.eu/docs/tools/inspector/)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)

---

## License

[Add your license information here]

---

## Contact

For questions or support:
- [Add contact information]
- [Add repository issues link]

---

**Last Updated:** 2026-08-15  
**Maintained by:** QuizSnap Development Team
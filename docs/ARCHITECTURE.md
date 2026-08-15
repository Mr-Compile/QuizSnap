# QuizSnap Architecture Overview

**Version:** 1.0.0  
**Last Updated:** 2026-08-15

This document provides a high-level architectural overview of QuizSnap, explaining the key design decisions, patterns, and component interactions.

---

## Table of Contents

1. [Architectural Principles](#architectural-principles)
2. [System Architecture](#system-architecture)
3. [Data Flow](#data-flow)
4. [Component Interactions](#component-interactions)
5. [Design Patterns](#design-patterns)
6. [Security Architecture](#security-architecture)
7. [Performance Considerations](#performance-considerations)
8. [Scalability Considerations](#scalability-considerations)

---

## Architectural Principles

### 1. Offline-First Design

QuizSnap is designed to work primarily offline, with AI features being the only components requiring internet connectivity.

**Benefits:**
- Reliable operation regardless of network conditions
- Fast response times for core features
- Privacy (data stays on device)
- Reduced API costs

**Implementation:**
- Local SQLite database for all data storage
- Background sync for AI features when online
- Connectivity guards before API calls
- Graceful degradation when offline

### 2. Clean Architecture

The app follows clean architecture principles with clear separation of concerns:

**Layer Independence:**
- UI layer doesn't know about database implementation
- Business logic doesn't depend on UI framework
- Data access is abstracted through repositories

**Dependency Flow:**
```
UI → Providers → Services → Repositories → Database
```

### 3. State Management Strategy

**Hybrid Approach:**
- Riverpod for new features (modern, type-safe)
- Provider for legacy features (being migrated)
- Clear migration path to Riverpod

**State Ownership:**
- UI state: Managed by providers
- Business state: Managed by services
- Data state: Managed by repositories

### 4. Modular Feature Organization

**Feature-Based Structure:**
- Each feature is self-contained
- Clear boundaries between features
- Minimal cross-feature dependencies

**Feature Components:**
- UI screens and widgets
- Feature-specific providers
- Shared services and repositories

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Features   │  │   Shared     │  │   Theme      │       │
│  │   (UI)       │  │   Widgets    │  │   System     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   State Management Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Riverpod   │  │   Provider   │  │   Controllers│       │
│  │   Providers  │  │   (Legacy)   │  │              │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   AI         │  │   Study      │  │   Backup     │       │
│  │   Services   │  │   Services   │  │   Services   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Deck       │  │   Flashcard  │  │   Analytics  │       │
│  │   Repository │  │   Repository │  │   Repository │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Drift      │  │   Secure     │  │   Shared     │       │
│  │   Database   │  │   Storage    │  │   Prefs      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**Presentation Layer:**
- Renders UI based on state
- Handles user interactions
- Navigates between screens
- Displays data from providers

**State Management Layer:**
- Manages application state
- Coordinates between layers
- Handles state persistence
- Provides reactive data streams

**Service Layer:**
- Implements business logic
- Coordinates external API calls
- Handles complex operations
- Manages background tasks

**Repository Layer:**
- Abstracts data access
- Implements caching strategies
- Handles database operations
- Provides data transformation

**Data Layer:**
- Persistent storage (SQLite)
- Secure storage (API keys)
- Key-value storage (preferences)
- File system operations

---

## Data Flow

### Typical Data Flow: User Action

```
User Action (e.g., Create Flashcard)
    ↓
UI Widget (FlashcardCreateScreen)
    ↓
Provider (FlashcardProvider)
    ↓
Service (FlashcardService - validation, business logic)
    ↓
Repository (FlashcardRepository - data access)
    ↓
Database (Drift - SQLite operation)
    ↓
State Update (Provider notifies listeners)
    ↓
UI Rebuild (Widget updates with new state)
```

### AI Generation Data Flow

```
User Uploads Document
    ↓
Document Extraction Service (PDF/TXT/DOCX parsing)
    ↓
Text Processing (Heading detection, scope selection)
    ↓
Groq Service (API call with prompt)
    ↓
Response Processing (Parse AI response)
    ↓
Question Validation (Validate generated questions)
    ↓
UI Display (Question review screen)
    ↓
User Approval/Editing
    ↓
Database Storage (Save to flashcards table)
```

### Study Session Data Flow

```
User Starts Study Session
    ↓
Session Controller (Initialize session state)
    ↓
Repository (Get flashcards due for review)
    ↓
SM-2 Algorithm (Calculate review schedule)
    ↓
UI Display (Flashcard study screen)
    ↓
User Interaction (Rate card: Again/Hard/Good/Easy)
    ↓
Algorithm Update (Update SM-2 parameters)
    ↓
Repository (Update flashcard in database)
    ↓
Session Persistence (Save session progress)
    ↓
Analytics Update (Record study session)
```

---

## Component Interactions

### 1. Database Provider Pattern

**Purpose:** Centralized database access and lifecycle management

**Implementation:**
```dart
class DatabaseProvider extends ChangeNotifier {
  AppDatabase? _database;
  int dbEpoch = 0; // Tracks database version
  
  Future<AppDatabase> initializeDatabase() async {
    if (_database != null) return _database!;
    
    _database = await AppDatabase.open();
    dbEpoch++;
    notifyListeners();
    return _database!;
  }
  
  void resetDatabase() {
    _database = null;
    dbEpoch++;
    notifyListeners();
  }
}
```

**Benefits:**
- Single database instance
- Epoch tracking for provider updates
- Centralized initialization
- Easy reset for backup/restore

### 2. Repository Pattern

**Purpose:** Abstract data access logic

**Example:**
```dart
class FlashcardRepository {
  final AppDatabase database;
  
  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) {
    return database.getFlashcardsByDeck(deckId);
  }
  
  Future<void> updateFlashcardReview(int id, bool correct) {
    return database.updateFlashcardReview(id, correct);
  }
}
```

**Benefits:**
- Testable (can mock repositories)
- Centralized query logic
- Caching opportunities
- Consistent data access

### 3. Service Pattern

**Purpose:** Business logic coordination

**Example:**
```dart
class StudySessionService {
  final FlashcardRepository flashcardRepository;
  final StudyRepository studyRepository;
  
  Future<void> recordStudySession(StudySession session) async {
    // Business logic
    final duration = session.endedAt.difference(session.startedAt);
    
    // Update flashcards
    for (var card in session.cardsStudied) {
      await flashcardRepository.updateFlashcardReview(card.id, card.correct);
    }
    
    // Record session
    await studyRepository.createStudySession(session);
  }
}
```

**Benefits:**
- Complex operation coordination
- Transaction management
- Business rule enforcement
- Reusable logic

### 4. Provider Pattern

**Purpose:** State management and dependency injection

**Riverpod Example:**
```dart
final flashcardProvider = StateNotifierProvider<FlashcardNotifier, FlashcardState>((ref) {
  final repository = ref.watch(databaseHolderProvider).database;
  return FlashcardNotifier(repository);
});

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier(AppDatabase database) : super(FlashcardState.initial()) {
    _repository = FlashcardRepository(database);
  }
  
  Future<void> loadFlashcards(int deckId) async {
    state = FlashcardState.loading();
    try {
      final flashcards = await _repository.getFlashcardsByDeck(deckId);
      state = FlashcardState.loaded(flashcards);
    } catch (e) {
      state = FlashcardState.error(e.toString());
    }
  }
}
```

**Benefits:**
- Reactive state management
- Dependency injection
- Test isolation
- Type safety

---

## Design Patterns

### 1. Repository Pattern

**Usage:** All data access through repositories

**Implementation:**
- Abstract interface
- Concrete implementation
- Dependency injection

**Examples:**
- `DeckRepository`
- `FlashcardRepository`
- `StudyRepository`
- `AnalyticsRepository`

### 2. Service Pattern

**Usage:** Business logic coordination

**Implementation:**
- Stateless services
- Dependency injection
- Single responsibility

**Examples:**
- `GroqService` (AI integration)
- `BackupServiceEnhanced` (Backup operations)
- `StudySessionPersistence` (Session management)

### 3. Provider Pattern

**Usage:** State management

**Implementation:**
- Riverpod StateNotifier
- Provider ChangeNotifier
- Dependency injection

**Examples:**
- `SecurityProvider` (Security state)
- `ThemeProvider` (Theme state)
- `ExamProvider` (Exam state)

### 4. Observer Pattern

**Usage:** Reactive updates

**Implementation:**
- Provider listeners
- Riverpod watchers
- ChangeNotifier

**Examples:**
- UI updates on state changes
- Database epoch tracking
- Security state changes

### 5. Strategy Pattern

**Usage:** Interchangeable algorithms

**Implementation:**
- Question type strategies
- Study mode strategies
- Export format strategies

**Examples:**
- Different question type renderers
- Different study algorithms
- Different export formats

### 6. Factory Pattern

**Usage:** Object creation

**Implementation:**
- Database factory
- Service factories
- Model factories

**Examples:**
- Database initialization
- Flashcard creation
- Exam generation

### 7. Singleton Pattern

**Usage:** Single instance

**Implementation:**
- Database instance
- Service instances
- Provider instances

**Examples:**
- `DatabaseProvider`
- `SecurityProvider`
- `GroqService`

---

## Security Architecture

### 1. Data Security

**API Key Storage:**
- `flutter_secure_storage` for Groq API key
- Encrypted at rest
- Never logged or exposed

**Database Security:**
- Local SQLite database
- App-private storage
- No network transmission of user data

**File Security:**
- App-private storage for backups
- FileProvider for secure file sharing
- No unnecessary permissions

### 2. Authentication

**PIN Lock System:**
- Optional PIN lock
- Configurable timeout
- Session inactivity detection
- Focus mode (suspend lock during study)

**Implementation:**
```dart
class SecurityProvider extends ChangeNotifier {
  bool _isLocked = false;
  bool _isPinEnabled = false;
  String? _pinHash;
  
  Future<void> initialize() async {
    _isPinEnabled = await _loadPinEnabled();
    if (_isPinEnabled) {
      _pinHash = await _loadPinHash();
      lockApp();
    }
  }
  
  void lockApp() {
    if (!_isPinEnabled || _isLocked) return;
    _isLocked = true;
    notifyListeners();
  }
  
  Future<bool> verifyPin(String pin) async {
    if (!_isPinEnabled) return true;
    final hash = _hashPin(pin);
    if (hash == _pinHash) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }
}
```

### 3. Session Management

**Inactivity Detection:**
- `SessionInactivityService` tracks user activity
- Configurable warning period
- Automatic lock on timeout
- Manual lock option

**Focus Mode:**
- Suspends auto-lock during study/exam
- Prevents interruption
- Manual lock still available

### 4. Network Security

**API Communication:**
- HTTPS only for Groq API
- No sensitive data in API calls
- Request/response validation
- Error handling without exposing details

**Connectivity Guards:**
- Check connectivity before API calls
- Graceful degradation when offline
- User-friendly error messages
- Retry mechanisms

---

## Performance Considerations

### 1. Database Performance

**Optimizations:**
- Indexed columns on frequently queried fields
- Batch operations for bulk updates
- Query optimization with proper joins
- Connection pooling

**Strategies:**
- Lazy loading for large datasets
- Pagination for list views
- Caching frequently accessed data
- Background operations for heavy tasks

### 2. UI Performance

**Optimizations:**
- `const` widgets where possible
- Lazy loading for long lists
- Image caching and optimization
- Efficient rebuilds with providers

**Strategies:**
- Split large widgets into smaller ones
- Use `ListView.builder` instead of `ListView`
- Avoid unnecessary rebuilds
- Optimize animation performance

### 3. Memory Management

**Optimizations:**
- Proper disposal of controllers
- Clearing caches when not needed
- Closing database connections
- Managing image memory

**Strategies:**
- Use weak references where appropriate
- Implement proper cleanup in dispose
- Monitor memory usage
- Profile memory-intensive operations

### 4. Background Processing

**Optimizations:**
- Isolates for CPU-intensive tasks
- Background sync for AI features
- Scheduled cleanup tasks
- Efficient file operations

**Strategies:**
- Use `compute` for heavy calculations
- Implement proper error handling
- Provide user feedback
- Allow cancellation

---

## Scalability Considerations

### 1. Database Scalability

**Current Design:**
- SQLite for local storage
- Schema versioning for migrations
- Efficient query patterns

**Future Considerations:**
- Database indexing strategy
- Query optimization
- Data archiving for old records
- Potential cloud sync (optional)

### 2. Feature Scalability

**Current Design:**
- Modular feature organization
- Clear boundaries between features
- Minimal cross-feature dependencies

**Future Considerations:**
- Plugin architecture for extensions
- Feature flags for gradual rollout
- A/B testing framework
- Analytics-driven feature development

### 3. User Scalability

**Current Design:**
- Offline-first architecture
- Efficient local operations
- Minimal server dependencies

**Future Considerations:**
- Multi-device sync (optional)
- Cloud backup (optional)
- Collaborative features (optional)
- Export/import improvements

### 4. Performance Scalability

**Current Design:**
- Efficient algorithms (SM-2)
- Optimized database queries
- Lazy loading strategies

**Future Considerations:**
- Performance monitoring
- Profiling tools integration
- Adaptive performance based on device
- Resource usage optimization

---

## Technology Rationale

### Why Flutter?

**Cross-Platform:**
- Single codebase for Android, iOS, Web, Desktop
- Consistent UI across platforms
- Native performance

**Developer Experience:**
- Hot reload for fast development
- Rich widget library
- Strong tooling support

**Performance:**
- Native compilation
- Efficient rendering
- Smooth animations

### Why Drift?

**Type Safety:**
- Compile-time query validation
- Auto-generated code
- Strong typing

**Productivity:**
- SQL-like syntax
- Migration support
- Query builder

**Performance:**
- Efficient SQLite operations
- Connection pooling
- Transaction support

### Why Riverpod?

**Modern State Management:**
- Compile-time safety
- Testability
- No BuildContext dependency

**Performance:**
- Selective rebuilds
- Efficient state updates
- Memory efficiency

**Developer Experience:**
- Clear syntax
- Good documentation
- Strong community

### Why Groq AI?

**Performance:**
- Fast response times
- High-quality outputs
- Cost-effective

**Integration:**
- Simple API
- Good documentation
- Reliable service

**Privacy:**
- No data retention
- Secure API
- Flexible usage

---

## Future Architecture Considerations

### 1. Cloud Integration (Optional)

**Potential Features:**
- Cloud backup and sync
- Multi-device support
- Collaborative study
- Shared decks

**Architecture Impact:**
- Add cloud service layer
- Implement sync conflict resolution
- Add authentication (optional)
- Update data models for sync

### 2. Plugin System

**Potential Features:**
- Custom question types
- Custom study algorithms
- Third-party integrations
- Custom export formats

**Architecture Impact:**
- Define plugin interfaces
- Implement plugin loader
- Add plugin marketplace (optional)
- Update security model

### 3. Advanced Analytics

**Potential Features:**
- Machine learning insights
- Personalized recommendations
- Advanced visualizations
- Export analytics data

**Architecture Impact:**
- Enhance analytics repository
- Add ML service layer
- Update UI for new insights
- Implement data export

### 4. Social Features

**Potential Features:**
- Study groups
- Leaderboards
- Shared decks
- Discussion forums

**Architecture Impact:**
- Add social service layer
- Implement real-time communication
- Add permission system
- Update data models

---

## Conclusion

QuizSnap's architecture is designed to be:

- **Maintainable:** Clear separation of concerns and modular design
- **Scalable:** Efficient performance and room for growth
- **Secure:** Data protection and user privacy
- **Performant:** Optimized for smooth user experience
- **Testable:** Well-structured for unit and integration testing

The architecture supports the current feature set while providing a solid foundation for future enhancements.

---

**Last Updated:** 2026-08-15  
**Maintained by:** QuizSnap Development Team
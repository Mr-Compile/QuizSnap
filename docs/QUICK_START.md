# QuizSnap Quick Start Guide

**Version:** 1.0.0  
**Last Updated:** 2026-08-15

This guide helps new developers get started with QuizSnap quickly.

---

## Prerequisites

- Flutter SDK ^3.12.2
- Dart SDK ^3.12.2 (included with Flutter)
- Android Studio / Xcode (for mobile development)
- Git

---

## Installation (5 minutes)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd QuizSnap
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Code (if needed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App

```bash
flutter run
```

---

## Project Structure Overview

```
lib/
├── core/              # Core application logic
│   ├── database/     # SQLite database (Drift)
│   ├── models/       # Data models
│   ├── providers/    # State management
│   ├── repositories/ # Data access layer
│   ├── services/     # Business logic
│   └── navigation/   # Routing
├── features/         # Feature-based UI
│   ├── ai_generate/ # AI question generation
│   ├── analytics/   # Analytics dashboard
│   ├── decks/       # Deck management
│   ├── exam/        # Exam functionality
│   ├── study/       # Study modes
│   └── settings/    # App settings
└── main.dart        # App entry point
```

---

## Key Technologies

- **UI Framework:** Flutter
- **Database:** Drift (SQLite)
- **State Management:** Riverpod + Provider
- **Navigation:** go_router
- **AI Integration:** Groq API
- **Charts:** fl_chart

---

## Common Tasks

### Add a New Screen

1. Create screen file in appropriate feature folder:
```dart
// lib/features/my_feature/my_screen.dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(child: Text('Hello World')),
    );
  }
}
```

2. Add route to `lib/core/navigation/app_routes.dart`:
```dart
static const String myScreen = '/my-screen';
```

3. Add route configuration to `lib/core/navigation/app_router.dart`:
```dart
GoRoute(
  path: AppRoutes.myScreen,
  builder: (context, state) => const MyScreen(),
),
```

### Add a New Database Table

1. Add table definition to `lib/core/database/database.dart`:
```dart
class MyTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

2. Add table to `@DriftDatabase` annotation:
```dart
@DriftDatabase(tables: [Folders, Decks, Flashcards, MyTable])
```

3. Increment schema version and add migration:
```dart
@override
int get schemaVersion => 6; // Increment

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 6 && to >= 6) {
        await m.createTable(myTable);
      }
    },
  );
}
```

4. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Create a New Provider

**Riverpod Provider:**
```dart
// lib/core/providers/my_provider.dart
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial());
  
  void doSomething() {
    state = MyState.loading();
    // Perform action
    state = MyState.loaded();
  }
}

class MyState {
  final bool isLoading;
  final String? data;
  
  MyState({this.isLoading = false, this.data});
  
  factory MyState.initial() => MyState();
  factory MyState.loading() => MyState(isLoading: true);
  factory MyState.loaded(String data) => MyState(data: data);
}
```

**Provider (Legacy):**
```dart
// lib/core/providers/my_provider.dart
class MyProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _data;
  
  bool get isLoading => _isLoading;
  String? get data => _data;
  
  Future<void> doSomething() async {
    _isLoading = true;
    notifyListeners();
    
    // Perform action
    
    _isLoading = false;
    notifyListeners();
  }
}
```

### Add AI Integration

1. Create service method in `lib/core/services/groq_service.dart`:
```dart
Future<String> generateContent(String prompt) async {
  try {
    final response = await groq.chat.completions.create(
      model: 'llama3-8b-8192',
      messages: [
        ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
        ChatMessage(role: 'user', content: prompt),
      ],
    );
    
    return response.choices.first.message.content;
  } catch (e) {
    throw GroqException('Failed to generate content: $e');
  }
}
```

2. Use in provider:
```dart
final result = await groqService.generateContent('Generate a question');
```

### Run Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web
```

---

## Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
# ...

# Run tests
flutter test

# Run analyzer
flutter analyze

# Format code
dart format .

# Commit changes
git commit -m "Add my feature"

# Push and create PR
git push origin feature/my-feature
```

### 2. Code Generation

When modifying database schema or models:

```bash
# Clean previous generation
flutter pub run build_runner clean

# Generate new code
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch for changes
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Debugging

```bash
# Run in debug mode
flutter run

# Run with specific device
flutter run -d chrome

# Enable observatory
flutter run --observatory-port=8888

# Profile mode
flutter run --profile
```

---

## Common Issues & Solutions

### Database Migration Error

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Code Generation Issues

```bash
# Clean build cache
flutter pub run build_runner clean

# Regenerate with conflict resolution
flutter pub run build_runner build --delete-conflicting-outputs
```

### Import Errors

```bash
# Get dependencies again
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
```

### Build Errors (Android)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## Useful Commands

```bash
# Flutter version
flutter --version

# List devices
flutter devices

# Upgrade Flutter
flutter upgrade

# Doctor check
flutter doctor

# Format code
dart format .

# Analyze code
flutter analyze

# Run specific test
flutter test test/my_test.dart

# Build icons
flutter pub run flutter_launcher_icons

# Build splash screen
flutter pub run flutter_native_splash:create
```

---

## Next Steps

1. Read the [Developer Guide](DEVELOPER_GUIDE.md) for detailed documentation
2. Review the [Architecture Overview](ARCHITECTURE.md) for system design
3. Check the [User Manual](USER_MANUAL.md) for feature understanding
4. Explore the codebase starting with `lib/main.dart`

---

## Getting Help

- Check existing documentation in `docs/`
- Review code comments and examples
- Run `flutter doctor` to check environment
- Check Flutter documentation: https://docs.flutter.dev/

---

**Last Updated:** 2026-08-15  
**Maintained by:** QuizSnap Development Team
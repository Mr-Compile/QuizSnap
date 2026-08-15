# QuizSnap

<div align="center">

![QuizSnap Logo](assets/branding/app_icon.png)

**An intelligent offline-first flashcard and study application built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.12.2-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[Features](#-features) • [Getting Started](#-getting-started) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

## 📖 About

QuizSnap is a powerful offline-first flashcard and study application that helps users learn effectively using spaced repetition, AI-powered question generation, and detailed analytics. Built with Flutter, it runs seamlessly on Android, iOS, Windows, macOS, Linux, and Web.

### ✨ Key Capabilities

- **🧠 Smart Flashcard Management**: Create, organize, and study flashcards manually or via AI
- **📚 Multiple Study Modes**: List Mode, Quiz Mode, and Today's Review with SM-2 spaced repetition
- **🎯 Exam Mode**: Timed exams generated from deck content with detailed results
- **🤖 AI Integration**: Generate questions from PDF, TXT, DOCX, or camera OCR using Groq AI
- **📊 Analytics Dashboard**: Track study time, accuracy, streaks, and mastery
- **💾 Data Management**: Backup/restore, export to PDF, trash/restore system
- **🔒 Security**: Optional PIN lock and session management
- **📁 Organization**: Folders, tags, and bookmarks for content organization

## 🚀 Features

### Flashcard System
- **Multiple Question Types**: Identification, Enumeration, Multiple Choice
- **SM-2 Spaced Repetition**: Optimized learning schedule based on performance
- **Bookmark & Tag System**: Easy organization and quick access
- **Shuffle Functionality**: Randomized study sessions

### Study Modes
- **List Mode**: Browse all cards with study functionality
- **Quiz Mode**: Self-graded quiz with immediate feedback
- **Today's Review**: SM-2 algorithm-based review scheduling
- **Confidence Tracking**: Rate your answers before revealing

### Exam System
- Configurable question count (5-100)
- Time limits (1-120 minutes)
- Shuffle option for randomization
- Real-time countdown timer
- Pause/resume functionality
- AI explanation integration

### AI Integration
- Question generation from documents (PDF, TXT, DOCX)
- Camera OCR for text extraction
- Question regeneration options
- Difficulty levels (Easy, Medium, Hard)
- Answer explanation generation
- Daily quota management

### Analytics
- Daily activity tracking
- Study time analysis
- Quiz performance history
- Mastery breakdown per deck
- Subject accuracy metrics
- Weak topic identification
- Streak tracking

### Data Management
- Automatic scheduled backups
- Manual backup creation
- Backup history management
- Import preview before restore
- Export to PDF and CSV
- Trash system with auto-cleanup

## 🛠 Tech Stack

### Core Framework
- **Flutter**: ^3.12.2 - UI framework
- **Dart**: ^3.12.2 - Programming language

### Database & Storage
- **Drift**: ^2.14.0 - SQLite ORM
- **sqlite3_flutter_libs**: ^0.5.18 - SQLite native libraries
- **flutter_secure_storage**: ^9.0.0 - Secure storage for API keys

### State Management
- **Provider**: ^6.1.1 - Legacy state management
- **flutter_riverpod**: ^2.4.9 - Modern state management

### Navigation
- **go_router**: ^13.0.0 - Declarative routing

### AI & Document Processing
- **groq**: ^1.1.1 - AI API client
- **syncfusion_flutter_pdf**: ^29.2.11 - PDF processing
- **google_mlkit_text_recognition**: ^0.11.0 - OCR

### UI Components
- **google_fonts**: ^6.1.0 - Typography
- **flutter_slidable**: ^3.0.1 - Swipe actions
- **fl_chart**: ^0.66.0 - Charts and graphs

## 🏗 Architecture

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

## 📁 Project Structure

```
QuizSnap/
├── lib/
│   ├── core/                   # Core application logic
│   │   ├── database/          # Database schema and queries
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── repositories/       # Data access layer
│   │   ├── services/          # Business logic
│   │   ├── navigation/        # Routing configuration
│   │   └── theme/             # App theming
│   ├── features/              # Feature-based UI organization
│   │   ├── ai_generate/       # AI question generation
│   │   ├── analytics/         # Analytics dashboard
│   │   ├── decks/             # Deck management
│   │   ├── exam/              # Exam functionality
│   │   ├── flashcards/        # Flashcard management
│   │   └── study/             # Study modes
│   └── main.dart              # App entry point
├── assets/                     # Static assets
├── docs/                      # Documentation
└── test/                      # Unit and integration tests
```

## 🚀 Getting Started

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

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/QuizSnap.git
   cd QuizSnap
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Configuration

**API Keys:**
- Groq API key: Set via in-app settings (stored securely)
- No environment variables required

## 📱 Building

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Debug Build
flutter build ios --debug

# Release Build
flutter build ios --release
```

### Web
```bash
flutter build web
```

### Desktop
```bash
flutter build windows  # or macos, linux
```

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widgets/
```

## 📖 Documentation

For detailed documentation, see the [Developer Guide](docs/DEVELOPER_GUIDE.md).

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No linting errors
- [ ] All tests pass

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions or support:
- Open an issue on GitHub
- Check the [Developer Guide](docs/DEVELOPER_GUIDE.md)
- Join our community discussions

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Groq AI for providing the AI API
- Drift for the excellent SQLite ORM
- All contributors to this project

---

<div align="center">

**Built with ❤️ using Flutter**

[⬆ Back to top](#quizsnap)

</div>

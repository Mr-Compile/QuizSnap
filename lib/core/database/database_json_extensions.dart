part of 'database.dart';

// Extension methods for JSON serialization
extension FolderJson on Folder {
  static Folder fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }
}

extension DeckJson on Deck {
  static Deck fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      folderId: json['folderId'] as int?,
      color: json['color'] as String,
      cardCount: json['cardCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    );
  }
}

extension FlashcardJson on Flashcard {
  static Flashcard fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      deckId: json['deckId'] as int,
      order: json['order'] as int,
      isFavorite: json['isFavorite'] as bool,
      reviewCount: json['reviewCount'] as int,
      correctCount: json['correctCount'] as int,
      lastReviewedAt: json['lastReviewedAt'] != null ? DateTime.parse(json['lastReviewedAt'] as String) : null,
      nextReviewAt: json['nextReviewAt'] != null ? DateTime.parse(json['nextReviewAt'] as String) : null,
      easeFactor: json['easeFactor'] as double,
      interval: json['interval'] as int,
      repetitions: json['repetitions'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      // Question type system (schema v5).  Old backups may omit these
      // fields, so they default to 'identification' / null.
      questionType: json['questionType'] as String? ?? 'identification',
      optionA: json['optionA'] as String?,
      optionB: json['optionB'] as String?,
      optionC: json['optionC'] as String?,
      optionD: json['optionD'] as String?,
      correctOption: json['correctOption'] as String?,
      enumerationItems: json['enumerationItems'] as String?,
      explanation: json['explanation'] as String?,
    );
  }
}

extension TagJson on Tag {
  static Tag fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

extension FlashcardTagJson on FlashcardTag {
  static FlashcardTag fromJson(Map<String, dynamic> json) {
    return FlashcardTag(
      flashcardId: json['flashcardId'] as int,
      tagId: json['tagId'] as int,
    );
  }
}

extension StudySessionJson on StudySession {
  static StudySession fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as int,
      deckId: json['deckId'] as int?,
      cardsStudied: json['cardsStudied'] as int,
      cardsCorrect: json['cardsCorrect'] as int,
      durationSeconds: json['durationSeconds'] as int,
      studyMode: json['studyMode'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

extension QuizResultJson on QuizResult {
  static QuizResult fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] as int,
      deckId: json['deckId'] as int?,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      score: json['score'] as double,
      durationSeconds: json['durationSeconds'] as int,
      quizType: json['quizType'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

extension AiUsageJson on AiUsageData {
  static AiUsageData fromJson(Map<String, dynamic> json) {
    return AiUsageData(
      id: json['id'] as int,
      date: json['date'] as String,
      usedCount: json['usedCount'] as int,
      dailyLimit: json['dailyLimit'] as int,
      lastResetAt: DateTime.parse(json['lastResetAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

extension ExtractedDocumentJson on ExtractedDocument {
  static ExtractedDocument fromJson(Map<String, dynamic> json) {
    return ExtractedDocument(
      id: json['id'] as int,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      extractedText: json['extractedText'] as String,
      selectedScope: json['selectedScope'] as String,
      scopeDetails: json['scopeDetails'] as String?,
      totalPages: json['totalPages'] as int,
      characterCount: json['characterCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt'] as String) : null,
    );
  }
}
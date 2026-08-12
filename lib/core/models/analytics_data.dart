/// Strongly-typed analytics data classes used by charts and providers.
///
/// These models replace untyped dynamic maps and guarantee every numeric
/// value exposed to the UI is a `double` or a non-null default.
class SubjectAccuracyData {
  final int deckId;
  final String deckName;
  final double accuracy;
  final int totalCards;

  SubjectAccuracyData({
    required this.deckId,
    required this.deckName,
    required this.accuracy,
    required this.totalCards,
  });

  factory SubjectAccuracyData.empty() {
    return SubjectAccuracyData(
      deckId: 0,
      deckName: '',
      accuracy: 0.0,
      totalCards: 0,
    );
  }

  SubjectAccuracyData copyWith({
    int? deckId,
    String? deckName,
    double? accuracy,
    int? totalCards,
  }) {
    return SubjectAccuracyData(
      deckId: deckId ?? this.deckId,
      deckName: deckName ?? this.deckName,
      accuracy: accuracy ?? this.accuracy,
      totalCards: totalCards ?? this.totalCards,
    );
  }
}

class DeckAccuracyData {
  final int deckId;
  final String deckName;
  final double accuracy;
  final int totalCards;

  DeckAccuracyData({
    required this.deckId,
    required this.deckName,
    required this.accuracy,
    required this.totalCards,
  });

  double get accuracyPercent => accuracy.toDouble();

  factory DeckAccuracyData.empty() {
    return DeckAccuracyData(
      deckId: 0,
      deckName: '',
      accuracy: 0.0,
      totalCards: 0,
    );
  }

  DeckAccuracyData copyWith({
    int? deckId,
    String? deckName,
    double? accuracy,
    int? totalCards,
  }) {
    return DeckAccuracyData(
      deckId: deckId ?? this.deckId,
      deckName: deckName ?? this.deckName,
      accuracy: accuracy ?? this.accuracy,
      totalCards: totalCards ?? this.totalCards,
    );
  }
}

class WeakTopicChartItem {
  final int deckId;
  final String name;
  final double accuracy;
  final int cardCount;

  WeakTopicChartItem({
    required this.deckId,
    required this.name,
    required this.accuracy,
    required this.cardCount,
  });

  bool get isWeak => accuracy < 70.0;

  double get accuracyPercent => accuracy.toDouble();

  WeakTopicChartItem copyWith({
    int? deckId,
    String? name,
    double? accuracy,
    int? cardCount,
  }) {
    return WeakTopicChartItem(
      deckId: deckId ?? this.deckId,
      name: name ?? this.name,
      accuracy: accuracy ?? this.accuracy,
      cardCount: cardCount ?? this.cardCount,
    );
  }
}

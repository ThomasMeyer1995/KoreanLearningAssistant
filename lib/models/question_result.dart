import 'vocab_item.dart';

class QuestionResult {
  final int number;
  final String section;
  final String myAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final List<VocabItem> items;

  QuestionResult({
    required this.number,
    required this.section,
    required this.myAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.items = const [],
  });

  QuestionResult copyWith({
    int? number,
    String? section,
    String? myAnswer,
    String? correctAnswer,
    bool? isCorrect,
    List<VocabItem>? items,
  }) {
    return QuestionResult(
      number: number ?? this.number,
      section: section ?? this.section,
      myAnswer: myAnswer ?? this.myAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'section': section,
        'myAnswer': myAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      number: (json['number'] as num).toInt(),
      section: json['section'] as String? ?? '',
      myAnswer: json['myAnswer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      items: ((json['items'] as List?) ?? const [])
          .map((e) => VocabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

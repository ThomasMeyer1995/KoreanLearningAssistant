import 'question_result.dart';
import 'vocab_item.dart';

class SectionScore {
  final String section;
  final int total;
  final int correct;

  SectionScore({required this.section, required this.total, required this.correct});

  double get percent => total == 0 ? 0 : correct / total * 100;

  Map<String, dynamic> toJson() => {
        'section': section,
        'total': total,
        'correct': correct,
      };

  factory SectionScore.fromJson(Map<String, dynamic> json) => SectionScore(
        section: json['section'] as String,
        total: (json['total'] as num).toInt(),
        correct: (json['correct'] as num).toInt(),
      );
}

class ExamSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<QuestionResult> questions;

  ExamSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.questions = const [],
  });

  List<QuestionResult> get scoredQuestions =>
      questions.where((q) => q.number > 0).toList();

  int get totalQuestions => scoredQuestions.length;

  int get correctCount => scoredQuestions.where((q) => q.isCorrect).length;

  double get percent =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions * 100;

  String get scoreLabel => '$correctCount/$totalQuestions (${percent.toStringAsFixed(0)}%)';

  List<SectionScore> get sectionScores {
    final result = <SectionScore>[];
    for (final q in scoredQuestions) {
      final existing = result.indexWhere((s) => s.section == q.section);
      if (existing == -1) {
        result.add(SectionScore(
          section: q.section,
          total: 1,
          correct: q.isCorrect ? 1 : 0,
        ));
      } else {
        result[existing] = SectionScore(
          section: q.section,
          total: result[existing].total + 1,
          correct: result[existing].correct + (q.isCorrect ? 1 : 0),
        );
      }
    }
    return result;
  }

  List<VocabItem> get allItems =>
      questions.expand((q) => q.items).toList(growable: false);

  List<VocabItem> get missedItems =>
      scoredQuestions.where((q) => !q.isCorrect).expand((q) => q.items).toList(growable: false);

  static List<VocabItem> distinctByKorean(List<VocabItem> items) {
    final byKey = <String, VocabItem>{};
    for (final item in items) {
      final key = item.korean.trim().toLowerCase();
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = item;
      } else {
        byKey[key] = existing.copyWith(
          missed: existing.missed || item.missed,
          knownCount: existing.knownCount + item.knownCount,
          exampleKr: existing.exampleKr.isNotEmpty ? existing.exampleKr : item.exampleKr,
          exampleEn: existing.exampleEn.isNotEmpty ? existing.exampleEn : item.exampleEn,
        );
      }
    }
    return byKey.values.toList(growable: false);
  }

  ExamSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<QuestionResult>? questions,
  }) {
    return ExamSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
    );
  }

  ExamSession withItemReplaced(VocabItem updated) {
    return copyWith(questions: [
      for (final q in questions)
        q.copyWith(items: [
          for (final item in q.items) item.id == updated.id ? updated : item,
        ]),
    ]);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    return ExamSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled exam',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      questions: ((json['questions'] as List?) ?? const [])
          .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:korean_learning_assistant/models/exam_session.dart';
import 'package:korean_learning_assistant/models/question_result.dart';
import 'package:korean_learning_assistant/models/vocab_item.dart';

VocabItem item(String korean, {bool missed = false, int known = 0}) => VocabItem(
      id: korean,
      korean: korean,
      english: 'en-$korean',
      type: VocabType.vocabulary,
      missed: missed,
      knownCount: known,
    );

ExamSession sessionWith(List<QuestionResult> questions) => ExamSession(
      id: 's1',
      title: 'T',
      createdAt: DateTime(2026, 1, 1),
      questions: questions,
    );

void main() {
  group('ExamSession scoring', () {
    test('section scores and overall percent', () {
      final s = sessionWith([
        QuestionResult(number: 1, section: 'Listening', myAnswer: '1', correctAnswer: '1', isCorrect: true),
        QuestionResult(number: 2, section: 'Listening', myAnswer: '2', correctAnswer: '3', isCorrect: false),
        QuestionResult(number: 3, section: 'Reading', myAnswer: '4', correctAnswer: '4', isCorrect: true),
      ]);
      expect(s.totalQuestions, 3);
      expect(s.correctCount, 2);
      expect(s.percent, closeTo(66.67, 0.01));
      expect(s.scoreLabel, startsWith('2/3 (67%)'));
      final listening = s.sectionScores.firstWhere((x) => x.section == 'Listening');
      expect(listening.total, 2);
      expect(listening.correct, 1);
      expect(listening.percent, 50);
    });

    test('unnumbered note questions are not scored', () {
      final s = sessionWith([
        QuestionResult(number: 0, section: 'Notes', myAnswer: '', correctAnswer: '', isCorrect: true, items: [item('사과')]),
        QuestionResult(number: 1, section: 'Listening', myAnswer: '1', correctAnswer: '1', isCorrect: true),
      ]);
      expect(s.totalQuestions, 1);
      expect(s.allItems, hasLength(1));
    });
  });

  group('distinctByKorean', () {
    test('merges duplicates, keeps missed flag and examples', () {
      final merged = ExamSession.distinctByKorean([
        item('사과', missed: false),
        item('사과', missed: true, known: 2),
      ]);
      expect(merged, hasLength(1));
      expect(merged.single.missed, isTrue);
      expect(merged.single.knownCount, 2);
    });
  });

  group('json roundtrip', () {
    test('session survives toJson/fromJson', () {
      final s = sessionWith([
        QuestionResult(
          number: 1,
          section: 'Listening',
          myAnswer: '1',
          correctAnswer: '2',
          isCorrect: false,
          items: [
            VocabItem(
              id: 'i1',
              korean: '사과',
              english: 'apple',
              type: VocabType.vocabulary,
              exampleKr: '사과를 먹어요.',
              exampleEn: 'I eat an apple.',
              questionNumber: 1,
              section: 'Listening',
              missed: true,
              knownCount: 3,
            ),
          ],
        ),
      ]);
      final restored = ExamSession.fromJson(s.toJson());
      expect(restored.id, s.id);
      expect(restored.title, s.title);
      expect(restored.questions.single.items.single.korean, '사과');
      expect(restored.questions.single.items.single.knownCount, 3);
      expect(restored.questions.single.isCorrect, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:korean_learning_assistant/core/answer_sheet_parser.dart';

void main() {
  group('AnswerSheetParser', () {
    test('parses title, sections and answers', () {
      final session = AnswerSheetParser.parse('''
# TOPIK II 83회
## Listening
1. 3 -> 4 | 사과 (apple)
2. 2 -> 2
## Reading
3. 1 -> 3
''');

      expect(session.title, 'TOPIK II 83회');
      expect(session.questions, hasLength(3));
      expect(session.questions[0].section, 'Listening');
      expect(session.questions[0].isCorrect, isFalse);
      expect(session.questions[1].isCorrect, isTrue);
      expect(session.questions[2].section, 'Reading');
      expect(session.questions[2].isCorrect, isFalse);
    });

    test('normalizes circled digits and 번', () {
      expect(AnswerSheetParser.normalizeAnswer('③'), '3');
      expect(AnswerSheetParser.normalizeAnswer('4번'), '4');
      expect(AnswerSheetParser.normalizeAnswer(' ② '), '2');

      final session = AnswerSheetParser.parse('1. ③ -> ③');
      expect(session.questions.single.isCorrect, isTrue);
    });

    test('parses vocab, grammar and example annotations', () {
      final session = AnswerSheetParser.parse(
        '1. 1 -> 2 | 사과 (apple) | 예: 사과를 먹어요. (I eat an apple.) | grammar: -아요 (polite ending)',
      );
      final items = session.questions.single.items;
      expect(items, hasLength(2));
      expect(items[0].korean, '사과');
      expect(items[0].english, 'apple');
      expect(items[0].type.name, 'vocabulary');
      expect(items[0].exampleKr, '사과를 먹어요.');
      expect(items[0].exampleEn, 'I eat an apple.');
      expect(items[0].missed, isTrue);
      expect(items[1].type.name, 'grammar');
      expect(items[1].korean, '-아요');
    });

    test('supports Korean annotation prefixes', () {
      final session = AnswerSheetParser.parse(
        '1. 1 -> 1 | 단어: 약속 (appointment) | 문법: -(으)니까 (because) | 예문: 비가 오니까 (Because it rains)',
      );
      final items = session.questions.single.items;
      expect(items[0].english, 'appointment');
      expect(items[1].type.name, 'grammar');
      expect(items[1].exampleKr, '비가 오니까');
      expect(items[1].exampleEn, 'Because it rains');
    });

    test('numbered line without arrow counts as incorrect', () {
      final session = AnswerSheetParser.parse('1. 4');
      expect(session.questions.single.isCorrect, isFalse);
      expect(session.questions.single.myAnswer, '');
    });

    test('free lines become unnumbered notes, not scored questions', () {
      final session = AnswerSheetParser.parse('''
# Exam
사과 (apple)
1. 1 -> 1
''');
      expect(session.totalQuestions, 1);
      expect(session.allItems.single.korean, '사과');
      expect(session.allItems.single.questionNumber, 0);
    });

    test('empty text yields an empty session with fallback title', () {
      final session = AnswerSheetParser.parse('   \n  ');
      expect(session.questions, isEmpty);
      expect(session.title, 'Untitled exam');
    });

    test('score aggregates over the whole sheet', () {
      final session = AnswerSheetParser.parse('''
# Mock
## Listening
1. 1 -> 1
2. 2 -> 3
## Reading
3. 4 -> 4
4. 1 -> 2
''');
      expect(session.totalQuestions, 4);
      expect(session.correctCount, 2);
      expect(session.percent, 50);
      expect(session.sectionScores.map((s) => s.section), ['Listening', 'Reading']);
      expect(session.sectionScores[0].correct, 1);
      expect(session.sectionScores[0].total, 2);
    });

    test('missed items come only from wrong answers', () {
      final session = AnswerSheetParser.parse('''
1. 1 -> 2 | 사과 (apple)
2. 1 -> 1 | 약속 (appointment)
3. 3 -> 1 | 금방 (soon)
''');
      final missed = session.missedItems.map((e) => e.korean).toList();
      expect(missed, containsAll(['사과', '금방']));
      expect(missed, isNot(contains('약속')));
    });
  });
}

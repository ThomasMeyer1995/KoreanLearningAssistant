import 'package:flutter_test/flutter_test.dart';
import 'package:korean_learning_assistant/core/answer_sheet_parser.dart';
import 'package:korean_learning_assistant/core/exam_store.dart';
import 'package:korean_learning_assistant/models/vocab_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExamStore persistence', () {
    test('sessions survive save and reload', () async {
      final store = ExamStore();
      await store.load();
      await store.addSession(AnswerSheetParser.parse('# Exam A\n1. 1 -> 1 | 사과 (apple)'));
      expect(store.sessions, hasLength(1));

      final reloaded = ExamStore();
      await reloaded.load();
      expect(reloaded.sessions, hasLength(1));
      expect(reloaded.sessions.first.title, 'Exam A');
      expect(reloaded.sessions.first.allItems.single.korean, '사과');
    });

    test('deleteSession removes and persists', () async {
      final store = ExamStore();
      await store.load();
      final session = AnswerSheetParser.parse('# Exam B\n1. 1 -> 2');
      await store.addSession(session);
      await store.deleteSession(session.id);
      expect(store.sessions, isEmpty);

      final reloaded = ExamStore();
      await reloaded.load();
      expect(reloaded.sessions, isEmpty);
    });

    test('markItemKnown increments knownCount and persists', () async {
      final store = ExamStore();
      await store.load();
      final session = AnswerSheetParser.parse('1. 1 -> 1 | 사과 (apple)');
      await store.addSession(session);
      final itemId = session.allItems.single.id;

      await store.markItemKnown(session.id, itemId);
      await store.markItemKnown(session.id, itemId);

      final reloaded = ExamStore();
      await reloaded.load();
      expect(reloaded.sessions.single.allItems.single.knownCount, 2);
    });

    test('addItemToSession adds to empty session and to existing one', () async {
      final store = ExamStore();
      await store.load();
      final empty = AnswerSheetParser.parse('# Empty');
      await store.addSession(empty);
      await store.addItemToSession(empty.id, VocabItem(
        id: 'x1',
        korean: '테스트',
        english: 'test',
        type: VocabType.grammar,
      ));
      expect(store.findSession(empty.id)!.allItems.single.korean, '테스트');

      final withQ = AnswerSheetParser.parse('1. 1 -> 1');
      await store.addSession(withQ);
      await store.addItemToSession(withQ.id, VocabItem(
        id: 'x2',
        korean: '단어',
        english: 'word',
        type: VocabType.vocabulary,
      ));
      expect(store.findSession(withQ.id)!.allItems.single.korean, '단어');
    });
  });

  group('export / import', () {
    test('exportJson -> importJson roundtrip, duplicates skipped', () async {
      final store = ExamStore();
      await store.load();
      await store.addSession(AnswerSheetParser.parse('# A\n1. 1 -> 2 | 사과 (apple)'));
      await store.addSession(AnswerSheetParser.parse('# B\n2. 2 -> 2'));
      final json = store.exportJson();

      SharedPreferences.setMockInitialValues({});
      final other = ExamStore();
      await other.load();
      final added = await other.importJson(json);
      expect(added, 2);
      expect(other.sessions.map((s) => s.title), containsAll(['A', 'B']));

      final addedAgain = await other.importJson(json);
      expect(addedAgain, 0);
      expect(other.sessions, hasLength(2));
    });

    test('importJson rejects invalid files', () async {
      final store = ExamStore();
      await store.load();
      expect(() => store.importJson('{"nope": true}'), throwsFormatException);
      expect(() => store.importJson('[1,2]'), throwsFormatException);
    });
  });
}

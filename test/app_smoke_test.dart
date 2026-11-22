import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korean_learning_assistant/app.dart';
import 'package:korean_learning_assistant/core/exam_store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sample asset is bundled', () async {
    final text = await rootBundle.loadString('assets/sample_answer_sheet.txt');
    expect(text, contains('사과'));
  });

  testWidgets('home -> paste -> parse -> session detail shows score and missed list',
      (tester) async {
    final store = ExamStore();
    await store.load();
    await tester.pumpWidget(KoreanLearningApp(store: store));
    expect(find.text('Korean Learning Assistant'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('New answer sheet'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '# Demo exam\n## Listening\n1. 1 -> 2 | 사과 (apple) | 예: 사과를 먹어요. (I eat an apple.)\n2. 2 -> 2 | 약속 (appointment)',
    );
    await tester.tap(find.text('Parse & save'));
    await tester.pumpAndSettle();

    expect(find.text('Demo exam'), findsOneWidget);
    expect(find.text('1/2 (50%)'), findsWidgets);
    expect(find.text('Missed (1)'), findsOneWidget);
    expect(find.text('All (2)'), findsOneWidget);

    await tester.tap(find.text('Missed (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Missed vocabulary'), findsOneWidget);
    expect(find.text('사과'), findsOneWidget);
    expect(find.text('약속'), findsNothing);

    await tester.tap(find.text('사과'));
    await tester.pumpAndSettle();
    expect(find.text('사과를 먹어요.'), findsOneWidget);
    expect(find.text('I eat an apple.'), findsOneWidget);
  });

  testWidgets('flashcards: flip and mark got it', (tester) async {
    final store = ExamStore();
    await store.load();
    await tester.pumpWidget(KoreanLearningApp(store: store));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '# Demo\n1. 1 -> 2 | 사과 (apple)',
    );
    await tester.tap(find.text('Parse & save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flashcards: missed'));
    await tester.pumpAndSettle();
    expect(find.text('사과'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    expect(find.text('apple'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Deck finished!'), findsOneWidget);
    expect(find.text('Got it: 1 · Review again: 0 · Total: 1'), findsOneWidget);
  });
}

import 'package:material_ui/material_ui.dart';

import 'core/exam_store.dart';
import 'ui/flashcard_screen.dart';
import 'ui/home_screen.dart';
import 'ui/paste_sheet_screen.dart';
import 'ui/session_detail_screen.dart';
import 'ui/vocab_list_screen.dart';
import 'ui/vocab_review_screen.dart';

class StoreScope extends InheritedNotifier<ExamStore> {
  const StoreScope({super.key, required ExamStore store, required super.child})
      : super(notifier: store);

  static ExamStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    if (scope == null || scope.notifier == null) {
      throw FlutterError('StoreScope not found in widget tree');
    }
    return scope.notifier!;
  }
}

class KoreanLearningApp extends StatelessWidget {
  final ExamStore store;

  const KoreanLearningApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Korean Learning Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCD2E3A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCD2E3A),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        routes: {
          PasteSheetScreen.route: (context) => const PasteSheetScreen(),
          SessionDetailScreen.route: (context) => const SessionDetailScreen(),
          VocabListScreen.route: (context) => const VocabListScreen(),
          VocabReviewScreen.route: (context) => const VocabReviewScreen(),
          FlashcardScreen.route: (context) => const FlashcardScreen(),
        },
      ),
    );
  }
}

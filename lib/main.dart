import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/exam_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ExamStore();
  await store.load();
  runApp(KoreanLearningApp(store: store));
}

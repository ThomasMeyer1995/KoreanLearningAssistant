import '../models/exam_session.dart';
import '../models/vocab_item.dart';

/// Items shown for a session: every parsed item, or only the ones from
/// questions answered incorrectly. Duplicates by Korean term are merged.
List<VocabItem> sessionItems(ExamSession session, {required bool missedOnly}) {
  final items = missedOnly ? session.missedItems : session.allItems;
  return ExamSession.distinctByKorean(items);
}

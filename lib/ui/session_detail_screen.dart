import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../core/answer_sheet_parser.dart';
import '../core/item_lists.dart';
import '../models/vocab_item.dart';
import 'flashcard_screen.dart';
import 'vocab_list_screen.dart';
import 'vocab_review_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  static const String route = '/session';

  const SessionDetailScreen({super.key});

  Future<void> _showAddItemDialog(BuildContext context, String sessionId) async {
    final store = StoreScope.of(context);
    final korean = TextEditingController();
    final english = TextEditingController();
    final exampleKr = TextEditingController();
    final exampleEn = TextEditingController();
    var type = VocabType.vocabulary;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add vocabulary / grammar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<VocabType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: VocabType.vocabulary, child: Text('Vocabulary')),
                    DropdownMenuItem(value: VocabType.grammar, child: Text('Grammar')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? VocabType.vocabulary),
                ),
                TextField(
                  controller: korean,
                  decoration: const InputDecoration(labelText: 'Korean'),
                  autofocus: true,
                ),
                TextField(
                  controller: english,
                  decoration: const InputDecoration(labelText: 'English meaning'),
                ),
                TextField(
                  controller: exampleKr,
                  decoration: const InputDecoration(labelText: 'Example (Korean)'),
                ),
                TextField(
                  controller: exampleEn,
                  decoration: const InputDecoration(labelText: 'Example (English)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && korean.text.trim().isNotEmpty) {
      await store.addItemToSession(sessionId, VocabItem(
        id: newId(),
        korean: korean.text.trim(),
        english: english.text.trim(),
        type: type,
        exampleKr: exampleKr.text.trim(),
        exampleEn: exampleEn.text.trim(),
        section: 'Notes',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final sessionId = ModalRoute.of(context)?.settings.arguments as String;
    final session = store.findSession(sessionId);
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final missed = sessionItems(session, missedOnly: true);
    final all = sessionItems(session, missedOnly: false);

    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(session.scoreLabel,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
                  Text(
                    'Raw correct answers. Official TOPIK grades use a scaled curve, so treat this as a practice indicator.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 24),
                  for (final s in session.sectionScores) ...[
                    Row(
                      children: [
                        Expanded(child: Text(s.section)),
                        Text('${s.correct}/${s.total} (${s.percent.toStringAsFixed(0)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: s.percent / 100),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Vocabulary & grammar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pushNamed(
                  context, VocabListScreen.route,
                  arguments: {'sessionId': session.id, 'missedOnly': true},
                ),
                icon: const Icon(Icons.error_outline),
                label: Text('Missed (${missed.length})'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pushNamed(
                  context, VocabListScreen.route,
                  arguments: {'sessionId': session.id, 'missedOnly': false},
                ),
                icon: const Icon(Icons.list_alt),
                label: Text('All (${all.length})'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context, VocabReviewScreen.route,
                  arguments: {'sessionId': session.id, 'missedOnly': false, 'startIndex': 0},
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Review all'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context, VocabReviewScreen.route,
                  arguments: {'sessionId': session.id, 'missedOnly': true, 'startIndex': 0},
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Review missed'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context, FlashcardScreen.route,
                  arguments: {'sessionId': session.id, 'missedOnly': true},
                ),
                icon: const Icon(Icons.style_outlined),
                label: const Text('Flashcards: missed'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context, FlashcardScreen.route,
                  arguments: {'sessionId': session.id, 'missedOnly': false},
                ),
                icon: const Icon(Icons.style_outlined),
                label: const Text('Flashcards: all'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddItemDialog(context, session.id),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

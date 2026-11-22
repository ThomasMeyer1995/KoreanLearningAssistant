import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../core/item_lists.dart';
import '../models/vocab_item.dart';
import 'vocab_review_screen.dart';

class VocabListScreen extends StatefulWidget {
  static const String route = '/vocab-list';

  const VocabListScreen({super.key});

  @override
  State<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends State<VocabListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final session = store.findSession(args['sessionId'] as String);
    final missedOnly = args['missedOnly'] as bool? ?? false;
    if (session == null) {
      return const Scaffold(body: Center(child: Text('Exam not found')));
    }

    final all = sessionItems(session, missedOnly: missedOnly);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? all
        : all
            .where((i) =>
                i.korean.toLowerCase().contains(query) ||
                i.english.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(missedOnly ? 'Missed vocabulary' : 'All vocabulary'),
        actions: [
          IconButton(
            tooltip: 'Review with examples',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              VocabReviewScreen.route,
              arguments: {
                'sessionId': session.id,
                'missedOnly': missedOnly,
                'startIndex': 0,
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search Korean or English...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(missedOnly
                        ? 'No missed items. Nice!'
                        : 'No items yet. Paste an answer sheet or add items manually.'),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      return _ItemTile(
                        item: item,
                        onTap: () => Navigator.pushNamed(
                          context,
                          VocabReviewScreen.route,
                          arguments: {
                            'sessionId': session.id,
                            'missedOnly': missedOnly,
                            'startIndex': all.indexWhere((e) => e.id == item.id),
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final VocabItem item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final source = item.questionNumber > 0
        ? '${item.section} · Q${item.questionNumber}'
        : (item.section.isNotEmpty ? item.section : 'Note');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.type == VocabType.grammar
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          item.type == VocabType.grammar ? Icons.functions : Icons.translate,
          color: item.type == VocabType.grammar
              ? Theme.of(context).colorScheme.onSecondaryContainer
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(item.korean, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${item.english.isNotEmpty ? item.english : item.typeLabel} · $source'
        '${item.knownCount > 0 ? ' · known ×${item.knownCount}' : ''}',
      ),
      trailing: item.missed
          ? Chip(
              label: const Text('missed'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              visualDensity: VisualDensity.compact,
            )
          : null,
      onTap: onTap,
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../core/item_lists.dart';
import '../models/vocab_item.dart';

class VocabReviewScreen extends StatefulWidget {
  static const String route = '/review';

  const VocabReviewScreen({super.key});

  @override
  State<VocabReviewScreen> createState() => _VocabReviewScreenState();
}

class _VocabReviewScreenState extends State<VocabReviewScreen> {
  late final PageController _pageController;
  int _index = 0;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _index = (args['startIndex'] as int?) ?? 0;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    final items = sessionItems(session, missedOnly: missedOnly);
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const Center(child: Text('Nothing to review yet.')),
      );
    }
    if (_index >= items.length) _index = items.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(missedOnly ? 'Review: missed' : 'Review: all'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) => _ReviewCard(item: items[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _index > 0
                      ? () => _pageController.animateToPage(_index - 1,
                          duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_index + 1} / ${items.length}'),
                IconButton(
                  onPressed: _index < items.length - 1
                      ? () => _pageController.animateToPage(_index + 1,
                          duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final VocabItem item;

  const _ReviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = item.questionNumber > 0
        ? '${item.section} · Question ${item.questionNumber}'
        : (item.section.isNotEmpty ? item.section : 'Note');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(item.typeLabel),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  if (item.missed)
                    Chip(
                      label: const Text('missed'),
                      backgroundColor: theme.colorScheme.errorContainer,
                      labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(item.korean,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(item.english.isNotEmpty ? item.english : '—',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      )),
              const Spacer(),
              if (item.hasExample) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text('Example', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                if (item.exampleKr.isNotEmpty)
                  Text(item.exampleKr,
                      style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                if (item.exampleEn.isNotEmpty)
                  Text(item.exampleEn, style: theme.textTheme.bodyMedium),
              ],
              const Spacer(),
              Text('$source · known ×${item.knownCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

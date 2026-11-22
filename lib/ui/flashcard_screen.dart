import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../core/item_lists.dart';
import '../models/vocab_item.dart';

class FlashcardScreen extends StatefulWidget {
  static const String route = '/flashcards';

  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late List<VocabItem> _deck;
  late int _total;
  late AnimationController _flipController;
  bool _showBack = false;
  bool _ready = false;
  int _gotIt = 0;
  int _again = 0;
  String? _sessionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _sessionId = args['sessionId'] as String;
    final missedOnly = args['missedOnly'] as bool? ?? false;
    final store = StoreScope.of(context);
    final session = store.findSession(_sessionId!);
    final items = session == null
        ? <VocabItem>[]
        : sessionItems(session, missedOnly: missedOnly);
    _deck = [...items];
    _deck.shuffle(Random());
    _total = _deck.length;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipController.isAnimating) return;
    if (_showBack) {
      _flipController.reverse().then((_) {
        if (mounted) setState(() => _showBack = false);
      });
    } else {
      _flipController.forward().then((_) {
        if (mounted) setState(() => _showBack = true);
      });
    }
  }

  void _shuffle() {
    setState(() {
      _deck.shuffle(Random());
      _flipController.reset();
      _showBack = false;
    });
  }

  Future<void> _answer({required bool known}) async {
    if (_deck.isEmpty) return;
    final item = _deck.first;
    setState(() {
      if (known) {
        _gotIt++;
        _deck = _deck.sublist(1);
      } else {
        _again++;
        _deck = [..._deck.sublist(1), item];
      }
      _flipController.reset();
      _showBack = false;
    });
    if (known && _sessionId != null) {
      await StoreScope.of(context).markItemKnown(_sessionId!, item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final missedOnly = args['missedOnly'] as bool? ?? false;
    final remaining = _deck.length;
    final done = _total == 0 ? 1.0 : 1 - remaining / _total;

    return Scaffold(
      appBar: AppBar(
        title: Text(missedOnly ? 'Flashcards: missed' : 'Flashcards: all'),
        actions: [
          IconButton(
            tooltip: 'Shuffle',
            icon: const Icon(Icons.shuffle),
            onPressed: _deck.length > 1 ? _shuffle : null,
          ),
        ],
      ),
      body: remaining == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Deck finished!', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Got it: $_gotIt · Review again: $_again · Total: $_total'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to exam'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text('Remaining: $remaining / $_total'),
                      const Spacer(),
                      Text('Got it: $_gotIt · Again: $_again'),
                    ],
                  ),
                ),
                LinearProgressIndicator(value: done),
                Expanded(
                  child: GestureDetector(
                    onTap: _flip,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedBuilder(
                        animation: _flipController,
                        builder: (context, child) {
                          final angle = _flipController.value * pi;
                          final showBack = _flipController.value >= 0.5;
                          final card = showBack
                              ? _CardFace(item: _deck.first, back: true)
                              : _CardFace(item: _deck.first, back: false);
                          return Transform.rotate(
                            angle: angle,
                            child: showBack
                                ? Transform.rotate(angle: pi, child: card)
                                : card,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _answer(known: false),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _answer(known: true),
                          icon: const Icon(Icons.check),
                          label: const Text('Got it'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Tap the card to flip',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final VocabItem item;
  final bool back;

  const _CardFace({required this.item, required this.back});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!back)
              Chip(
                label: Text(item.typeLabel),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(height: 16),
            Text(
              back ? (item.english.isNotEmpty ? item.english : item.korean) : item.korean,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (back && item.hasExample) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              if (item.exampleKr.isNotEmpty)
                Text(item.exampleKr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
              if (item.exampleEn.isNotEmpty)
                Text(item.exampleEn,
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ],
            if (!back)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('English on the other side',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        )),
              ),
          ],
        ),
      ),
    );
  }
}

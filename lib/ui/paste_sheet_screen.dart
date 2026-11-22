import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/answer_sheet_parser.dart';
import 'session_detail_screen.dart';

const String formatHelp = '''Answer sheet format (one entry per line):

# Exam title                <- sets the exam name
## Listening                <- starts a section (Listening / Reading / ...)
1. 3 -> 4 | 사과 (apple) | 예: 사과를 먹어요. (I eat an apple.)
2. ② -> ② | 문법: -아요 (polite ending) | 예: 커피를 마셔요. (I drink coffee.)

Rules:
- "N. my -> correct" is one question. Digits, circled digits (①-⑩) and "3번" all work.
- A question is correct when both sides match after normalizing.
- After the correct answer, add "|"-separated notes:
  - "사과 (apple)" or "vocab: 사과 (apple)" -> vocabulary item
  - "grammar: -ayo (ending)" or "문법: ..." -> grammar item
  - "예: 문장 (translation)" or "ex: ..." -> example sentence for the previous item
- A line without a number is treated as a free vocabulary/grammar note.''';

class PasteSheetScreen extends StatefulWidget {
  static const String route = '/paste';

  const PasteSheetScreen({super.key});

  @override
  State<PasteSheetScreen> createState() => _PasteSheetScreenState();
}

class _PasteSheetScreenState extends State<PasteSheetScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSample() async {
    final text = await rootBundle.loadString('assets/sample_answer_sheet.txt');
    setState(() {
      _controller.text = text;
    });
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer sheet format'),
        content: SingleChildScrollView(
          child: SelectableText(formatHelp,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _parseAndSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your answer sheet first.')),
      );
      return;
    }
    setState(() => _busy = true);
    final session = AnswerSheetParser.parse(text);
    final store = StoreScope.of(context);
    if (session.questions.isEmpty) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find any questions. Check the format (see Help).')),
        );
      }
      return;
    }
    await store.addSession(session);
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        SessionDetailScreen.route,
        arguments: session.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New answer sheet'),
        actions: [
          IconButton(
            tooltip: 'Format help',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Paste your annotated answer sheet here...\n\n'
                      '# TOPIK II 83회\n'
                      '## Listening\n'
                      '1. 3 -> 4 | 사과 (apple) | 예: 사과를 먹어요. (I eat an apple.)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _loadSample,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Load sample'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _busy ? null : _parseAndSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Parse & save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

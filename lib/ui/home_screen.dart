import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../core/exam_store.dart';
import 'paste_sheet_screen.dart';
import 'session_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> _export(BuildContext context, ExamStore store) async {
    try {
      final file = await store.exportToFile();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, ExamStore store) async {
    try {
      final count = await store.importFromPicker();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count == 0
                ? 'No new sessions imported (nothing selected or all already known).'
                : 'Imported $count session(s).'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, ExamStore store, String id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exam?'),
        content: Text('"$title" and all its vocabulary will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await store.deleteSession(id);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final sessions = store.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Korean Learning Assistant'),
        actions: [
          IconButton(
            tooltip: 'Export all data (JSON)',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _export(context, store),
          ),
          IconButton(
            tooltip: 'Import data (JSON)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _import(context, store),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Paste an annotated TOPIK answer sheet to get your score, your missed vocabulary, and flashcards.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, PasteSheetScreen.route),
                      icon: const Icon(Icons.content_paste),
                      label: const Text('Paste an answer sheet'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final missedCount = session.missedItems.length;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(session.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${_formatDate(session.createdAt)}  ·  Score ${session.scoreLabel}  ·  $missedCount missed item(s)',
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      SessionDetailScreen.route,
                      arguments: session.id,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, store, session.id, session.title),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, PasteSheetScreen.route),
        icon: const Icon(Icons.content_paste),
        label: const Text('Paste answer sheet'),
      ),
    );
  }
}

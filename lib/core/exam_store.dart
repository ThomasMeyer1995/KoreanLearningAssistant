import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_session.dart';
import '../models/question_result.dart';
import '../models/vocab_item.dart';

class ExamStore extends ChangeNotifier {
  static const String storageKey = 'korean_learning_assistant.sessions.v1';
  static const int exportVersion = 1;

  final List<ExamSession> _sessions = [];

  List<ExamSession> get sessions => List.unmodifiable(_sessions);

  ExamSession? findSession(String id) {
    for (final s in _sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    _sessions.clear();
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _sessions.addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(ExamSession.fromJson),
        );
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(_sessions.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> addSession(ExamSession session) async {
    _sessions.insert(0, session);
    await _persist();
    notifyListeners();
  }

  Future<void> updateSession(ExamSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> markItemKnown(String sessionId, String itemId) async {
    final session = findSession(sessionId);
    if (session == null) return;
    for (final q in session.questions) {
      for (final item in q.items) {
        if (item.id == itemId) {
          await updateSession(
            session.withItemReplaced(item.copyWith(knownCount: item.knownCount + 1)),
          );
          return;
        }
      }
    }
  }

  Future<void> addItemToSession(String sessionId, VocabItem item) async {
    final session = findSession(sessionId);
    if (session == null) return;
    if (session.questions.isEmpty) {
      await updateSession(session.copyWith(questions: [
        QuestionResult(
          number: 0,
          section: 'Notes',
          myAnswer: '',
          correctAnswer: '',
          isCorrect: true,
          items: [item],
        ),
      ]));
      return;
    }
    final first = session.questions.first;
    await updateSession(session.copyWith(questions: [
      first.copyWith(items: [...first.items, item]),
      ...session.questions.skip(1),
    ]));
  }

  String exportJson() {
    return jsonEncode({
      'app': 'korean_learning_assistant',
      'exportVersion': exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
    });
  }

  Future<File> exportToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}korean_learning_assistant_export.json',
    );
    await file.writeAsString(exportJson(), flush: true);
    return file;
  }

  /// Returns the number of sessions imported.
  Future<int> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not a Korean Learning Assistant export file.');
    }
    final list = decoded['sessions'];
    if (list is! List) {
      throw const FormatException('Export file has no "sessions" list.');
    }
    var added = 0;
    for (final entry in list.whereType<Map<String, dynamic>>()) {
      final session = ExamSession.fromJson(entry);
      if (_sessions.any((s) => s.id == session.id)) continue;
      _sessions.add(session);
      added++;
    }
    if (added > 0) {
      await _persist();
      notifyListeners();
    }
    return added;
  }

  Future<int> importFromPicker() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return 0;
    return importJson(await File(path).readAsString());
  }
}

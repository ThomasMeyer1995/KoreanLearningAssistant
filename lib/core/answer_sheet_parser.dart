import 'dart:math';

import '../models/exam_session.dart';
import '../models/question_result.dart';
import '../models/vocab_item.dart';

final _idRandom = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${_idRandom.nextInt(1 << 30)}';

/// Parses an annotated TOPIK answer sheet pasted as plain text.
///
/// Format (one entry per line):
///   # Exam title
///   ## Section name            (e.g. ## Listening, ## Reading)
///   1. 3 -> 4 | 사과 (apple) | 예: 사과를 먹어요. (I eat an apple.)
///
/// - `# ...` sets the exam title, `## ...` starts a new section.
/// - `N. my -> correct` is a question; answers may be digits, circled
///   digits (①..⑩) or `3번`. The question is correct when both sides match.
/// - After the correct answer, `|`-separated annotations add learning items:
///   - `사과 (apple)` or `vocab: 사과 (apple)` -> vocabulary item
///   - `grammar: -아요 (polite present)` or `문법: ...` -> grammar item
///   - `예: 문장 (translation)` / `ex: ...` -> example for the previous item
/// - A numbered line without `->` counts as incorrect and its text is
///   still parsed for annotations.
/// - A line without a number is treated as a free vocabulary/grammar note.
class AnswerSheetParser {
  static const Map<String, String> _circled = {
    '①': '1',
    '②': '2',
    '③': '3',
    '④': '4',
    '⑤': '5',
    '⑥': '6',
    '⑦': '7',
    '⑧': '8',
    '⑨': '9',
    '⑩': '10',
  };

  static final RegExp _questionLine = RegExp(r'^(\d+)\s*[.)\-:]\s*(.*)$');
  static final RegExp _arrow = RegExp(r'->|=>|→');

  static String normalizeAnswer(String raw) {
    var s = raw.trim().toLowerCase();
    for (final entry in _circled.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    s = s.replaceAll('번', '');
    s = s.replaceAll(RegExp(r'[^0-9a-z가-힣\-]'), '');
    return s;
  }

  static ExamSession parse(String text, {String? fallbackTitle}) {
    var title = (fallbackTitle ?? '').trim();
    var section = 'General';
    final questions = <QuestionResult>[];

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('##')) {
        final name = line.replaceFirst(RegExp(r'^#+\s*'), '');
        if (name.isNotEmpty) section = name;
        continue;
      }
      if (line.startsWith('#')) {
        final name = line.replaceFirst(RegExp(r'^#+\s*'), '');
        if (name.isNotEmpty) title = name;
        continue;
      }

      final match = _questionLine.firstMatch(line);
      if (match != null) {
        final number = int.parse(match.group(1)!);
        final rest = match.group(2)!.trim();
        final arrowIndex = _arrow.firstMatch(rest);
        String myRaw;
        String correctSide;
        if (arrowIndex != null) {
          myRaw = rest.substring(0, arrowIndex.start);
          correctSide = rest.substring(arrowIndex.end);
        } else {
          myRaw = '';
          correctSide = rest;
        }
        final parts = correctSide.split('|');
        final my = normalizeAnswer(myRaw);
        final correct = normalizeAnswer(parts.first);
        final isCorrect = my.isNotEmpty && correct.isNotEmpty && my == correct;
        final items = _parseAnnotations(
          parts.sublist(1),
          section: section,
          questionNumber: number,
          missed: !isCorrect,
        );
        questions.add(QuestionResult(
          number: number,
          section: section,
          myAnswer: my,
          correctAnswer: correct,
          isCorrect: isCorrect,
          items: items,
        ));
        continue;
      }

      final items = _parseAnnotations(
        line.split('|'),
        section: section,
        questionNumber: 0,
        missed: false,
      );
      if (items.isNotEmpty) {
        questions.add(QuestionResult(
          number: 0,
          section: section,
          myAnswer: '',
          correctAnswer: '',
          isCorrect: true,
          items: items,
        ));
      }
    }

    return ExamSession(
      id: newId(),
      title: title.isEmpty ? 'Untitled exam' : title,
      createdAt: DateTime.now(),
      questions: questions,
    );
  }

  static List<VocabItem> _parseAnnotations(
    List<String> parts, {
    required String section,
    required int questionNumber,
    required bool missed,
  }) {
    final items = <VocabItem>[];
    String? pendingExampleKr;
    String? pendingExampleEn;

    void attachExample(String kr, String en) {
      if (items.isNotEmpty) {
        final last = items.last;
        items[items.length - 1] = last.copyWith(exampleKr: kr, exampleEn: en);
      } else {
        pendingExampleKr = kr;
        pendingExampleEn = en;
      }
    }

    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      final lower = part.toLowerCase();

      final examplePrefix = _firstPrefix(lower, const ['ex:', '예:', '예문:', 'example:']);
      if (examplePrefix != null) {
        final body = part.substring(examplePrefix.length);
        final parsed = _splitExample(body);
        attachExample(parsed.$1, parsed.$2);
        continue;
      }

      var type = VocabType.vocabulary;
      var body = part;
      final grammarPrefix = _firstPrefix(lower, const ['grammar:', '문법:']);
      final vocabPrefix = _firstPrefix(lower, const ['vocab:', '단어:', 'v:']);
      if (grammarPrefix != null) {
        type = VocabType.grammar;
        body = part.substring(grammarPrefix.length);
      } else if (vocabPrefix != null) {
        body = part.substring(vocabPrefix.length);
      }

      final parsed = _splitTerm(body);
      items.add(VocabItem(
        id: newId(),
        korean: parsed.$1,
        english: parsed.$2,
        type: type,
        exampleKr: pendingExampleKr ?? '',
        exampleEn: pendingExampleEn ?? '',
        questionNumber: questionNumber,
        section: section,
        missed: missed,
      ));
      pendingExampleKr = null;
      pendingExampleEn = null;
    }

    return items;
  }

  static String? _firstPrefix(String lower, List<String> prefixes) {
    for (final p in prefixes) {
      if (lower.startsWith(p)) return p;
    }
    return null;
  }

  static (String, String) _splitExample(String body) {
    final paren = body.indexOf('(');
    if (paren >= 0) {
      final kr = body.substring(0, paren).trim();
      var en = body.substring(paren + 1).trim();
      if (en.endsWith(')')) en = en.substring(0, en.length - 1).trim();
      return (kr, en);
    }
    return (body.trim(), '');
  }

  static (String, String) _splitTerm(String body) {
    final trimmed = body.trim();
    final paren = trimmed.indexOf('(');
    if (paren >= 0) {
      final kr = trimmed.substring(0, paren).trim();
      var en = trimmed.substring(paren + 1).trim();
      if (en.endsWith(')')) en = en.substring(0, en.length - 1).trim();
      if (kr.isNotEmpty) return (kr, en);
    }
    final eq = trimmed.indexOf('=');
    if (eq > 0) {
      return (trimmed.substring(0, eq).trim(), trimmed.substring(eq + 1).trim());
    }
    final dash = trimmed.indexOf(RegExp(r'\s[-–—]\s'));
    if (dash > 0) {
      return (trimmed.substring(0, dash).trim(), trimmed.substring(dash + 1).trim());
    }
    return (trimmed, '');
  }
}

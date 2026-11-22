# Korean Learning Assistant

A cross-platform (Windows PC + Android phone) app to practice Korean for TOPIK exams.

Paste an annotated answer sheet for a TOPIK exam and the app will:

1. **Score the exam** — correct/total per section and overall (raw score + %; official
   TOPIK grades use a scaled curve, so treat this as a practice indicator).
2. **Extract key vocabulary/grammar** into two lists:
   - the points you **missed** (from wrong answers),
   - **all** key points from the sheet.
3. **Review** each point in detail, with an example sentence for every item.
4. **Drill flashcards** — Korean word/grammar on one side, English on the other
   (tap to flip, "Again" / "Got it", shuffle).

Everything is stored locally on the device (no account needed). Use **Export** /
**Import** (JSON) from the home screen to move your data between your PC and your phone.

## Answer sheet format

Paste plain text, one entry per line:

```
# TOPIK II 83rd mock exam        <- exam title
## Listening                     <- section (Listening / Reading / ...)
1. 3 -> 4 | 사과 (apple) | 예: 사과를 먹어요. (I eat an apple.)
2. ② -> ② | 문법: -아요 (polite ending) | 예: 커피를 마셔요. (I drink coffee.)
## Reading
3. 1 -> 3 | vocab: 금방 (soon)
```

- `N. my -> correct` is one question. Answers can be digits, circled digits (①–⑩)
  or `3번`. A question is correct when both sides match.
- After the correct answer, `|`-separated notes add learning items:
  - `사과 (apple)` or `vocab: 사과 (apple)` / `단어: ...` → vocabulary item
  - `grammar: -아요 (...)` / `문법: ...` → grammar item
  - `예: 문장 (translation)` / `예문:` / `ex: ...` → example for the previous item
- A line without a number is a free vocabulary/grammar note (not scored).

A ready-to-try example is bundled: in the app, tap **Load sample** on the paste screen
(see `assets/sample_answer_sheet.txt`).

## Run

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable).

```bash
flutter pub get

# Windows desktop
flutter run -d windows
flutter build windows        # produces build\windows\x64\runner\Release\*.exe

# Android (phone connected with USB debugging, or an emulator)
flutter run -d android
flutter build apk            # produces build/app/outputs/flutter-apk/app-release.apk
```

## Test & analyze

```bash
flutter analyze
flutter test
```

## Project layout

```
lib/
  main.dart                  app entry point
  app.dart                   theme, routes, StoreScope
  models/                    ExamSession, QuestionResult, VocabItem (+ JSON)
  core/
    answer_sheet_parser.dart pure-Dart parser for the answer-sheet format
    exam_store.dart          local persistence (shared_preferences), export/import
    item_lists.dart          missed/all item derivation
  ui/                        home, paste, session detail, vocab list, review, flashcards
test/                        unit tests for parser, scoring, store
assets/sample_answer_sheet.txt
```

## Roadmap ideas

- Cloud sync between PC and phone instead of manual JSON export/import
- Approximate TOPIK level estimate from the raw score
- Spaced-repetition scheduling for flashcards

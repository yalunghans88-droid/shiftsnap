# AI usage

This project was built with AI assistance. This file is the record of it. It is
graded as the finals badge, and it is worth 100 points.

Start it in week 1 and keep it up as you go. The commit history of this file is
part of the evidence: a file written all at once the night before the deadline
looks exactly like what it is.

## 1. How I used AI

### 2026-09-23 - Setting up the Flutter project and resolving dependency conflicts

- **Tool:** Claude (Anthropic)
- **What I asked for:** Help resolving a dependency conflict between `hive_generator` and `riverpod_generator` that was blocking `flutter pub get` entirely.
- **What it gave back:** Suggested switching from the abandoned `hive` package to the community fork `hive_ce` and `hive_ce_generator`, upgrading `custom_lint` to `^0.8.1`, and moving to Riverpod 3.0.
- **What I kept, what I changed, and why:** I kept the `hive_ce` switch — it unblocked the resolver. I changed the migration order: the suggestion was to do Riverpod 3.0 and the Hive swap in one go, but I did the Hive swap first so I could isolate which change fixed what.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-09-24 - Designing the Hive data models

- **Tool:** Claude (Anthropic)
- **What I asked for:** A Hive schema for three entities — `Shift`, `ScannedRoster`, `UserPreferences`.
- **What it gave back:** Draft model classes with `@HiveType` annotations and suggested `typeId` values (1, 2, 3). It proposed storing times as strings in `"HH:mm"` format and adding computed getters `startDateTime` and `endDateTime` for sorting and countdowns.
- **What I kept, what I changed, and why:** I kept the string-times approach — it matches what Gemini returns and avoids timezone drift. I added the `confirmed` boolean myself so extracted-but-unreviewed shifts could be distinguished from saved ones.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-09-27 - Building the Gemini extraction service

- **Tool:** Claude (Anthropic) + Google Gemini API docs
- **What I asked for:** A service that takes a roster photo, sends it to Gemini, and returns structured shifts as Dart objects.
- **What it gave back:** A draft `GeminiService` using `google_generative_ai` and `gemini-2.0-flash`, with a JSON-only prompt and a `RosterExtractionResult` wrapper. It also suggested setting `responseMimeType: 'application/json'` on the generation config.
- **What I kept, what I changed, and why:** I kept the typed result wrapper — it made error handling in the UI much cleaner. I significantly rewrote the prompt to add rules for midnight-spanning shifts, missing years, and unreadable rows. I wrote the `_normaliseTime` helper myself.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-09-28 - Migrating from Riverpod 2 to Riverpod 3

- **Tool:** Claude (Anthropic)
- **What I asked for:** Help fixing `StateNotifier` errors after the upgrade to Riverpod 3.0.
- **What it gave back:** Explained that `StateNotifier` and `StateNotifierProvider` moved out of the main package in Riverpod 3.0 and suggested migrating to `Notifier` and `NotifierProvider`.
- **What I kept, what I changed, and why:** I kept the `Notifier` migration and restructured `RosterNotifier` so the initial state lives in `build()` rather than a constructor — that's the new API shape.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-10-04 - Building the manual shift entry feature

- **Tool:** Claude (Anthropic)
- **What I asked for:** A permanent way to add a shift without using the camera, for users who prefer manual entry or when Gemini misses a shift. I made this decision myself after realising the camera-only flow was fragile.
- **What it gave back:** A Column of two FABs (amber "add" above the navy camera) plus an `_addShiftManually` method that opens the edit modal and writes directly to Hive.
- **What I kept, what I changed, and why:** I kept the two-FAB layout. I changed the original draft — which had the button trigger a test-only route — into a real user-facing feature with a "Shift added" snackbar and `confirmed: true` flag. I also made it save directly to Hive instead of the roster state.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/fa75df1

### 2026-10-09 - Diagnosing the shift reactivity bug on Android and web

- **Tool:** Claude (Anthropic)
- **What I asked for:** Help diagnosing why shifts saved from the camera flow weren't appearing on the Home screen, even though they were being written to Hive.
- **What it gave back:** A diagnosis that `box.watch()` doesn't reliably emit on Android in Hive CE. It suggested a manual version-bump pattern: a `shiftsVersionProvider` that gets incremented after every write, forcing all watching providers to recompute.
- **What I kept, what I changed, and why:** I kept the version-bump pattern and the `_forceFutureYear` safety net it suggested for the Gemini year-guessing bug. I rewrote the provider file to use a broadcast `StreamController` because the first version returned a typed `Provider` where the widgets expected a `StreamProvider` — a type mismatch the compiler caught.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/d91bd15

## 2. Where the AI got it wrong

### Case 1 - `FontWeight.regular` does not exist in Flutter

- **What it gave me:** A `TextStyle` using `fontWeight: FontWeight.regular`.
- **What was wrong with it:** Flutter's `FontWeight` enum has no `regular` member. The valid values are `w100` through `w900`, plus the named constants `normal` and `bold`. The error was only caught at compile time.
- **What I did instead:** Replaced `FontWeight.regular` with `FontWeight.normal` in both the body and caption styles.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### Case 2 - Device Preview 3.0.0 API change

- **What it gave me:** Instructions to wrap `MaterialApp` in `DevicePreview` with an `enabled:` parameter, and to call `DevicePreview.locale(context)` and `DevicePreview.appBuilder`.
- **What was wrong with it:** Device Preview 3.0.0 completely reworked its API. The `enabled:` parameter and both static helpers are gone. Additionally, calling `WidgetsFlutterBinding.ensureInitialized()` before `DevicePreview.enable()` triggers a runtime binding conflict assertion that crashes the app with a white screen.
- **What I did instead:** Removed the wrapper, removed `WidgetsFlutterBinding.ensureInitialized()`, and called `DevicePreview.enable(enabled: !kReleaseMode)` as the first statement in `main()`.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### Case 3 - Gemini returned shifts with past dates

- **What it gave me:** Extracted shifts with years of 2023, 2024, and 2025, even though the current year is 2026. The prompt said "if the year is not shown, assume the current year" but Gemini ignored it.
- **What was wrong with it:** The instruction was too weak. Gemini guessed years that put most shifts in the past, so the Home screen's `findNextShift` filter (which only shows future shifts) hid them. The user saw an empty home screen even though the data was correctly saved.
- **What I did instead:** I strengthened the prompt to include the actual current date and strict rules about never outputting a year earlier than the current one. I also added a `_forceFutureYear` safety net in the Dart parsing code that advances any past-dated shift forward year by year until it's in the future. This means the app is correct even if Gemini still guesses wrong.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/d91bd15

## 3. Who wrote what

At least a fifth of this project is code you wrote yourself. Name it, and explain
it in your own words.

### Written by me

- **File:** `lib/providers/shift_provider.dart`
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/d91bd15
- **What it does and why it is built this way:** This file defines how the app tracks shifts. `allShiftsProvider` is a `StreamProvider` that reads from the Hive box and re-emits whenever the `shiftsVersionProvider` gets bumped. `findNextShift` walks the sorted list and returns the first shift whose end time is still in the future — that's what powers the hero card. `findUpcoming` filters out that same shift so the list below doesn't duplicate it. I also wrote `formatCountdown`, which returns "in X minutes", "in X hours", or "in X days" depending on how far away the shift is. Building it this way means Home rebuilds automatically whenever a shift is added, edited, or deleted — no manual refresh logic anywhere.

### The AI-written part I understand best

- **File:** `lib/services/gemini_service.dart`
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/d91bd15
- **What it does and why we kept it:** Sends a roster photo to `gemini-3.8-flash` with a strict JSON-only prompt, then parses the response back into `Shift` objects. The reason we kept it in this shape is the `RosterExtractionResult` wrapper — instead of throwing exceptions on failure, it returns either `{ shifts }` or `{ error }`. That one design choice means the Camera screen can call `extractFromImage()` and then just check `result.success` before navigating, without any try/catch clutter. The `_forceFutureYear` helper was added later when we discovered Gemini was returning past-dated shifts, and it quietly corrects them without the user ever knowing.
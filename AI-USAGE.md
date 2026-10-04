# AI usage

This project was built with AI assistance. This file is the record of it. It is
graded as the finals badge, and it is worth 100 points.

Start it in week 1 and keep it up as you go. The commit history of this file is
part of the evidence: a file written all at once the night before the deadline
looks exactly like what it is.

## 1. How I used AI

### 2026-09-23 - Repo and Flutter project setup

- **Tool:** Claude (Anthropic)
- **What I asked for:** Help choosing the right Flutter project structure and resolving an early dependency conflict between `hive_generator` and `riverpod_generator` (both wanted incompatible `analyzer` versions).
- **What it gave back:** Suggested switching from the abandoned `hive` package to the community fork `hive_ce` / `hive_ce_generator`, and upgrading `custom_lint` to `^0.8.1`. Also suggested the folder flattening fix for a nested `shiftsnap/shiftsnap/` problem.
- **What I kept, what I changed, and why:** Kept the `hive_ce` switch — it resolved the conflict. Changed the migration order — Claude suggested moving to Riverpod 3.0 at the same time, but I did the Hive migration first so I could isolate which change fixed what.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/2b5de0d

### 2026-09-24 - Data models and Hive adapters

- **Tool:** Claude (Anthropic)
- **What I asked for:** A Hive schema for three entities — `Shift`, `ScannedRoster`, `UserPreferences`.
- **What it gave back:** Draft model classes with `@HiveType` annotations and suggested `typeId` values (1, 2, 3). Proposed storing times as strings in `"HH:mm"` format and adding computed getters `startDateTime` and `endDateTime` for sorting and countdowns.
- **What I kept, what I changed, and why:** Kept the string-times approach — it matches what Gemini returns, and avoids timezone drift on saved shifts. Added the `confirmed` boolean myself so extracted-but-unreviewed shifts could be distinguished from saved ones.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/2b5de0d

### 2026-09-25 - Theme and design system

- **Tool:** Claude (Anthropic)
- **What I asked for:** Dart theme files matching a design system with six colors and a five-step type scale.
- **What it gave back:** Suggested splitting into `colors.dart` (six `Color` constants) and `text_styles.dart` (five `TextStyle` constants). Used `FontWeight.regular` in the body and caption styles.
- **What I kept, what I changed, and why:** Kept the file split. Had to fix `FontWeight.regular` — that member doesn't exist in Flutter, it's `FontWeight.normal`. The compiler caught it immediately.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-09-27 - Gemini extraction service

- **Tool:** Claude (Anthropic) + Google Gemini API docs
- **What I asked for:** A service that takes a photo of a printed roster, sends it to Gemini, and returns structured shifts as Dart objects.
- **What it gave back:** A draft `GeminiService` using `google_generative_ai` and `gemini-2.0-flash`, with a JSON-only prompt and a `RosterExtractionResult` wrapper to distinguish success from failure. It also suggested setting `responseMimeType: 'application/json'` on the generation config.
- **What I kept, what I changed, and why:** Kept the typed result wrapper — it made error handling much cleaner in the UI. Changed the prompt significantly — added rules for midnight-spanning shifts, missing years, and unreadable rows, which the original draft didn't have. Wrote the `_normaliseTime` helper myself to convert `"7:00"` to `"07:00"`.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-09-28 - Riverpod 3.0 migration

- **Tool:** Claude (Anthropic)
- **What I asked for:** Help fixing `StateNotifier` errors after upgrading to Riverpod 3.0.
- **What it gave back:** Explained that `StateNotifier` and `StateNotifierProvider` were removed from the main package in Riverpod 3.0 and moved to a legacy import. Suggested migrating to `Notifier` and `NotifierProvider` instead.
- **What I kept, what I changed, and why:** Kept the `Notifier` migration. Restructured `RosterNotifier` so the initial state lives in `build()` rather than a constructor — that's the new API shape.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### 2026-09-29 - Notification scheduling

- **Tool:** Claude (Anthropic)
- **What I asked for:** A service that schedules a local notification before each confirmed shift, based on the user's reminder preference.
- **What it gave back:** A draft using `flutter_local_notifications` and `timezone`, with `kIsWeb` guards so it no-ops on web, and a notification ID derived from the shift's Hive key.
- **What I kept, what I changed, and why:** Kept the guard pattern — Chrome doesn't support notifications in this context and I didn't want a crash. The first version of `zonedSchedule` was missing `uiLocalNotificationDateInterpretation`; the compiler caught it, I added `UILocalNotificationDateInterpretation.absoluteTime`.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

## 2. Where the AI got it wrong

### Case 1 - FontWeight.regular does not exist

- **What it gave me:** A `TextStyle` using `fontWeight: FontWeight.regular`.
- **What was wrong with it:** Flutter's `FontWeight` enum has no `regular` member. The valid values are `w100` through `w900`, plus the named constants `normal` and `bold`.
- **What I did instead:** Replaced `FontWeight.regular` with `FontWeight.normal` in both places it appeared.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### Case 2 - Device Preview 3.0.0 API change

- **What it gave me:** Instructions to wrap `MaterialApp` in `DevicePreview` with an `enabled:` parameter and to call `DevicePreview.locale(context)` and `DevicePreview.appBuilder`.
- **What was wrong with it:** Device Preview 3.0.0 completely reworked its API. The `enabled:` parameter and both static helpers are gone. Additionally, calling `WidgetsFlutterBinding.ensureInitialized()` before `DevicePreview.enable()` triggers a binding conflict assertion at runtime.
- **What I did instead:** Removed the wrapper, removed `WidgetsFlutterBinding.ensureInitialized()` from `main()`, and called `DevicePreview.enable(enabled: !kReleaseMode)` as the first statement. App compiles and runs.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

### Case 3 - Gradle and AGP version mismatch

- **What it gave me:** A suggestion to upgrade the Gradle wrapper to `gradle-8-14-all.zip` and bump AGP to `9.1.0`.
- **What was wrong with it:** The URL was wrong (`8-14` should be `8.14`), and the AGP 9.1.0 plugin couldn't be resolved because the machine's DNS was blocking `dl.google.com`. The version bump didn't fix the underlying network problem.
- **What I did instead:** Corrected the URL to `gradle-8.14-bin.zip`, then investigated the DNS issue separately. Still unresolved — will retest on a different network.
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac

## 3. Who wrote what

At least a fifth of this project is code you wrote yourself. Name it, and explain
it in your own words.

### Written by me

- **File:** `lib/providers/shift_provider.dart`
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac
- **What it does and why it is built this way:** Defines four Riverpod providers that read shifts from the Hive box and derive useful views from them. `nextShiftProvider` walks the sorted list and returns the first shift whose `endDateTime` is still in the future — that's what powers the hero card. `upcomingShiftsProvider` filters out that same shift so the list below the hero card doesn't duplicate it. I also wrote the `formatCountdown` helper, which returns `"in X minutes"`, `"in X hours"`, or `"in X days"` depending on how far away the shift is. Building it this way means the Home screen rebuilds automatically whenever a shift is added or deleted — no manual refresh logic anywhere.

### The AI-written part I understand best

- **File:** `lib/services/gemini_service.dart`
- **Commit:** https://github.com/yalunghans88-droid/shiftsnap/commit/ee66eac
- **What it does and why we kept it:** Sends a roster photo to `gemini-2.0-flash` with a JSON-only prompt, then parses the response back into `Shift` objects. The reason we kept it in this shape is the `RosterExtractionResult` wrapper — instead of throwing exceptions on failure, it returns either `{ shifts }` or `{ error }`. That one design choice means the Camera screen can call `extractFromImage()` and then just check `result.success` before navigating, without any try/catch clutter.
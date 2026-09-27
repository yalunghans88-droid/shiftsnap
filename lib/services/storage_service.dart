import 'package:hive_ce/hive.dart';

import '../models/shift.dart';
import '../models/scanned_roster.dart';
import '../models/user_preferences.dart';

/// Centralised access point for all Hive boxes.
///
/// Why this exists: instead of scattering `Hive.box<Shift>('shifts')`
/// calls throughout the app, everything goes through here. Easier to
/// test, easier to change later.
class StorageService {
  static const String shiftsBoxName = 'shifts';
  static const String rostersBoxName = 'rosters';
  static const String preferencesBoxName = 'preferences';

  Box<Shift> get shifts => Hive.box<Shift>(shiftsBoxName);
  Box<ScannedRoster> get rosters => Hive.box<ScannedRoster>(rostersBoxName);
  Box<UserPreferences> get preferences =>
      Hive.box<UserPreferences>(preferencesBoxName);

  /// All shifts, sorted chronologically.
  List<Shift> allShiftsSorted() {
    final list = shifts.values.toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  /// Save a batch of extracted shifts at once (used after Review).
  Future<void> saveShifts(List<Shift> newShifts) async {
    final confirmed = newShifts
        .map((s) => Shift(
              title: s.title,
              date: s.date,
              startTime: s.startTime,
              endTime: s.endTime,
              description: s.description,
              confirmed: true,
            ))
        .toList();
    await shifts.addAll(confirmed);
  }

  /// Delete a shift by its Hive key.
  Future<void> deleteShift(dynamic key) async {
    await shifts.delete(key);
  }

  /// Clear all shifts (used only in dev/testing).
  Future<void> clearAll() async {
    await shifts.clear();
  }

  /// Read the user's reminder preference, defaulting to 60 minutes.
  int reminderMinutes() {
    if (preferences.isEmpty) return 60;
    return preferences.getAt(0)!.reminderMinutesBefore;
  }

  /// Persist the reminder preference (creates the row if missing).
  Future<void> setReminderMinutes(int minutes) async {
    if (preferences.isEmpty) {
      await preferences.add(UserPreferences(reminderMinutesBefore: minutes));
    } else {
      final existing = preferences.getAt(0)!;
      existing.reminderMinutesBefore = minutes;
      await existing.save();
    }
  }
}
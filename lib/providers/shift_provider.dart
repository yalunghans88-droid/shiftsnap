import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/shift.dart';

/// The Hive box that holds all confirmed shifts.
final shiftsBoxProvider = Provider<Box<Shift>>((ref) {
  return Hive.box<Shift>('shifts');
});

/// A reactive list of all shifts, sorted by start time ascending.
final allShiftsProvider = Provider<List<Shift>>((ref) {
  final box = ref.watch(shiftsBoxProvider);
  final shifts = box.values.toList()
    ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  return shifts;
});

/// The next upcoming shift (first shift whose end time is in the future).
final nextShiftProvider = Provider<Shift?>((ref) {
  final shifts = ref.watch(allShiftsProvider);
  final now = DateTime.now();
  for (final shift in shifts) {
    if (shift.endDateTime.isAfter(now)) {
      return shift;
    }
  }
  return null;
});

/// All upcoming shifts AFTER the next one.
final upcomingShiftsProvider = Provider<List<Shift>>((ref) {
  final shifts = ref.watch(allShiftsProvider);
  final next = ref.watch(nextShiftProvider);
  final now = DateTime.now();

  return shifts.where((s) {
    if (s.endDateTime.isBefore(now)) return false;
    if (next != null && s.key == next.key) return false;
    return true;
  }).toList();
});

/// Formatted countdown string for a shift, e.g. "in 2 hours".
String formatCountdown(Shift shift) {
  final diff = shift.startDateTime.difference(DateTime.now());
  if (diff.isNegative) return 'in progress';

  if (diff.inDays >= 1) {
    return 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
  }
  if (diff.inHours >= 1) {
    return 'in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
  }
  return 'in ${diff.inMinutes} min';
}
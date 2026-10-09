import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/shift.dart';

/// The Hive box that holds all confirmed shifts.
final shiftsBoxProvider = Provider<Box<Shift>>((ref) {
  return Hive.box<Shift>('shifts');
});

/// Internal broadcast stream for reload signals.
final _shiftsStreamProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// Bump this to force all shift views to reload.
final shiftsVersionProvider = NotifierProvider<ShiftsVersionNotifier, int>(
  ShiftsVersionNotifier.new,
);

class ShiftsVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
    ref.read(_shiftsStreamProvider).add(null);
  }
}

/// A reactive stream of all shifts, sorted chronologically.
final allShiftsProvider = StreamProvider<List<Shift>>((ref) {
  final box = ref.watch(shiftsBoxProvider);
  final controller = ref.watch(_shiftsStreamProvider);

  final output = StreamController<List<Shift>>();

  List<Shift> readAll() {
    return box.values.toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  output.add(readAll());
  controller.stream.listen((_) => output.add(readAll()));
  ref.onDispose(output.close);

  return output.stream;
});

/// Helper: return the next upcoming shift (or null).
Shift? findNextShift(List<Shift> shifts) {
  final now = DateTime.now();
  for (final shift in shifts) {
    if (shift.endDateTime.isAfter(now)) {
      return shift;
    }
  }
  return null;
}

/// Helper: return all upcoming shifts AFTER the next one.
List<Shift> findUpcoming(List<Shift> shifts, Shift? next) {
  final now = DateTime.now();
  return shifts.where((s) {
    if (s.endDateTime.isBefore(now)) return false;
    if (next != null && s.key == next.key) return false;
    return true;
  }).toList();
}

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

/// Replace an existing shift in Hive with an updated version.
Future<void> updateShiftInHive(Shift original, Shift updated) async {
  final box = Hive.box<Shift>('shifts');
  final replacement = Shift(
    title: updated.title,
    date: updated.date,
    startTime: updated.startTime,
    endTime: updated.endTime,
    description: updated.description,
    confirmed: true,
  );
  await box.put(original.key, replacement);
}

/// Delete a shift by its Hive key.
Future<void> deleteShiftFromHive(dynamic key) async {
  final box = Hive.box<Shift>('shifts');
  await box.delete(key);
}
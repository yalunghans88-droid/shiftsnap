import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Reactive reminder preference. Reads from Hive and updates the UI when
/// the user changes it. Also triggers rescheduling externally.
class ReminderMinutesNotifier extends Notifier<int> {
  @override
  int build() {
    final storage = ref.read(storageServiceProvider);
    return storage.reminderMinutes();
  }

  Future<void> set(int minutes) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setReminderMinutes(minutes);
    state = minutes;
  }
}

final reminderMinutesProvider =
    NotifierProvider<ReminderMinutesNotifier, int>(
  ReminderMinutesNotifier.new,
);
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/preferences_provider.dart';
import '../services/notification_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Hamburger drawer with the reminder preference slider.
class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(reminderMinutesProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: const Text('ShiftSnap',
                  style: AppTextStyles.header),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Remind me before shift',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Currently: $minutes minutes before',
                  style: AppTextStyles.caption),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final option in const [15, 30, 60, 120, 240])
                    RadioListTile<int>(
                      value: option,
                      groupValue: minutes,
                      title: Text(_labelFor(option),
                          style: AppTextStyles.body),
                      activeColor: AppColors.primary,
                      onChanged: (v) async {
                        if (v == null) return;
                        await ref
                            .read(reminderMinutesProvider.notifier)
                            .set(v);
                        await NotificationService().requestPermission();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(int minutes) {
    if (minutes < 60) return '$minutes minutes before';
    final hours = minutes ~/ 60;
    return '$hours hour${hours == 1 ? '' : 's'} before';
  }
}
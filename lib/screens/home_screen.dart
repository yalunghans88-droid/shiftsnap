
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/app_bar.dart';
import '../widgets/edit_modal.dart';
import '../widgets/empty_state.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/shift_card.dart';
import 'camera_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final allShiftsAsync = ref.watch(allShiftsProvider);
    final allShifts = allShiftsAsync.value ?? const <Shift>[];

    final nextShift = findNextShift(allShifts);
    final upcomingShifts = findUpcoming(allShifts, nextShift);
    final hasAnyShift = nextShift != null || upcomingShifts.isNotEmpty;

    

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.surface,
      appBar: ShiftSnapAppBar(
        onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const SettingsDrawer(),
      body: hasAnyShift
          ? _buildWithShifts(context, ref, nextShift, upcomingShifts)
          : const EmptyStateCard(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'manual-add',
            backgroundColor: AppColors.accent,
            onPressed: () => _addShiftManually(context, ref),
            child: const Icon(Icons.add, color: AppColors.surface),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'camera',
            backgroundColor: AppColors.primary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
            },
            child: const Icon(Icons.camera_alt, color: AppColors.surface),
          ),
        ],
      ),
    );
  }

  Future<void> _addShiftManually(BuildContext context, WidgetRef ref) async {
    final newShift = await showDialog<Shift>(
      context: context,
      builder: (_) => const EditShiftModal(),
    );
    if (newShift == null) return;

    final confirmed = Shift(
      title: newShift.title,
      date: newShift.date,
      startTime: newShift.startTime,
      endTime: newShift.endTime,
      description: newShift.description,
      confirmed: true,
    );

    await Hive.box<Shift>('shifts').add(confirmed);
    ref.read(shiftsVersionProvider.notifier).bump();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shift added.')),
    );
  }

  Future<void> _showShiftActions(
    BuildContext context,
    WidgetRef ref,
    Shift shift,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  shift.title,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit shift'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _editSavedShift(context, ref, shift);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete shift'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _confirmDelete(context, ref, shift);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editSavedShift(
    BuildContext context,
    WidgetRef ref,
    Shift shift,
  ) async {
    final updated = await showDialog<Shift>(
      context: context,
      builder: (_) => EditShiftModal(initial: shift),
    );
    if (updated == null) return;

    await updateShiftInHive(shift, updated);
    ref.read(shiftsVersionProvider.notifier).bump();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shift updated.')),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Shift shift,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this shift?'),
        content: Text(
          '${shift.title} on '
          '${shift.date.year}-${shift.date.month.toString().padLeft(2, '0')}-${shift.date.day.toString().padLeft(2, '0')} '
          'will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await deleteShiftFromHive(shift.key);
    ref.read(shiftsVersionProvider.notifier).bump();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shift deleted.')),
    );
  }

  Widget _buildWithShifts(
    BuildContext context,
    WidgetRef ref,
    Shift? nextShift,
    List<Shift> upcomingShifts,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Next Shift', style: AppTextStyles.sectionTitle),
          ),
          const SizedBox(height: 12),
          if (nextShift != null)
            NextShiftHeroCard(
              shift: nextShift,
              countdown: formatCountdown(nextShift),
              onTap: () => _showShiftActions(context, ref, nextShift),
            ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Upcoming Shift', style: AppTextStyles.sectionTitle),
          ),
          const SizedBox(height: 8),
          ...upcomingShifts.map(
            (s) => ShiftCard(
              shift: s,
              onTap: () => _showShiftActions(context, ref, s),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
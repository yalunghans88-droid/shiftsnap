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
    final nextShift = ref.watch(nextShiftProvider);
    final upcomingShifts = ref.watch(upcomingShiftsProvider);
    final hasAnyShift = nextShift != null || upcomingShifts.isNotEmpty;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.surface,
      appBar: ShiftSnapAppBar(
        onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const SettingsDrawer(),
      body: hasAnyShift
          ? _buildWithShifts(nextShift, upcomingShifts)
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

  /// Opens the edit modal with a blank shift, then saves it directly
  /// to the Hive box if the user confirms.
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

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shift added.')),
    );
  }

  Widget _buildWithShifts(Shift? nextShift, List<Shift> upcomingShifts) {
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
            ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Upcoming Shift', style: AppTextStyles.sectionTitle),
          ),
          const SizedBox(height: 8),
          ...upcomingShifts.map((s) => ShiftCard(shift: s)),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
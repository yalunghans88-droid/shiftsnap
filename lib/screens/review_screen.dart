import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

import '../models/shift.dart';
import '../providers/roster_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/app_bar.dart';
import '../widgets/edit_modal.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  Future<void> _editShift(
    BuildContext context,
    WidgetRef ref,
    int index,
    Shift shift,
  ) async {
    final updated = await showDialog<Shift>(
      context: context,
      builder: (_) => EditShiftModal(initial: shift),
    );
    if (updated != null) {
      ref.read(rosterProvider.notifier).updateShift(index, updated);
    }
  }

  Future<void> _addShiftManually(BuildContext context, WidgetRef ref) async {
    final newShift = await showDialog<Shift>(
      context: context,
      builder: (_) => const EditShiftModal(),
    );
    if (newShift != null) {
      ref.read(rosterProvider.notifier).addShift(newShift);
    }
  }

  Future<void> _confirmAndSave(BuildContext context, WidgetRef ref) async {
    final state = ref.read(rosterProvider);
    final box = Hive.box<Shift>('shifts');

    for (final shift in state.extractedShifts) {
      final confirmed = Shift(
        title: shift.title,
        date: shift.date,
        startTime: shift.startTime,
        endTime: shift.endTime,
        description: shift.description,
        confirmed: true,
      );
      await box.add(confirmed);
    }

    ref.read(rosterProvider.notifier).reset();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${state.extractedShifts.length} shifts saved.')),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rosterProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const ShiftSnapAppBar(showBack: true),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Review Shift',
                          style: AppTextStyles.sectionTitle),
                    ],
                  ),
                ),
                Expanded(
                  child: state.extractedShifts.isEmpty
                      ? const Center(
                          child: Text(
                            'No shifts to review.',
                            style: AppTextStyles.body,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: state.extractedShifts.length,
                          itemBuilder: (context, i) {
                            final shift = state.extractedShifts[i];
                            return _ReviewShiftCard(
                              shift: shift,
                              onEdit: () =>
                                  _editShift(context, ref, i, shift),
                              onDelete: () => ref
                                  .read(rosterProvider.notifier)
                                  .removeShift(i),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addShiftManually(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Shift Manually'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.extractedShifts.isEmpty
                              ? null
                              : () => _confirmAndSave(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Confirm & Save',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReviewShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewShiftCard({
    required this.shift,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(shift.date);
    final timeStr = '${shift.startTime} - ${shift.endTime}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(shift.title, style: AppTextStyles.caption),
              Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 20),
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
          Text(dateStr,
              style:
                  AppTextStyles.highlight.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(timeStr, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
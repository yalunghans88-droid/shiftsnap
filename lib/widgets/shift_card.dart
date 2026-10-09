import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shift.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Hero card shown at the top of the Home screen with a countdown.
/// Tap to expand and reveal the description + edit/delete actions.
class NextShiftHeroCard extends StatefulWidget {
  final Shift shift;
  final String countdown;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NextShiftHeroCard({
    super.key,
    required this.shift,
    required this.countdown,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<NextShiftHeroCard> createState() => _NextShiftHeroCardState();
}

class _NextShiftHeroCardState extends State<NextShiftHeroCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final dateStr = DateFormat('EEEE, MMM d').format(shift.date);
    final timeStr = '${shift.startTime} - ${shift.endTime}';
    final hasDescription =
        shift.description != null && shift.description!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.accent, width: 6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Next Shift', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(shift.title, style: AppTextStyles.highlight),
            const SizedBox(height: 4),
            Text(dateStr, style: AppTextStyles.body),
            const SizedBox(height: 2),
            Text(timeStr, style: AppTextStyles.body),
            const SizedBox(height: 6),
            Text(widget.countdown, style: AppTextStyles.countdown),

            // Expanded content
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (hasDescription) ...[
                const Text('Description', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(shift.description!, style: AppTextStyles.body),
                const SizedBox(height: 12),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No description',
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard card for the Upcoming Shift list.
/// Tap to expand and reveal the description + edit/delete actions.
class ShiftCard extends StatefulWidget {
  final Shift shift;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ShiftCard({
    super.key,
    required this.shift,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends State<ShiftCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final dateStr = DateFormat('EEE, MMM d').format(shift.date);
    final timeStr = '${shift.startTime} - ${shift.endTime}';
    final hasDescription =
        shift.description != null && shift.description!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.accent, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shift.title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: AppTextStyles.caption),
                Text(timeStr, style: AppTextStyles.caption),
              ],
            ),

            // Expanded content
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (hasDescription) ...[
                const Text('Description', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(shift.description!, style: AppTextStyles.body),
                const SizedBox(height: 12),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No description',
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shift.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Hero card shown at the top of the Home screen with a countdown.
/// Source: DESIGN SYSTEM Step D — COMPONENT 2
class NextShiftHeroCard extends StatelessWidget {
  final Shift shift;
  final String countdown;

  const NextShiftHeroCard({
    super.key,
    required this.shift,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(shift.date);
    final timeStr = '${shift.startTime} - ${shift.endTime}';

    return Container(
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
          Text(dateStr, style: AppTextStyles.highlight),
          const SizedBox(height: 4),
          Text(timeStr, style: AppTextStyles.body),
          const SizedBox(height: 6),
          Text(countdown, style: AppTextStyles.countdown),
        ],
      ),
    );
  }
}

/// Simple single-line card for the Upcoming Shift list.
/// Source: DESIGN SYSTEM Step D — COMPONENT 3
class ShiftCard extends StatelessWidget {
  final Shift shift;

  const ShiftCard({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(shift.date);
    final timeStr = '${shift.startTime} - ${shift.endTime}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(timeStr, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
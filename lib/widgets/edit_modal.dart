import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shift.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Pop-up modal for editing a single shift.
/// Source: DESIGN SYSTEM Step D — COMPONENT 5
class EditShiftModal extends StatefulWidget {
  final Shift? initial;

  const EditShiftModal({super.key, this.initial});

  @override
  State<EditShiftModal> createState() => _EditShiftModalState();
}

class _EditShiftModalState extends State<EditShiftModal> {
  late TextEditingController _titleController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _descController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final now = DateTime.now();
    final defaultStart = '${now.hour.toString().padLeft(2, '0')}:00';
    final defaultEnd = '${(now.hour + 1).toString().padLeft(2, '0')}:00';

    _titleController = TextEditingController(text: initial?.title ?? '');
    _startController = TextEditingController(text: initial?.startTime ?? defaultStart);
    _endController = TextEditingController(text: initial?.endTime ?? defaultEnd);
    _descController = TextEditingController(text: initial?.description ?? '');
    _date = initial?.date ?? DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _endController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _confirm() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty.')),
      );
      return;
    }

    final updated = Shift(
      title: _titleController.text.trim(),
      date: _date,
      startTime: _startController.text.trim(),
      endTime: _endController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      confirmed: widget.initial?.confirmed ?? false,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(_date);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: AppColors.accent, width: 6),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Mode',
                      style: AppTextStyles.sectionTitle
                          .copyWith(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _label('Title'),
              _input(_titleController),
              const SizedBox(height: 12),
              _label('Date'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: AppTextStyles.body),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _label('Time'),
              Row(
                children: [
                  Expanded(child: _input(_startController, hint: 'HH:mm')),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to'),
                  ),
                  Expanded(child: _input(_endController, hint: 'HH:mm')),
                ],
              ),
              const SizedBox(height: 12),
              _label('Add Description (Optional)'),
              _input(_descController, maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.caption),
      );

  Widget _input(TextEditingController c, {String? hint, int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
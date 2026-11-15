// Read-only date picker form field that formats selected dates as yyyy-MM-dd.
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../utils/validators.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    final initial = value != null && !value!.isAfter(today) && !value!.isBefore(oneYearAgo)
        ? value!
        : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: oneYearAgo,
      lastDate: today,
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = value != null ? formatDate(value!) : '';
    return TextFormField(
      key: ValueKey<String>('$label::$formatted'),
      initialValue: formatted,
      readOnly: true,
      onTap: () => _pick(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      validator: (_) => value == null ? t('fieldRequired') : null,
    );
  }
}

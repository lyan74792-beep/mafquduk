// Styled dropdown form field backed by a list of lookup string options.
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class LookupDropdown extends StatelessWidget {
  const LookupDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon,
    this.validator,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = (value != null && options.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>('$label::$effectiveValue::${options.length}'),
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      items: options
          .map(
            (opt) => DropdownMenuItem<String>(
              value: opt,
              child: Text(tv(opt), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? t('fieldRequired') : null,
    );
  }
}

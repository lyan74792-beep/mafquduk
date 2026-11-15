// Form field validators and ISO date formatting helpers.
import '../l10n/l10n.dart';

final RegExp _phoneRegex = RegExp(r'^05[0-9]{8}$');
final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? requiredField(String? v) {
  if (v == null || v.trim().isEmpty) {
    return t('fieldRequired');
  }
  return null;
}

String? phoneValidator(String? v) {
  final text = v?.trim() ?? '';
  if (text.isEmpty) {
    return t('fieldRequired');
  }
  if (!_phoneRegex.hasMatch(text)) {
    return t('invalidPhone');
  }
  return null;
}

String? emailValidator(String? v) {
  final text = v?.trim() ?? '';
  if (text.isEmpty) {
    return t('fieldRequired');
  }
  if (!_emailRegex.hasMatch(text)) {
    return t('invalidEmail');
  }
  return null;
}

String? Function(String?) minLength(int n) {
  return (String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) {
      return t('fieldRequired');
    }
    if (text.length < n) {
      return '${t('minLengthError')} ($n)';
    }
    return null;
  };
}

String formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

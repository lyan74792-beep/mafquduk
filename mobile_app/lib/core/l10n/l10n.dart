import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings/admin_strings.dart';
import 'strings/auth_strings.dart';
import 'strings/items_strings.dart';
import 'strings/lookup_values.dart';
import 'strings/reports_strings.dart';
import 'strings_ar.dart';
import 'strings_en.dart';
import 'strings_tr.dart';
import 'strings_ur.dart';

/// App language (ar, en, tr, ur) and translated strings.
///
/// Strings live in resource files, never in widget code:
/// - `strings_ar.dart` / `strings_en.dart`: shared/common keys;
/// - `strings/<area>_strings.dart`: Arabic and English keys of one feature area;
/// - `strings_tr.dart` / `strings_ur.dart`: every key in Turkish / Urdu;
/// - `strings/lookup_values.dart`: option values the server stores in Arabic (see [tv]).
///
/// Usage: `t('loginTitle')`. Missing keys fall back to English, then Arabic,
/// then the key itself, so a new screen never shows a blank label.
class L10n extends ChangeNotifier {
  L10n._();

  static final L10n instance = L10n._();
  static const _kLang = 'app_language';

  static const supported = ['ar', 'en', 'tr', 'ur'];
  static const names = {'ar': 'العربية', 'en': 'English', 'tr': 'Türkçe', 'ur': 'اردو'};

  /// Feature string tables; add a new area here.
  static const List<Map<String, Map<String, String>>> _areas = [
    authStrings,
    reportsStrings,
    itemsStrings,
    adminStrings,
  ];

  static final Map<String, Map<String, String>> _strings = _merge();

  static Map<String, Map<String, String>> _merge() {
    final merged = <String, Map<String, String>>{
      'ar': {...stringsAr},
      'en': {...stringsEn},
      'tr': {...stringsTr},
      'ur': {...stringsUr},
    };
    for (final area in _areas) {
      area.forEach((lang, table) => merged.putIfAbsent(lang, () => {}).addAll(table));
    }
    return merged;
  }

  String _lang = 'ar';
  String get lang => _lang;
  bool get isRtl => _lang == 'ar' || _lang == 'ur';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLang);
    if (saved != null && supported.contains(saved)) {
      _lang = saved;
    }
  }

  Future<void> setLanguage(String code) async {
    if (!supported.contains(code) || code == _lang) return;
    _lang = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, code);
    notifyListeners();
  }

  String text(String key) =>
      _strings[_lang]?[key] ?? _strings['en']![key] ?? _strings['ar']![key] ?? key;

  /// A lookup value the server stores in Arabic (category, landmark, item
  /// status, cancel reason) in the current language; unknown values as-is.
  String value(String arabic) => lookupValueStrings[_lang]?[arabic.trim()] ?? arabic;
}

/// Translate [key] into the current language.
String t(String key) => L10n.instance.text(key);

/// Show a lookup value stored in Arabic in the current language. Display only:
/// forms still send the Arabic value to the API.
String tv(String value) => L10n.instance.value(value);

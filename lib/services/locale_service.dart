import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String indonesian = 'Bahasa Indonesia';
  static const String english = 'English';

  static final ValueNotifier<String> language = ValueNotifier(indonesian);

  static bool get isEnglish => language.value == english;

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString('lang');
      if (saved == english || saved == indonesian) {
        language.value = saved!;
      }
    } catch (_) {}
  }

  static Future<void> setLanguage(String lang) async {
    final normalized = lang == english ? english : indonesian;
    language.value = normalized;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lang', normalized);
    } catch (_) {}
  }

  static String tr(String id, String en) => isEnglish ? en : id;
}

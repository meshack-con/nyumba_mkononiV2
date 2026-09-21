import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageOption {
  const LanguageOption(this.code, this.name);
  final String code;
  final String name;
}

/// Inahifadhi lugha ya app: Kiswahili (default) au English.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _key = 'app_language';

  static const List<LanguageOption> languages = [
    LanguageOption('sw', 'Kiswahili'),
    LanguageOption('en', 'English'),
  ];

  String _code = 'sw';

  String get code => _code;
  bool get isEnglish => _code == 'en';
  String get currentName =>
      languages.firstWhere((l) => l.code == _code, orElse: () => languages.first).name;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      _code = languages.any((l) => l.code == saved) ? saved! : 'sw';
    } catch (_) {
      _code = 'sw';
    }
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code == _code || !languages.any((l) => l.code == code)) return;
    _code = code;
    notifyListeners();
    _rebuildWholeApp();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {
      // Chaguo linabaki kwa kipindi hiki hata kama kuhifadhi kumeshindwa.
    }
  }

  /// Inalazimisha screens zote zisome maandishi mapya lugha inapobadilika.
  void _rebuildWholeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
    });
  }
}

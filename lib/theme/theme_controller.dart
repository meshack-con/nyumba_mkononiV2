import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chaguo la rangi kuu ya app.
class AccentOption {
  const AccentOption(this.id, this.name, this.primary, this.container);
  final String id;
  final String name;
  final Color primary;
  final Color container;
}

/// Inahifadhi chaguo la mtumiaji: White/Dark mode na rangi kuu.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  int? _userId;

  static const List<AccentOption> accents = [
    AccentOption('pink', 'Pinki', Color(0xFF9C2C50), Color(0xFFC24571)),
    AccentOption('blue', 'Bluu', Color(0xFF1565C0), Color(0xFF3D8BE0)),
    AccentOption('indigo', 'Nili', Color(0xFF3949AB), Color(0xFF5C6BC0)),
    AccentOption('green', 'Kijani', Color(0xFF2E7D32), Color(0xFF43A047)),
    AccentOption('teal', 'Kijani bluu', Color(0xFF00796B), Color(0xFF26A69A)),
    AccentOption('purple', 'Zambarau', Color(0xFF7B3FA0), Color(0xFF9B5FC4)),
    AccentOption('orange', 'Machungwa', Color(0xFFC2570C), Color(0xFFE67A2E)),
    AccentOption('red', 'Nyekundu', Color(0xFFC62828), Color(0xFFE53935)),
  ];

  ThemeMode _mode = ThemeMode.light;
  AccentOption _accent = accents.first;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  AccentOption get accent => _accent;

  Future<void> load() async {
    await loadForUser(null);
  }

  Future<void> loadForUser(int? userId) async {
    _userId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeKey = userId == null ? null : 'theme_mode_user_$userId';
      final accentKey = userId == null ? null : 'accent_color_user_$userId';
      _mode = modeKey != null && prefs.getString(modeKey) == 'dark' ? ThemeMode.dark : ThemeMode.light;
      final id = accentKey == null ? null : prefs.getString(accentKey);
      _accent = accents.firstWhere((a) => a.id == id, orElse: () => accents.first);
    } catch (_) {
      _mode = ThemeMode.light;
      _accent = accents.first;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userId != null) {
        await prefs.setString('theme_mode_user_${_userId!}', mode == ThemeMode.dark ? 'dark' : 'light');
      }
    } catch (_) {
      // Chaguo linabaki kwa kipindi hiki hata kama kuhifadhi kumeshindwa.
    }
  }

  Future<void> setAccent(AccentOption option) async {
    if (option.id == _accent.id) return;
    _accent = option;
    notifyListeners();
    _rebuildWholeApp();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userId != null) {
        await prefs.setString('accent_color_user_${_userId!}', option.id);
      }
    } catch (_) {
      // Chaguo linabaki kwa kipindi hiki hata kama kuhifadhi kumeshindwa.
    }
  }

  /// Screens nyingi zinatumia AppTheme.primary moja kwa moja, kwa hiyo
  /// tunalazimisha kila widget ijijenge upya rangi inapobadilika.
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

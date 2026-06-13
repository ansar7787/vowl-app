import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-grade locale service for Vowl.
///
/// Manages locale persistence, translation loading, and string resolution.
/// Designed as a singleton registered through DI for app-wide access.
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'vowl_app_locale';

  Locale _currentLocale = const Locale('en');
  Map<String, dynamic> _translations = {};
  Map<String, dynamic> _fallbackTranslations = {};
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  /// All supported locales with metadata for the language picker.
  static const List<LocaleInfo> supportedLocales = [
    LocaleInfo(locale: Locale('en'), name: 'English', nativeName: 'English', flag: '🇺🇸'),
    LocaleInfo(locale: Locale('hi'), name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('es'), name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    LocaleInfo(locale: Locale('pt'), name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷'),
    LocaleInfo(locale: Locale('ar'), name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    LocaleInfo(locale: Locale('fr'), name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    LocaleInfo(locale: Locale('ru'), name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    LocaleInfo(locale: Locale('zh'), name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    LocaleInfo(locale: Locale('ko'), name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    LocaleInfo(locale: Locale('ja'), name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    LocaleInfo(locale: Locale('de'), name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    LocaleInfo(locale: Locale('ml'), name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('kn'), name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('ta'), name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('te'), name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('mr'), name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('bn'), name: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('gu'), name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
  ];

  /// Initialize the service: load persisted locale preference and translations.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      if (savedLocale != null && _isSupportedLocale(savedLocale)) {
        _currentLocale = Locale(savedLocale);
      }

      // Always load English as fallback
      _fallbackTranslations = await _loadTranslations('en');
      _translations = _currentLocale.languageCode == 'en'
          ? _fallbackTranslations
          : await _loadTranslations(_currentLocale.languageCode);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('LocaleService: Init error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change the active locale, persist preference, and reload translations.
  Future<void> setLocale(Locale locale) async {
    if (!_isSupportedLocale(locale.languageCode)) return;
    if (locale == _currentLocale) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);

      _currentLocale = locale;
      _translations = locale.languageCode == 'en'
          ? _fallbackTranslations
          : await _loadTranslations(locale.languageCode);

      notifyListeners();
    } catch (e) {
      debugPrint('LocaleService: setLocale error: $e');
    }
  }

  /// Translate a dot-notated key (e.g., "settings.title").
  /// Falls back to English if key is missing in the active locale.
  /// Supports `{}` placeholder substitution via [args].
  String tr(String key, {List<String> args = const [], String? fallback}) {
    String value = _resolve(key, _translations) ??
        _resolve(key, _fallbackTranslations) ??
        fallback ?? key;

    // Replace {} placeholders with args
    for (final arg in args) {
      value = value.replaceFirst('{}', arg);
    }

    return value;
  }

  /// Get the display name for the current locale (for UI display).
  String get currentLocaleName {
    final info = supportedLocales.firstWhere(
      (l) => l.locale.languageCode == _currentLocale.languageCode,
      orElse: () => supportedLocales.first,
    );
    return info.nativeName;
  }

  /// Get the flag emoji for the current locale.
  String get currentLocaleFlag {
    final info = supportedLocales.firstWhere(
      (l) => l.locale.languageCode == _currentLocale.languageCode,
      orElse: () => supportedLocales.first,
    );
    return info.flag;
  }

  // ─── Private Helpers ────────────────────────────────────────

  Future<Map<String, dynamic>> _loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('LocaleService: Failed to load $languageCode translations: $e');
      return {};
    }
  }

  bool _isSupportedLocale(String code) {
    return supportedLocales.any((l) => l.locale.languageCode == code);
  }

  /// Resolve a dot-notated key like "settings.title" from a nested map.
  String? _resolve(String key, Map<String, dynamic> map) {
    final parts = key.split('.');
    dynamic current = map;

    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current is String ? current : null;
  }
}

/// Immutable metadata for a supported locale.
class LocaleInfo {
  final Locale locale;
  final String name;
  final String nativeName;
  final String flag;

  const LocaleInfo({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

/// Extension on BuildContext for convenient translation access.
extension LocaleContextExtension on BuildContext {
  /// Shorthand for translating a key using the LocaleService.
  /// Usage: `context.tr('settings.title')`
  String tr(String key, {List<String> args = const [], String? fallback}) {
    try {
      // Access from the widget tree via the InheritedWidget / ChangeNotifierProvider
      // Since we use GetIt, we access directly from the service locator.
      // This avoids requiring a Provider wrapper.
      return _localeServiceInstance.tr(key, args: args, fallback: fallback);
    } catch (_) {
      return fallback ?? key;
    }
  }
}

/// Cached reference to avoid repeated GetIt lookups in hot paths.
late final LocaleService _localeServiceInstance;

/// Must be called once during DI initialization.
void initLocaleServiceReference(LocaleService service) {
  _localeServiceInstance = service;
}

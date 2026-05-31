import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The reactive state holding the current active theme configuration and
/// the premium high-contrast midnight mode flag.
class ThemeState {
  final ThemeMode themeMode;
  final bool isMidnight;

  ThemeState({
    required this.themeMode,
    required this.isMidnight,
  });

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isSystem => themeMode == ThemeMode.system;

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isMidnight,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isMidnight: isMidnight ?? this.isMidnight,
    );
  }
}

/// The central controller coordinating the theme modes of the Vowl app,
/// persisting user settings across sessions using SharedPreferences.
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeModeKey = 'vowl_theme_mode';
  static const String _isMidnightKey = 'vowl_is_midnight';

  ThemeCubit()
      : super(ThemeState(themeMode: ThemeMode.system, isMidnight: false)) {
    _loadPersistedTheme();
  }

  /// Recovers user preference tokens from local storage on app initialization.
  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey) ?? 'system';
      final isMidnightValue = prefs.getBool(_isMidnightKey) ?? false;

      ThemeMode mode;
      switch (modeString) {
        case 'dark':
          mode = ThemeMode.dark;
          break;
        case 'light':
          mode = ThemeMode.light;
          break;
        default:
          mode = ThemeMode.system;
      }

      emit(ThemeState(themeMode: mode, isMidnight: isMidnightValue));
    } catch (_) {
      // Safe defensive fallback to system defaults
    }
  }

  /// Toggles the system-adaptive setting.
  Future<void> toggleSystemTheme(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = value
          ? ThemeMode.system
          : (state.isDark ? ThemeMode.dark : ThemeMode.light);

      final modeString = mode == ThemeMode.system
          ? 'system'
          : (mode == ThemeMode.dark ? 'dark' : 'light');

      await prefs.setString(_themeModeKey, modeString);
      emit(state.copyWith(themeMode: mode));
    } catch (_) {
      // Safe defensive fallback
    }
  }

  /// Explicitly toggles between manual Dark and Light themes.
  Future<void> toggleTheme(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = isDark ? ThemeMode.dark : ThemeMode.light;

      await prefs.setString(_themeModeKey, isDark ? 'dark' : 'light');
      emit(state.copyWith(themeMode: mode));
    } catch (_) {
      // Safe defensive fallback
    }
  }

  /// Toggles the premium high-contrast midnight black backdrop filter.
  Future<void> toggleMidnight(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isMidnightKey, value);
      emit(state.copyWith(isMidnight: value));
    } catch (_) {
      // Safe defensive fallback
    }
  }
}

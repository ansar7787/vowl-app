import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// The reactive state holding the current active theme configuration and
/// the premium high-contrast midnight mode flag.
///
/// FIX (CRITICAL-2): Extends [Equatable] so that [context.select<ThemeCubit>]
/// only triggers rebuilds when the values actually change. Previously, every
/// `emit(state.copyWith(...))` created a new object that failed identity
/// equality, causing full-tree rebuilds even when theme hadn't changed.
class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final bool isMidnight;

  const ThemeState({required this.themeMode, required this.isMidnight});

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isSystem => themeMode == ThemeMode.system;

  ThemeState copyWith({ThemeMode? themeMode, bool? isMidnight}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isMidnight: isMidnight ?? this.isMidnight,
    );
  }

  // FIX (CRITICAL-2): Equatable uses these props for == and hashCode.
  // Two ThemeStates with the same themeMode and isMidnight are now equal,
  // preventing unnecessary downstream widget rebuilds.
  @override
  List<Object?> get props => [themeMode, isMidnight];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// The central controller coordinating the theme modes of the Vowl app,
/// persisting user settings across sessions using SharedPreferences.
///
/// ### Initialization order note
/// [ThemeCubit] is registered as a **lazy singleton** in the DI container
/// (see `di_auth.dart`). The constructor immediately starts loading persisted
/// settings. The very first frame may briefly show the default (system) theme
/// before the persisted preference is emitted. This is an inherent limitation
/// of async-only SharedPreferences; mitigating it would require HydratedBloc
/// or a synchronous storage layer.
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeModeKey = 'vowl_theme_mode';
  static const String _isMidnightKey = 'vowl_is_midnight';

  ThemeCubit()
    : super(const ThemeState(themeMode: ThemeMode.system, isMidnight: false)) {
    _loadPersistedTheme();
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Recovers user preference tokens from local storage on app initialization.
  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = _parseThemeMode(prefs.getString(_themeModeKey));
      final isMidnight = prefs.getBool(_isMidnightKey) ?? false;
      // FIX (CRITICAL-2): Equatable prevents a rebuild if the persisted
      // values happen to match the defaults already in state.
      emit(ThemeState(themeMode: mode, isMidnight: isMidnight));
    } catch (_) {
      // Safe defensive fallback — leave state at system defaults.
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Switches between system-adaptive and manual theme.
  Future<void> toggleSystemTheme(bool useSystem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = useSystem
          ? ThemeMode.system
          : (state.isDark ? ThemeMode.dark : ThemeMode.light);
      await prefs.setString(_themeModeKey, _encodeThemeMode(mode));
      emit(state.copyWith(themeMode: mode));
    } catch (_) {
      // Safe defensive fallback — no state change on failure.
    }
  }

  /// Explicitly toggles between manual Dark and Light modes.
  Future<void> toggleTheme(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = isDark ? ThemeMode.dark : ThemeMode.light;
      await prefs.setString(_themeModeKey, _encodeThemeMode(mode));
      emit(state.copyWith(themeMode: mode));
    } catch (_) {
      // Safe defensive fallback.
    }
  }

  /// Toggles the premium high-contrast midnight black backdrop.
  Future<void> toggleMidnight(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isMidnightKey, value);
      emit(state.copyWith(isMidnight: value));
    } catch (_) {
      // Safe defensive fallback.
    }
  }
}

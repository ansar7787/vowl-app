import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState {
  final ThemeMode themeMode;
  final bool isMidnight;

  ThemeState({
    required this.themeMode,
    required this.isMidnight,
  });

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isSystem => themeMode == ThemeMode.system;
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
      : super(ThemeState(themeMode: ThemeMode.system, isMidnight: false)) {
    // We always default to system mode for production stability and splash harmony
  }

  // Simplified methods that no longer force manual modes
  Future<void> toggleSystemTheme(bool value) async {}
  Future<void> toggleTheme(bool isDark) async {}
  Future<void> toggleMidnight(bool value) async {}
}

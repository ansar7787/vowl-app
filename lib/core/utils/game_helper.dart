import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

/// Centralised utility that maps enums, categories, and gameplay levels to
/// visual themes, icons, and structured metadata.
class GameHelper {
  const GameHelper._(); // Non-instantiable utility class.

  /// Returns the parent category name string for a given [subtype].
  static String getCategoryForSubtype(GameSubtype subtype) {
    return subtype.category.name;
  }

  /// Returns the icon associated with a primary quest [type].
  static IconData getIconForCategory(QuestType type) {
    return LevelThemeHelper.getCategoryTheme(type.name).icon;
  }

  /// Returns structured visual metadata for [subtype] at [level].
  ///
  /// FIX (MEDIUM-2): [isDark] was previously optional with `isDark = true`
  /// as a default. This caused light-mode callers who omitted the parameter
  /// to silently receive dark-mode colours in their UI.
  ///
  /// [isDark] is now **required** so every call site must be explicit about
  /// the current brightness. Pass `Theme.of(context).brightness == Brightness.dark`.
  static GameMetadata getGameMetadata(
    GameSubtype subtype, {
    int level = 1,
    required bool isDark,
  }) {
    final theme = LevelThemeHelper.getTheme(
      subtype.name,
      level: level,
      isDark: isDark,
    );
    return GameMetadata(
      title: theme.title,
      color: theme.primaryColor,
      categoryName: getCategoryForSubtype(subtype).toUpperCase(),
      icon: theme.icon,
    );
  }

  /// Returns the icon associated with a gameplay [subtype].
  static IconData getIconForSubtype(GameSubtype subtype) {
    return LevelThemeHelper.getTheme(subtype.name).icon;
  }

  /// Returns the primary theme colour for a category string.
  static Color getCategoryColor(String category) {
    return LevelThemeHelper.getCategoryTheme(category).primaryColor;
  }

  /// Type-safe colour resolver for a [QuestType].
  static Color getQuestTypeColor(QuestType type) {
    return getCategoryColor(type.name);
  }
}

// ---------------------------------------------------------------------------
// Value object — resolved visual parameters for a game screen
// ---------------------------------------------------------------------------

/// Immutable descriptor of the visual identity for a specific game screen.
@immutable
class GameMetadata {
  final String title;
  final IconData icon;
  final Color color;
  final String categoryName;

  const GameMetadata({
    required this.title,
    required this.icon,
    required this.color,
    required this.categoryName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameMetadata &&
          title == other.title &&
          color == other.color &&
          categoryName == other.categoryName;

  @override
  int get hashCode => Object.hash(title, color, categoryName);
}

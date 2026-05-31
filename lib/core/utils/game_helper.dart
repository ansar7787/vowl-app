import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

/// Centralized utility coordinator that maps enums, categories,
/// and gameplay levels to localized Visual Themes, icons, and metadata structures.
class GameHelper {
  // Private constructor to enforce static utility boundaries
  const GameHelper._();

  /// Resolves the raw category string mapped to a specific game subtype.
  static String getCategoryForSubtype(GameSubtype subtype) {
    return subtype.category.name;
  }

  /// Resolves the corresponding visual icon representing a primary quest category.
  static IconData getIconForCategory(QuestType type) {
    return LevelThemeHelper.getCategoryTheme(type.name).icon;
  }

  /// Resolves gameplay assets and structural metadata matching player progression.
  /// 
  /// Leverages the optional [level] parameter to support dynamic level-shading progression.
  static GameMetadata getGameMetadata(
    GameSubtype subtype, {
    int level = 1,
    bool isDark = true,
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

  /// Resolves the specific visual icon mapped to a gameplay subtype.
  static IconData getIconForSubtype(GameSubtype subtype) {
    return LevelThemeHelper.getTheme(subtype.name).icon;
  }

  /// Resolves the base primary theme color mapped to a category string.
  static Color getCategoryColor(String category) {
    return LevelThemeHelper.getCategoryTheme(category).primaryColor;
  }

  /// Type-safe category color mapping wrapper resolving QuestType properties.
  static Color getQuestTypeColor(QuestType type) {
    return getCategoryColor(type.name);
  }
}

/// Dynamic immutable entity representing resolved visual parameters for active screens.
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
}

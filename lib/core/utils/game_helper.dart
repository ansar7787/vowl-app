import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

class GameHelper {
  static String getCategoryForSubtype(GameSubtype subtype) {
    return subtype.category.name;
  }

  static IconData getIconForCategory(QuestType type) {
    return LevelThemeHelper.getCategoryTheme(type.name).icon;
  }

  static GameMetadata getGameMetadata(
    GameSubtype subtype, {
    bool isDark = true,
  }) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    return GameMetadata(
      title: theme.title,
      color: theme.primaryColor,
      categoryName: getCategoryForSubtype(subtype).toUpperCase(),
      icon: theme.icon,
    );
  }

  static IconData getIconForSubtype(GameSubtype subtype) {
    return LevelThemeHelper.getTheme(subtype.name).icon;
  }

  static Color getCategoryColor(String category) {
    return LevelThemeHelper.getCategoryTheme(category).primaryColor;
  }
}

class GameMetadata {
  final String title;
  final IconData icon;
  final Color color;
  final String categoryName;

  GameMetadata({
    required this.title,
    required this.icon,
    required this.color,
    required this.categoryName,
  });
}

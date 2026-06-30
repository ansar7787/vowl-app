import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/kids_routes.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/day_night_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_alphabet_layout.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_numbers_layout.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_colors_layout.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_shapes_layout.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_animals_layout.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class UnifiedKidsGameScreen extends StatelessWidget {
  final String gameType;
  final int level;

  const UnifiedKidsGameScreen({
    super.key,
    required this.gameType,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    if (gameType == 'day_night') {
      return DayNightGameScreen(level: level);
    }
    
    if (gameType == 'alphabet') {
      return KidsAlphabetLayout(level: level, title: KidsRoutes.getKidsGameTitle(gameType), primaryColor: KidsRoutes.getKidsGameColor(gameType));
    }
    if (gameType == 'numbers') {
      return KidsNumbersLayout(level: level, title: KidsRoutes.getKidsGameTitle(gameType), primaryColor: KidsRoutes.getKidsGameColor(gameType));
    }
    if (gameType == 'colors') {
      return KidsColorsLayout(level: level, title: KidsRoutes.getKidsGameTitle(gameType), primaryColor: KidsRoutes.getKidsGameColor(gameType));
    }
    if (gameType == 'shapes') {
      return KidsShapesLayout(level: level, title: KidsRoutes.getKidsGameTitle(gameType), primaryColor: KidsRoutes.getKidsGameColor(gameType));
    }
    if (gameType == 'animals') {
      return KidsAnimalsLayout(level: level, title: KidsRoutes.getKidsGameTitle(gameType), primaryColor: KidsRoutes.getKidsGameColor(gameType));
    }

    return KidsPickerTemplate(
      title: KidsRoutes.getKidsGameTitle(gameType),
      gameType: gameType,
      level: level,
      primaryColor: KidsRoutes.getKidsGameColor(gameType),
      backgroundColors: const [],
      fallbackIcon: _getFallbackIcon(gameType),
      centerTextOverride: null,
    );
  }

  IconData _getFallbackIcon(String gameType) {
    switch (gameType) {
      case 'alphabet': return Icons.abc_rounded;
      case 'numbers': return Icons.numbers_rounded;
      case 'colors': return Icons.palette_rounded;
      case 'shapes': return Icons.category_rounded;
      case 'animals': return Icons.pets_rounded;
      case 'fruits': return Icons.shopping_basket_rounded;
      case 'family': return Icons.people_alt_rounded;
      case 'school': return Icons.school_rounded;
      case 'verbs': return Icons.directions_run_rounded;
      case 'routine': return Icons.wb_sunny_rounded;
      case 'emotions': return Icons.face_rounded;
      case 'prepositions': return Icons.location_on_rounded;
      case 'phonics': return Icons.volume_up_rounded;
      case 'time': return Icons.access_time_filled_rounded;
      case 'opposites': return Icons.compare_rounded;
      case 'nature': return Icons.park_rounded;
      case 'home': return Icons.home_rounded;
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'body_parts': return Icons.accessibility_new_rounded;
      case 'clothing': return Icons.checkroom_rounded;
      default: return Icons.extension_rounded;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/kids_routes.dart';

class KidsGameMetadata {
  final String gameType;
  final String gridTitle;
  final String subtitle;
  final IconData icon;

  const KidsGameMetadata({
    required this.gameType,
    required this.gridTitle,
    required this.subtitle,
    required this.icon,
  });

  String get fullTitle => KidsRoutes.getKidsGameTitle(gameType);
  Color get color => KidsRoutes.getKidsGameColor(gameType);
}

class KidsGameHelper {
  static const List<KidsGameMetadata> allGames = [
    KidsGameMetadata(
      gameType: 'handwriting',
      gridTitle: 'Write & Learn',
      subtitle: 'Handwriting Fun',
      icon: Icons.edit_rounded,
    ),
    KidsGameMetadata(
      gameType: 'alphabet',
      gridTitle: 'ABC',
      subtitle: 'Letters & Phonics',
      icon: Icons.abc_rounded,
    ),
    KidsGameMetadata(
      gameType: 'numbers',
      gridTitle: '123',
      subtitle: 'Numbers & Math',
      icon: Icons.pin_rounded,
    ),
    KidsGameMetadata(
      gameType: 'colors',
      gridTitle: 'Colors',
      subtitle: 'Rainbow Fun',
      icon: Icons.palette_rounded,
    ),
    KidsGameMetadata(
      gameType: 'shapes',
      gridTitle: 'Shapes',
      subtitle: 'Geometry Fun',
      icon: Icons.category_rounded,
    ),
    KidsGameMetadata(
      gameType: 'animals',
      gridTitle: 'Animals',
      subtitle: 'Farm & Wild',
      icon: Icons.pets_rounded,
    ),
    KidsGameMetadata(
      gameType: 'fruits',
      gridTitle: 'Fruits',
      subtitle: 'Healthy Eating',
      icon: Icons.apple_rounded,
    ),
    KidsGameMetadata(
      gameType: 'family',
      gridTitle: 'Family',
      subtitle: 'Love & Home',
      icon: Icons.people_rounded,
    ),
    KidsGameMetadata(
      gameType: 'school',
      gridTitle: 'School',
      subtitle: 'Let\'s Learn',
      icon: Icons.school_rounded,
    ),
    KidsGameMetadata(
      gameType: 'verbs',
      gridTitle: 'Verbs',
      subtitle: 'Action Words',
      icon: Icons.run_circle_rounded,
    ),
    KidsGameMetadata(
      gameType: 'routine',
      gridTitle: 'Routine',
      subtitle: 'My Day',
      icon: Icons.schedule_rounded,
    ),
    KidsGameMetadata(
      gameType: 'emotions',
      gridTitle: 'Emotions',
      subtitle: 'Feelings',
      icon: Icons.mood_rounded,
    ),
    KidsGameMetadata(
      gameType: 'prepositions',
      gridTitle: 'Positions',
      subtitle: 'Where is it?',
      icon: Icons.place_rounded,
    ),
    KidsGameMetadata(
      gameType: 'phonics',
      gridTitle: 'Phonics',
      subtitle: 'Sound Out',
      icon: Icons.record_voice_over_rounded,
    ),
    KidsGameMetadata(
      gameType: 'time',
      gridTitle: 'Time',
      subtitle: 'Tick Tock',
      icon: Icons.watch_later_rounded,
    ),
    KidsGameMetadata(
      gameType: 'opposites',
      gridTitle: 'Opposites',
      subtitle: 'Flip It',
      icon: Icons.swap_horiz_rounded,
    ),
    KidsGameMetadata(
      gameType: 'day_night',
      gridTitle: 'Day & Night',
      subtitle: 'Sun & Moon',
      icon: Icons.brightness_4_rounded,
    ),
    KidsGameMetadata(
      gameType: 'nature',
      gridTitle: 'Nature',
      subtitle: 'Outdoors',
      icon: Icons.forest_rounded,
    ),
    KidsGameMetadata(
      gameType: 'home',
      gridTitle: 'Home',
      subtitle: 'Rooms & Items',
      icon: Icons.home_rounded,
    ),
    KidsGameMetadata(
      gameType: 'food',
      gridTitle: 'Food',
      subtitle: 'Yummy!',
      icon: Icons.restaurant_rounded,
    ),
    KidsGameMetadata(
      gameType: 'transport',
      gridTitle: 'Transport',
      subtitle: 'Vroom Vroom',
      icon: Icons.directions_car_rounded,
    ),
    KidsGameMetadata(
      gameType: 'body_parts',
      gridTitle: 'Body',
      subtitle: 'My Body',
      icon: Icons.accessibility_new_rounded,
    ),
    KidsGameMetadata(
      gameType: 'clothing',
      gridTitle: 'Clothing',
      subtitle: 'Dress Up',
      icon: Icons.checkroom_rounded,
    ),
    KidsGameMetadata(
      gameType: 'weather',
      gridTitle: 'Weather',
      subtitle: 'Sun & Rain',
      icon: Icons.cloud_rounded,
    ),
    KidsGameMetadata(
      gameType: 'professions',
      gridTitle: 'Professions',
      subtitle: 'When I Grow Up',
      icon: Icons.work_rounded,
    ),
  ];

  static KidsGameMetadata getMetadata(String gameType) {
    return allGames.firstWhere(
      (game) => game.gameType == gameType,
      orElse: () => const KidsGameMetadata(
        gameType: 'unknown',
        gridTitle: 'Kids Zone',
        subtitle: 'Kids Game',
        icon: Icons.videogame_asset_rounded,
      ),
    );
  }
}

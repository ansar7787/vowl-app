import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/modern_path_game_map.dart';

class PlaceholderGameMap extends StatelessWidget {
  final String gameType;
  final String categoryId;

  const PlaceholderGameMap({
    super.key,
    required this.gameType,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return ModernPathGameMap(gameType: gameType, categoryId: categoryId);
  }
}

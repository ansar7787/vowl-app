import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class FlashcardsMap extends StatelessWidget {
  const FlashcardsMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'flashcards',
      categoryId: 'vocabulary',
    );
  }
}

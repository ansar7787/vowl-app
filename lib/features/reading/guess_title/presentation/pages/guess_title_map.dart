import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class GuessTitleMap extends StatelessWidget {
  const GuessTitleMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'guessTitle',
      categoryId: 'reading',
    );
  }
}

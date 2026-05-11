import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class MinimalPairsMap extends StatelessWidget {
  const MinimalPairsMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'minimalPairs',
      categoryId: 'accent',
    );
  }
}

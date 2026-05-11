import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SynonymSearchMap extends StatelessWidget {
  const SynonymSearchMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'synonymSearch',
      categoryId: 'vocabulary',
    );
  }
}

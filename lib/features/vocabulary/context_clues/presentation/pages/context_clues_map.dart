import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ContextCluesMap extends StatelessWidget {
  const ContextCluesMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'contextClues',
      categoryId: 'vocabulary',
    );
  }
}

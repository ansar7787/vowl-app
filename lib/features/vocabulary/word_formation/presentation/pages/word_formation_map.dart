import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class WordFormationMap extends StatelessWidget {
  const WordFormationMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'wordFormation',
      categoryId: 'vocabulary',
    );
  }
}

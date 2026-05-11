import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ConsonantClarityMap extends StatelessWidget {
  const ConsonantClarityMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'consonantClarity',
      categoryId: 'accent',
    );
  }
}

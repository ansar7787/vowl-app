import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ClozeTestMap extends StatelessWidget {
  const ClozeTestMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'clozeTest',
      categoryId: 'reading',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class IdiomsMap extends StatelessWidget {
  const IdiomsMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'idioms',
      categoryId: 'vocabulary',
    );
  }
}

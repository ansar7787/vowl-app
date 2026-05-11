import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class GourmetOrderMap extends StatelessWidget {
  const GourmetOrderMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'gourmetOrder',
      categoryId: 'roleplay',
    );
  }
}

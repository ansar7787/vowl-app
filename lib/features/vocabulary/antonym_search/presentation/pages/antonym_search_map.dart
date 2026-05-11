import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class AntonymSearchMap extends StatelessWidget {
  const AntonymSearchMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'antonymSearch',
      categoryId: 'vocabulary',
    );
  }
}

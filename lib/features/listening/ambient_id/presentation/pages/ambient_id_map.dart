import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class AmbientIdMap extends StatelessWidget {
  const AmbientIdMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'ambientId',
      categoryId: 'listening',
    );
  }
}

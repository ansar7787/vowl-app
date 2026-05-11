import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class DetailSpotlightMap extends StatelessWidget {
  const DetailSpotlightMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'detailSpotlight',
      categoryId: 'listening',
    );
  }
}

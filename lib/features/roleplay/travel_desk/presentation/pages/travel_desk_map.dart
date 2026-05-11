import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class TravelDeskMap extends StatelessWidget {
  const TravelDeskMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'travelDesk',
      categoryId: 'roleplay',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class EmergencyHubMap extends StatelessWidget {
  const EmergencyHubMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'emergencyHub',
      categoryId: 'roleplay',
    );
  }
}

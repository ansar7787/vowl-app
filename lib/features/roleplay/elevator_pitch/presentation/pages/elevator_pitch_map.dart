import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ElevatorPitchMap extends StatelessWidget {
  const ElevatorPitchMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'elevatorPitch',
      categoryId: 'roleplay',
    );
  }
}

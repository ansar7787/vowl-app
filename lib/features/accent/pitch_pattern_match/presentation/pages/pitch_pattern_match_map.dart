import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class PitchPatternMatchMap extends StatelessWidget {
  const PitchPatternMatchMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'pitchPatternMatch',
      categoryId: 'accent',
    );
  }
}

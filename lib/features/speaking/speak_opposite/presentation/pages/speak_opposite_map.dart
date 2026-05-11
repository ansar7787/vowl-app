import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SpeakOppositeMap extends StatelessWidget {
  const SpeakOppositeMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'speakOpposite',
      categoryId: 'speaking',
    );
  }
}

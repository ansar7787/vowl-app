import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SituationSpeakingMap extends StatelessWidget {
  const SituationSpeakingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'situationSpeaking',
      categoryId: 'speaking',
    );
  }
}

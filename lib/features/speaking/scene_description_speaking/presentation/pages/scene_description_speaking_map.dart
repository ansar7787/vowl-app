import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SceneDescriptionSpeakingMap extends StatelessWidget {
  const SceneDescriptionSpeakingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'sceneDescriptionSpeaking',
      categoryId: 'speaking',
    );
  }
}

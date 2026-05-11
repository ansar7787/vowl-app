import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class EmotionRecognitionMap extends StatelessWidget {
  const EmotionRecognitionMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'emotionRecognition',
      categoryId: 'listening',
    );
  }
}

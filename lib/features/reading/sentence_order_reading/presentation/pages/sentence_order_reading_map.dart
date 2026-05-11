import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SentenceOrderReadingMap extends StatelessWidget {
  const SentenceOrderReadingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'sentenceOrderReading',
      categoryId: 'reading',
    );
  }
}

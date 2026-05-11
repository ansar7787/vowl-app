import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ShortAnswerWritingMap extends StatelessWidget {
  const ShortAnswerWritingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'shortAnswerWriting',
      categoryId: 'writing',
    );
  }
}

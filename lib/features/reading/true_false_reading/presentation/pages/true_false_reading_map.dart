import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class TrueFalseReadingMap extends StatelessWidget {
  const TrueFalseReadingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'trueFalseReading',
      categoryId: 'reading',
    );
  }
}

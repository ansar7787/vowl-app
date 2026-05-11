import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ReadAndAnswerMap extends StatelessWidget {
  const ReadAndAnswerMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'readAndAnswer',
      categoryId: 'reading',
    );
  }
}

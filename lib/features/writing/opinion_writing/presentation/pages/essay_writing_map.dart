import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class EssayWritingMap extends StatelessWidget {
  const EssayWritingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'opinionWriting',
      categoryId: 'writing',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class WordLinkingMap extends StatelessWidget {
  const WordLinkingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'wordLinking',
      categoryId: 'accent',
    );
  }
}

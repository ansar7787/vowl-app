import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SpeakSynonymMap extends StatelessWidget {
  const SpeakSynonymMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'speakSynonym',
      categoryId: 'speaking',
    );
  }
}

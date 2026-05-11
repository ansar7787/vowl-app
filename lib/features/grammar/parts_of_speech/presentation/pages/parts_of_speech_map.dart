import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class PartsOfSpeechMap extends StatelessWidget {
  const PartsOfSpeechMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'partsOfSpeech',
      categoryId: 'grammar',
    );
  }
}

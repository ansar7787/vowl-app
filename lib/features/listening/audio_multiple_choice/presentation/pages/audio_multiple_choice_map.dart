import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class AudioMultipleChoiceMap extends StatelessWidget {
  const AudioMultipleChoiceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'audioMultipleChoice',
      categoryId: 'listening',
    );
  }
}

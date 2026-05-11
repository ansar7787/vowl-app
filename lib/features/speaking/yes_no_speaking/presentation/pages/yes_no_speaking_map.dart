import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class YesNoSpeakingMap extends StatelessWidget {
  const YesNoSpeakingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'yesNoSpeaking',
      categoryId: 'speaking',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SpeakMissingWordMap extends StatelessWidget {
  const SpeakMissingWordMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'speakMissingWord',
      categoryId: 'speaking',
    );
  }
}

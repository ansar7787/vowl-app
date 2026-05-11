import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class AudioFillBlanksMap extends StatelessWidget {
  const AudioFillBlanksMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'audioFillBlanks',
      categoryId: 'listening',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class DirectIndirectSpeechMap extends StatelessWidget {
  const DirectIndirectSpeechMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'directIndirectSpeech',
      categoryId: 'grammar',
    );
  }
}

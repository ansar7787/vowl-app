import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class FastSpeechDecoderMap extends StatelessWidget {
  const FastSpeechDecoderMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'fastSpeechDecoder',
      categoryId: 'listening',
    );
  }
}

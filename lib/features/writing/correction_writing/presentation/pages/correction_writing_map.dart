import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class CorrectionWritingMap extends StatelessWidget {
  const CorrectionWritingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'correctionWriting',
      categoryId: 'writing',
    );
  }
}

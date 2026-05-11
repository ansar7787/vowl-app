import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class AcademicWordMap extends StatelessWidget {
  const AcademicWordMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'academicWord',
      categoryId: 'vocabulary',
    );
  }
}

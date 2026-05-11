import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class DialogueRoleplayMap extends StatelessWidget {
  const DialogueRoleplayMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'dialogueRoleplay',
      categoryId: 'speaking',
    );
  }
}

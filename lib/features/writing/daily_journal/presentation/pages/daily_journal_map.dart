import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class DailyJournalMap extends StatelessWidget {
  const DailyJournalMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'dailyJournal',
      categoryId: 'writing',
    );
  }
}

import 'package:flutter/foundation.dart';

/// Centralized coordinator responsible for calculating daily quest rotations
/// based on exact local calendar dates, preventing shifts during daylight saving transitions.
class DailyQuestManager {
  // Private constructor to prevent unnecessary instance allocations
  const DailyQuestManager._();

  static final DateTime _epoch = DateTime(2024, 1, 1);

  /// Returns the category and level for today's daily quest.
  /// 
  /// Utilizes UTC midnight projections to guarantee DST-safe calendar step calculation.
  /// Returns a Map: {'category': 'reading', 'level': 3}
  static Map<String, dynamic> getDailyQuestConfig() {
    final now = DateTime.now();

    // project local calendar dates to exact UTC midnight boundaries
    final utcNow = DateTime.utc(now.year, now.month, now.day);
    final utcEpoch = DateTime.utc(_epoch.year, _epoch.month, _epoch.day);

    // difference.inDays is now guaranteed to be a precise multiple of 24 hours
    final difference = utcNow.difference(utcEpoch).inDays;

    if (kDebugMode) {
      debugPrint('DailyQuestManager: Current Calendar Day Difference since Epoch: $difference days.');
    }

    // Rotation: Reading -> Writing -> Speaking -> Grammar
    final categoryIndex = difference % 4;
    String category;
    switch (categoryIndex) {
      case 0:
        category = 'reading';
        break;
      case 1:
        category = 'writing';
        break;
      case 2:
        category = 'speaking';
        break;
      default:
        category = 'grammar';
    }

    // Level rotation: 1 to 5
    final level = (difference % 5) + 1;

    return {'category': category, 'level': level};
  }
}

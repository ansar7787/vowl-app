import 'package:flutter/foundation.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

class EnumParser {
  /// Safely parses a string into an enum of type [T].
  /// Returns [defaultValue] if the string is null or not found in the enum.
  static T fromString<T extends Enum>(
    String? value,
    List<T> values, {
    required T defaultValue,
  }) {
    if (value == null || value.isEmpty) return defaultValue;

    try {
      return values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => defaultValue,
      );
    } catch (e) {
      debugPrint(
        'EnumParser error: Could not parse "$value" into enum. Using default: $defaultValue',
      );
      return defaultValue;
    }
  }

  /// Specialized parser for InteractionType to handle legacy/mismatched values
  static InteractionType parseInteractionType(String? value) {
    if (value == null) return InteractionType.choice;

    final normalized = value.toLowerCase();
    switch (normalized) {
      case 'speech':
      case 'speaking':
        return InteractionType.speaking;
      case 'choice':
      case 'multiplechoice':
        return InteractionType.choice;
      case 'writing':
      case 'typing':
        return InteractionType.typing;
      case 'sequence':
      case 'reorder':
        return InteractionType.reorder;
      case 'match':
        return InteractionType.match;
      case 'truefalse':
        return InteractionType.trueFalse;
      case 'text':
        return InteractionType.text;
      default:
        return fromString(
          value,
          InteractionType.values,
          defaultValue: InteractionType.choice,
        );
    }
  }
}

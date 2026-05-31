import 'package:flutter/foundation.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Performance-optimized parsing utility that maps system strings to typed Enums safely.
class EnumParser {
  // Private constructor to enforce static utility boundaries
  const EnumParser._();

  // On-demand lazy-loaded constant list lookup mapping cache
  static final Map<List<dynamic>, Map<String, dynamic>> _cache = {};

  /// Safely parses a string into an enum of type [T].
  /// 
  /// Utilizes lazy static map caches to ensure constant O(1) lookups instead of O(N) list scans.
  /// Returns [defaultValue] if the string is null or not found in the enum.
  static T fromString<T extends Enum>(
    String? value,
    List<T> values, {
    required T defaultValue,
  }) {
    if (value == null || value.trim().isEmpty) return defaultValue;

    final normalized = value.trim().toLowerCase();

    // Dynamically build and cache lookup tables using the canonical constant list pointer
    final lookup = _cache.putIfAbsent(values, () {
      return {
        for (final val in values) val.name.toLowerCase(): val,
      };
    });

    final resolved = lookup[normalized];
    if (resolved is T) return resolved;

    if (kDebugMode) {
      debugPrint('EnumParser Warning: Cannot parse "$value" into target Enum values. Falling back to: $defaultValue');
    }
    return defaultValue;
  }

  /// Specialized parser for InteractionType to handle legacy/mismatched values.
  static InteractionType parseInteractionType(String? value) {
    if (value == null) return InteractionType.choice;

    final normalized = value.trim().toLowerCase();
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

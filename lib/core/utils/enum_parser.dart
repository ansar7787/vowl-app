import 'package:flutter/foundation.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Performance-optimised utility that maps string values to typed enums safely.
///
/// ### O(1) lookup strategy
/// Dart's `List.contains()` is O(n). This parser builds a `Map<String, T>`
/// lookup table from the enum values list on first access and caches it so
/// all subsequent lookups are O(1).
///
/// ### Cache key — why List works here
/// `_cache` uses `List<dynamic>` as a map key. In Dart, `Map` uses `hashCode`
/// and `==` for key comparison. For `List`, both delegate to **object identity**
/// (not structural equality). This means two *different* `List` objects with
/// identical contents would produce cache misses.
///
/// This is safe here because Dart enum `.values` getters always return the
/// **same canonical `List` object** — `identical(QuestType.values, QuestType.values)`
/// is `true`. Callers must always pass `SomeEnum.values` directly; they must
/// never pass a derived or copied list.
class EnumParser {
  const EnumParser._(); // Non-instantiable utility class.

  /// Lookup table keyed by the *same* List object that was passed in.
  /// See class-level doc for why List identity is a safe cache key here.
  static final Map<List<dynamic>, Map<String, dynamic>> _cache = {};

  /// Safely parses [value] into an enum of type [T].
  ///
  /// On first call for a given [values] list, builds and caches an O(1)
  /// lookup table. All subsequent calls for the same enum are O(1).
  ///
  /// Returns [defaultValue] when:
  /// - [value] is `null` or blank.
  /// - No match is found in [values].
  static T fromString<T extends Enum>(
    String? value,
    List<T> values, {
    required T defaultValue,
  }) {
    if (value == null || value.trim().isEmpty) return defaultValue;

    final normalized = value.trim().toLowerCase();

    final lookup = _cache.putIfAbsent(values, () {
      return {for (final v in values) v.name.toLowerCase(): v};
    });

    final resolved = lookup[normalized];
    if (resolved is T) return resolved;

    if (kDebugMode) {
      debugPrint(
        'EnumParser: Cannot parse "$value" into ${T.toString()}. '
        'Falling back to: $defaultValue',
      );
    }
    return defaultValue;
  }

  /// Specialised parser for [InteractionType] that handles legacy and
  /// abbreviated value names used in older Firestore documents.
  ///
  /// Falls back to [fromString] for any value not in the explicit mapping,
  /// keeping the switch focused on known legacy aliases.
  static InteractionType parseInteractionType(String? value) {
    if (value == null) return InteractionType.choice;

    switch (value.trim().toLowerCase()) {
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

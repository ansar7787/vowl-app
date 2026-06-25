import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/modern_path_game_map.dart';

/// Thin delegate to [ModernPathGameMap].
///
/// NOTE (code review): this widget adds no behavior of its own — it exists
/// purely as a forwarding seam. If nothing outside this file depends on the
/// name `PlaceholderGameMap` specifically (e.g. a route table entry, a
/// feature flag swap, or an A/B test), callers can be pointed directly at
/// [ModernPathGameMap] and this file removed. Left intact here since the
/// route/caller wiring isn't part of this file slice and I can't confirm
/// it's safe to delete without seeing where it's referenced.
class PlaceholderGameMap extends StatelessWidget {
  final String gameType;
  final String categoryId;

  const PlaceholderGameMap({
    super.key,
    required this.gameType,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return ModernPathGameMap(gameType: gameType, categoryId: categoryId);
  }
}

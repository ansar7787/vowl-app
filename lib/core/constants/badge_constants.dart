import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorCd7f32 = Color(0xFFCD7F32);
  static const Color color22d3ee = Color(0xFF22D3EE);
  static const Color color3b82f6 = Color(0xFF3B82F6);
}

/// Represents the data model and metadata configuration for a gamified level milestone badge.
@immutable
class BadgeData {
  /// Unique identifier of the badge.
  final String id;

  /// Translation key for the badge's display name (NOT literal display
  /// text - this is a compile-time const class with no BuildContext
  /// available, so it can't resolve translations itself). Resolve with
  /// `context.tr(badge.nameKey)` at the point of display.
  final String nameKey;

  /// Visual Icon representing the trophy/achievement tier.
  final IconData icon;

  /// Primary hex color representing the badge's tier (e.g. Bronze, Silver, Gold).
  final Color color;

  /// The minimum user level milestone required to unlock/claim this badge.
  final int? minLevel;

  const BadgeData({
    required this.id,
    required this.nameKey,
    required this.icon,
    required this.color,
    this.minLevel,
  });
}

/// Namespace for milestone progression and badge metadata constants.
///
/// This class is abstract to prevent instantiation and subclassing.
@immutable
abstract class BadgeConstants {
  // Private constructor to prevent instantiation.
  const BadgeConstants._();

  /// Static collection of all curriculum milestone badges available in the app.
  static const List<BadgeData> badges = [
    BadgeData(
      id: 'bronze_wings',
      nameKey: 'badges.bronze_wings',
      icon: LucideIcons.feather,
      color: _LocalPalette.colorCd7f32,
      minLevel: 10,
    ),
    BadgeData(
      id: 'silver_vanguard',
      nameKey: 'badges.silver_vanguard',
      icon: LucideIcons.shield,
      color: AppColors.slate400,
      minLevel: 25,
    ),
    BadgeData(
      id: 'gold_legend',
      nameKey: 'badges.gold_legend',
      icon: LucideIcons.sparkles,
      color: AppColors.amber400,
      minLevel: 50,
    ),
    BadgeData(
      id: 'platinum_master',
      nameKey: 'badges.platinum_master',
      icon: LucideIcons.trophy,
      color: _LocalPalette.color22d3ee,
      minLevel: 100,
    ),
    BadgeData(
      id: 'emerald_elite',
      nameKey: 'badges.emerald_elite',
      icon: LucideIcons.gem,
      color: AppColors.emerald500,
      minLevel: 200,
    ),
    BadgeData(
      id: 'sapphire_sovereign',
      nameKey: 'badges.sapphire_sovereign',
      icon: LucideIcons.crown,
      color: _LocalPalette.color3b82f6,
      minLevel: 300,
    ),
    BadgeData(
      id: 'ruby_royalty',
      nameKey: 'badges.ruby_royalty',
      icon: LucideIcons.heart,
      color: AppColors.red500,
      minLevel: 400,
    ),
    BadgeData(
      id: 'galactic_grandmaster',
      nameKey: 'badges.galactic_grandmaster',
      icon: LucideIcons.mountain,
      color: AppColors.violet500,
      minLevel: 500,
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Represents the data model and metadata configuration for a gamified level milestone badge.
@immutable
class BadgeData {
  /// Unique identifier of the badge.
  final String id;
  
  /// Display name of the badge.
  final String name;
  
  /// Visual Icon representing the trophy/achievement tier.
  final IconData icon;
  
  /// Primary hex color representing the badge's tier (e.g. Bronze, Silver, Gold).
  final Color color;
  
  /// The minimum user level milestone required to unlock/claim this badge.
  final int? minLevel;

  const BadgeData({
    required this.id,
    required this.name,
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
      name: 'Bronze Wings',
      icon: LucideIcons.feather,
      color: Color(0xFFCD7F32),
      minLevel: 10,
    ),
    BadgeData(
      id: 'silver_vanguard',
      name: 'Silver Vanguard',
      icon: LucideIcons.shield,
      color: Color(0xFF94A3B8),
      minLevel: 25,
    ),
    BadgeData(
      id: 'gold_legend',
      name: 'Gold Legend',
      icon: LucideIcons.sparkles,
      color: Color(0xFFFBBF24),
      minLevel: 50,
    ),
    BadgeData(
      id: 'platinum_master',
      name: 'Platinum Master',
      icon: LucideIcons.trophy,
      color: Color(0xFF22D3EE),
      minLevel: 100,
    ),
    BadgeData(
      id: 'emerald_elite',
      name: 'Emerald Elite',
      icon: LucideIcons.gem,
      color: Color(0xFF10B981),
      minLevel: 200,
    ),
    BadgeData(
      id: 'sapphire_sovereign',
      name: 'Sapphire Sovereign',
      icon: LucideIcons.crown,
      color: Color(0xFF3B82F6),
      minLevel: 300,
    ),
    BadgeData(
      id: 'ruby_royalty',
      name: 'Ruby Royalty',
      icon: LucideIcons.heart,
      color: Color(0xFFEF4444),
      minLevel: 400,
    ),
    BadgeData(
      id: 'galactic_grandmaster',
      name: 'Galactic Grandmaster',
      icon: LucideIcons.mountain,
      color: Color(0xFF8B5CF6),
      minLevel: 500,
    ),
  ];
}

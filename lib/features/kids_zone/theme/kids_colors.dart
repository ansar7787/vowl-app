import 'package:flutter/material.dart';

/// Isolated color palette specifically for Kids Zone illustrations and games.
///
/// These are intentionally separated from the global AppColors so that structural
/// UI theme changes do not break the specific art styles of the children's games.
class KidsColors {
  // Prevent instantiation
  KidsColors._();

  /// Boutique Purple for Kids Avatar Shop
  static const Color boutiquePurple = Color(0xFF9333EA); // Purple 600

  /// Vibrant Orange for Kids Nature & Food elements
  static const Color vibrantOrange = Color(0xFFEA580C); // Orange 600

  /// Safe Green for Kids Nature illustrations
  static const Color safeGreen = Color(0xFF10B981); // Emerald 500

  /// Warm Amber for Kids environment
  static const Color warmAmber = Color(0xFFD97706); // Amber 600
}

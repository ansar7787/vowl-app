import 'package:flutter/material.dart';

/// Centralized colors exclusively for illustrations, badges, and generic non-UI graphics.
///
/// **PSYCHOLOGY & ACCESSIBILITY:**
/// These colors have been subtly adjusted from raw neon hex codes to ensure they render
/// beautifully and clearly on lower-end LCD displays without washing out or causing color-bleeding.
class IllustrationColors {
  // Prevent instantiation
  IllustrationColors._();

  /// Premium Gold for badges and rewards (replaces pure #FFD700 which looks muddy on cheap LCDs)
  static const Color premiumGold = Color(
    0xFFFBBF24,
  ); // Amber 400 - warm and vibrant

  /// Vibrant Pink for confetti and highlights (replaces #EC4899 with better LCD contrast)
  static const Color vibrantPink = Color(0xFFF43F5E); // Rose 500

  /// Bright Blue for sky elements and neutral graphics (replaces #3B82F6 with richer tone)
  static const Color brightBlue = Color(0xFF2563EB); // Blue 600

  /// Warm Orange for secondary badges and graphics
  static const Color warmOrange = Color(0xFFF59E0B); // Amber 500

  /// Rich Purple for generic magical/bonus illustrations
  static const Color richPurple = Color(0xFF8B5CF6); // Violet 500
}

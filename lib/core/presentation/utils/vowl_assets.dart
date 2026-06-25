import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralised, immutable asset registry for Vowl mascots and accessories.
///
/// All public map constants are `const` — zero runtime allocation.
/// All lookup helpers are null-safe and return defined fallback values;
/// they must never throw or return null to prevent UI layout crashes.
@immutable
class VowlAssets {
  // ── Mascot emoji map ────────────────────────────────────────────────────
  static const Map<String, String> mascotMap = {
    'vowl_prime': '🦉',
    'silver_wing': '🦅',
    'crystal_swan': '🦢',
    'neon_parrot': '🦜',
    'night_bat': '🦇',
    'emerald_peacock': '🦚',
    'golden_dragon': '🐉',
    'shadow_wolf': '🐺',
    'frost_penguin': '🐧',
    'cosmic_unicorn': '🦄',
  };

  // ── Vowlbot image assets ─────────────────────────────────────────────────
  static const String vowlbotHappy = 'assets/images/mascot/voxbot_happy.webp';
  static const String vowlbotNeutral =
      'assets/images/mascot/voxbot_neutral.webp';
  static const String vowlbotThinking =
      'assets/images/mascot/voxbot_thinking.webp';
  static const String vowlbotWorried =
      'assets/images/mascot/voxbot_worried.webp';

  // ── Mascot display names ─────────────────────────────────────────────────
  static const Map<String, String> mascotNames = {
    'vowl_prime': 'Vowl Prime',
    'silver_wing': 'Silver Wing',
    'crystal_swan': 'Crystal Swan',
    'neon_parrot': 'Neon Parrot',
    'night_bat': 'Night Oracle Bat',
    'emerald_peacock': 'Emerald Peacock',
    'golden_dragon': 'Golden Dragon',
    'shadow_wolf': 'Shadow Wolf',
    'frost_penguin': 'Frost Penguin',
    'cosmic_unicorn': 'Cosmic Unicorn',
  };

  // ── Mascot lore traits ───────────────────────────────────────────────────
  static const Map<String, String> mascotTraits = {
    'vowl_prime': 'Ancient Sage of Vowels',
    'silver_wing': 'Master of the Swift Skies',
    'crystal_swan': 'Grace of the Pure Syllable',
    'neon_parrot': 'Echo of the Cyber Jungle',
    'night_bat': 'Watcher of the Moonlit Nest',
    'emerald_peacock': 'Keeper of the Vibrant Feathers',
    'golden_dragon': 'Oracle of the Golden Flame',
    'shadow_wolf': 'Spirit of the Silent Forest',
    'frost_penguin': 'Navigator of the Ice Tundra',
    'cosmic_unicorn': 'Traveler of the Infinite Stars',
  };

  // ── Accessory emoji map ──────────────────────────────────────────────────
  static const Map<String, String> accessoryMap = {
    'scholar_cap': '🎓',
    'red_scarf': '🧣',
    'cyber_visor': '🥽',
    'magic_wand': '🪄',
    'golden_bell': '🔔',
    'frost_aura': '❄️',
    'wind_whistler': '🌪️',
    'phoenix_wings': '🔥',
    'dragon_gem': '💎',
    'golden_crown': '👑',
    'starlight_aura': '✨',
    'mystic_amulet': '🧿',
  };

  // ── Accessory display names ──────────────────────────────────────────────
  static const Map<String, String> accessoryNames = {
    'scholar_cap': "Scholar's Cap",
    'red_scarf': 'Crimson Scarf',
    'cyber_visor': 'Cyber Visor',
    'magic_wand': 'Arcane Wand',
    'golden_bell': 'Golden Bell',
    'frost_aura': 'Frost Aura',
    'wind_whistler': 'Cyclone Aura',
    'phoenix_wings': 'Phoenix Fire',
    'dragon_gem': 'Dragon Gem',
    'golden_crown': 'Royal Crown',
    'starlight_aura': 'Starlight Aura',
    'mystic_amulet': 'Mystic Amulet',
  };

  // ── Accessory prices (Vowl Coins) ────────────────────────────────────────
  static const Map<String, int> accessoryPrices = {
    'scholar_cap': 1500,
    'red_scarf': 2500,
    'cyber_visor': 4000,
    'magic_wand': 6000,
    'golden_bell': 8500,
    'frost_aura': 12000,
    'wind_whistler': 15000,
    'phoenix_wings': 25000,
    'dragon_gem': 40000,
    'golden_crown': 65000,
    'starlight_aura': 85000,
    'mystic_amulet': 100000,
  };

  // ── Item theme colours ───────────────────────────────────────────────────
  static const Map<String, Color> itemColors = {
    // Mascots
    'vowl_prime': Color(0xFF3B82F6),
    'silver_wing': Color(0xFF64748B),
    'crystal_swan': Color(0xFFE0F2FE),
    'neon_parrot': Color(0xFFEC4899),
    'night_bat': Color(0xFF6366F1),
    'emerald_peacock': Color(0xFF10B981),
    'golden_dragon': Color(0xFFF59E0B),
    'shadow_wolf': Color(0xFF334155),
    'frost_penguin': Color(0xFF06B6D4),
    'cosmic_unicorn': Color(0xFF8B5CF6),
    // Accessories
    'scholar_cap': Color(0xFF4F46E5),
    'red_scarf': Color(0xFFEF4444),
    'cyber_visor': Color(0xFF14B8A6),
    'magic_wand': Color(0xFFD946EF),
    'golden_bell': Color(0xFFFBBF24),
    'frost_aura': Color(0xFF06B6D4),
    'wind_whistler': Color(0xFF64748B),
    'phoenix_wings': Color(0xFFF97316),
    'dragon_gem': Color(0xFFEC4899),
    'golden_crown': Color(0xFFF59E0B),
    'starlight_aura': Color(0xFFFEF08A),
    'mystic_amulet': Color(0xFF8B5CF6),
  };

  // =========================================================================
  // Null-safe lookup helpers — never return null, never throw.
  // =========================================================================

  /// Resolves the theme colour for a mascot or accessory [key].
  static Color getItemColor(
    String key, {
    Color fallback = const Color(0xFF2563EB),
  }) => itemColors[key] ?? fallback;

  /// Resolves the emoji for a mascot [key].
  static String getMascotEmoji(String key, {String fallback = '🦉'}) =>
      mascotMap[key] ?? fallback;

  /// Resolves the display name for a mascot [key].
  static String getMascotName(String key, {String fallback = 'Companion'}) =>
      mascotNames[key] ?? fallback;

  /// Resolves the lore trait for a mascot [key].
  static String getMascotTrait(
    String key, {
    String fallback = 'Ancient Spirit of Vowl',
  }) => mascotTraits[key] ?? fallback;

  /// Resolves the emoji for an accessory [key].
  static String getAccessoryEmoji(String key, {String fallback = '✨'}) =>
      accessoryMap[key] ?? fallback;

  /// Resolves the display name for an accessory [key].
  static String getAccessoryName(String key, {String fallback = 'Item'}) =>
      accessoryNames[key] ?? fallback;

  /// Resolves the Vowl Coin price for an accessory [key].
  static int getAccessoryPrice(String key, {int fallback = 0}) =>
      accessoryPrices[key] ?? fallback;
}

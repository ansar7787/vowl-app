import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colore0f2fe = Color(0xFFE0F2FE);
  static const Color colorec4899 = Color(0xFFEC4899);
  static const Color color6366f1 = Color(0xFF6366F1);
  static const Color color06b6d4 = Color(0xFF06B6D4);
  static const Color color4f46e5 = Color(0xFF4F46E5);
  static const Color colord946ef = Color(0xFFD946EF);
  static const Color colorf97316 = Color(0xFFF97316);
  static const Color colorfef08a = Color(0xFFFEF08A);
}

/// Visual equipment slot for positioning accessories on buddy avatars.
enum AccessorySlot {
  /// Sits atop the head (e.g. caps, crowns, visors).
  head,

  /// Sits around the lower neck/chest (e.g. scarves, bells).
  neck,

  /// Ambient background particles or energy aura behind the buddy.
  aura,

  /// Equipment pin/badge held or floating on the lower flank (e.g. wands, gems, amulets).
  charm,
}

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

  // ── Vowly image assets ─────────────────────────────────────────────────
  static const String vowlyHappy = 'assets/images/mascot/vowly_happy.webp';
  static const String vowlyNeutral = 'assets/images/mascot/vowly_neutral.webp';
  static const String vowlyThinking =
      'assets/images/mascot/vowly_thinking.webp';
  static const String vowlyWorried = 'assets/images/mascot/vowly_worried.webp';

  // ── Mascot display names (Friendly, memorable 1-word character names) ──
  static const Map<String, String> mascotNames = {
    'vowl_prime': 'Barnaby',
    'silver_wing': 'Zephyr',
    'crystal_swan': 'Luna',
    'neon_parrot': 'Echo',
    'night_bat': 'Nyx',
    'emerald_peacock': 'Beau',
    'golden_dragon': 'Blaze',
    'shadow_wolf': 'Shadow',
    'frost_penguin': 'Pippin',
    'cosmic_unicorn': 'Nova',
  };

  // ── Mascot learning traits ───────────────────────────────────────────────
  static const Map<String, String> mascotTraits = {
    'vowl_prime': 'Wise Guide of English',
    'silver_wing': 'Swift Master of Reading',
    'crystal_swan': 'Grace of Pure Grammar',
    'neon_parrot': 'Echo of Fluent Speech',
    'night_bat': 'Guardian of Night Study',
    'emerald_peacock': 'Keeper of Rich Vocabulary',
    'golden_dragon': 'Spark of Bold Confidence',
    'shadow_wolf': 'Spirit of Calm Focus',
    'frost_penguin': 'Champion of Daily Streaks',
    'cosmic_unicorn': 'Explorer of Boundless Words',
  };

  // ── Mascot prices (Vowl Coins) ────────────────────────────────────────
  static const Map<String, int> mascotPrices = {
    'vowl_prime': 0,
    'silver_wing': 0,
    'crystal_swan': 0,
    'neon_parrot': 0,
    'night_bat': 5000,
    'emerald_peacock': 10000,
    'golden_dragon': 20000,
    'shadow_wolf': 35000,
    'frost_penguin': 50000,
    'cosmic_unicorn': 75000,
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

  // ── Accessory slot classification ────────────────────────────────────────
  static const Map<String, AccessorySlot> accessorySlots = {
    'scholar_cap': AccessorySlot.head,
    'red_scarf': AccessorySlot.neck,
    'cyber_visor': AccessorySlot.head,
    'magic_wand': AccessorySlot.charm,
    'golden_bell': AccessorySlot.neck,
    'frost_aura': AccessorySlot.aura,
    'wind_whistler': AccessorySlot.aura,
    'phoenix_wings': AccessorySlot.aura,
    'dragon_gem': AccessorySlot.charm,
    'golden_crown': AccessorySlot.head,
    'starlight_aura': AccessorySlot.aura,
    'mystic_amulet': AccessorySlot.charm,
  };

  /// Resolves the visual equipment slot for an accessory [key].
  static AccessorySlot getAccessorySlot(String key) =>
      accessorySlots[key] ?? AccessorySlot.charm;

  // ── Item theme colours ───────────────────────────────────────────────────
  static const Map<String, Color> itemColors = {
    // Mascots
    'vowl_prime': AppColors.blue500,
    'silver_wing': AppColors.slate500,
    'crystal_swan': _LocalPalette.colore0f2fe,
    'neon_parrot': _LocalPalette.colorec4899,
    'night_bat': _LocalPalette.color6366f1,
    'emerald_peacock': AppColors.emerald500,
    'golden_dragon': AppColors.amber500,
    'shadow_wolf': AppColors.slate700,
    'frost_penguin': _LocalPalette.color06b6d4,
    'cosmic_unicorn': AppColors.violet500,
    // Accessories
    'scholar_cap': _LocalPalette.color4f46e5,
    'red_scarf': AppColors.red500,
    'cyber_visor': AppColors.teal500,
    'magic_wand': _LocalPalette.colord946ef,
    'golden_bell': AppColors.amber400,
    'frost_aura': _LocalPalette.color06b6d4,
    'wind_whistler': AppColors.slate500,
    'phoenix_wings': _LocalPalette.colorf97316,
    'dragon_gem': _LocalPalette.colorec4899,
    'golden_crown': AppColors.amber500,
    'starlight_aura': _LocalPalette.colorfef08a,
    'mystic_amulet': AppColors.violet500,
  };

  // =========================================================================
  // Null-safe lookup helpers — never return null, never throw.
  // =========================================================================

  /// Resolves the theme colour for a mascot or accessory [key].
  static Color getItemColor(
    String key, {
    Color fallback = AppColors.indigo500,
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

  /// Resolves the Vowl Coin price for a mascot [key].
  static int getMascotPrice(String key, {int fallback = 5000}) =>
      mascotPrices[key] ?? fallback;

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

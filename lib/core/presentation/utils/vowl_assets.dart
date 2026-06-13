import 'package:flutter/material.dart';

/// Centralized asset registry and item configurations for Vowl.
/// 
/// Provides unified null-safe accessors for mascots, accessories, prices,
/// and theme colors to prevent layout runtime exceptions.
class VowlAssets {
  // Mascots for Vowl Users
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

  // Vowlbot Assets (Dynamic Branding)
  static const String vowlbotHappy = 'assets/images/mascot/voxbot_happy.webp';
  static const String vowlbotNeutral = 'assets/images/mascot/voxbot_neutral.webp';
  static const String vowlbotThinking = 'assets/images/mascot/voxbot_thinking.webp';
  static const String vowlbotWorried = 'assets/images/mascot/voxbot_worried.webp';

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

  // Accessories for Vowl (Purchasable with Vowl Coins)
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

  static const Map<String, String> accessoryNames = {
    'scholar_cap': 'Scholar\'s Cap',
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

  static const Map<String, Color> itemColors = {
    // Mascots
    'vowl_prime': Color(0xFF3B82F6), // Premium Blue
    'silver_wing': Color(0xFF64748B), // Slate Grey
    'crystal_swan': Color(0xFFE0F2FE), // Ice Blue
    'neon_parrot': Color(0xFFEC4899), // Neon Pink
    'night_bat': Color(0xFF6366F1), // Indigo
    'emerald_peacock': Color(0xFF10B981), // Emerald
    'golden_dragon': Color(0xFFF59E0B), // Gold
    'shadow_wolf': Color(0xFF334155), // Dark Slate
    'frost_penguin': Color(0xFF06B6D4), // Frost Cyan
    'cosmic_unicorn': Color(0xFF8B5CF6), // Deep Purple
    // Accessories
    'scholar_cap': Color(0xFF4F46E5), // Scholar Indigo
    'red_scarf': Color(0xFFEF4444), // Crimson Red
    'cyber_visor': Color(0xFF14B8A6), // Cyber Teal
    'magic_wand': Color(0xFFD946EF), // Magic Fuchsia
    'golden_bell': Color(0xFFFBBF24), // Bell Gold
    'frost_aura': Color(0xFF06B6D4), // Frost Cyan
    'wind_whistler': Color(0xFF64748B), // Storm Grey
    'phoenix_wings': Color(0xFFF97316), // Phoenix Orange
    'dragon_gem': Color(0xFFEC4899), // Dragon Pink
    'golden_crown': Color(0xFFF59E0B), // Royal Amber
    'starlight_aura': Color(0xFFFEF08A), // Starlight Yellow
    'mystic_amulet': Color(0xFF8B5CF6), // Mystic Purple
  };

  // ============================================================
  // Null-Safe Lookup Helpers (Prevents UI runtime crash sweeps)
  // ============================================================

  /// Safely resolves a color mapping for a mascot or accessory.
  static Color getItemColor(String key, {Color fallback = const Color(0xFF2563EB)}) {
    return itemColors[key] ?? fallback;
  }

  /// Safely resolves the emoji visual representation for a mascot.
  static String getMascotEmoji(String key, {String fallback = '🦉'}) {
    return mascotMap[key] ?? fallback;
  }

  /// Safely resolves the display name for a mascot.
  static String getMascotName(String key, {String fallback = 'Companion'}) {
    return mascotNames[key] ?? fallback;
  }

  /// Safely resolves the lore trait description for a mascot.
  static String getMascotTrait(String key, {String fallback = 'Ancient Spirit of Vowl'}) {
    return mascotTraits[key] ?? fallback;
  }

  /// Safely resolves the emoji visual representation for an accessory.
  static String getAccessoryEmoji(String key, {String fallback = '✨'}) {
    return accessoryMap[key] ?? fallback;
  }

  /// Safely resolves the display name for an accessory.
  static String getAccessoryName(String key, {String fallback = 'Item'}) {
    return accessoryNames[key] ?? fallback;
  }

  /// Safely resolves the price tag in Vowl coins for an accessory.
  static int getAccessoryPrice(String key, {int fallback = 0}) {
    return accessoryPrices[key] ?? fallback;
  }
}

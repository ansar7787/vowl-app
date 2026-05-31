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
    'night_oracle': '🔮',
    'phantom_hoot': '🪶',
    'golden_talon': '🏅',
    'moss_feather': '🍃',
  };

  // Vowlbot Assets (Dynamic Branding)
  static const String vowlbotHappy = 'assets/images/mascot/voxbot_happy.webp';
  static const String vowlbotNeutral = 'assets/images/mascot/voxbot_neutral.webp';
  static const String vowlbotThinking = 'assets/images/mascot/voxbot_thinking.webp';
  static const String vowlbotWorried = 'assets/images/mascot/voxbot_worried.webp';

  static const Map<String, String> mascotNames = {
    'vowl_prime': 'Vowl Prime',
    'silver_wing': 'Silver Wing',
    'night_oracle': 'Night Oracle',
    'phantom_hoot': 'Phantom Hoot',
    'golden_talon': 'Golden Talon',
    'moss_feather': 'Moss Feather',
  };

  static const Map<String, String> mascotTraits = {
    'vowl_prime': 'Ancient Sage of Vowels',
    'silver_wing': 'Master of the Swift Skies',
    'night_oracle': 'Watcher of the Moonlit Nest',
    'phantom_hoot': 'Spirit of the Silent Flight',
    'golden_talon': 'Oracle of the Golden Song',
    'moss_feather': 'Keeper of the Emerald Leaves',
  };

  // Accessories for Vowl (Purchasable with Vowl Coins)
  static const Map<String, String> accessoryMap = {
    'scholar_cap': '🎓',
    'frost_aura': '❄️',
    'night_vision': '🕶️',
    'phoenix_wings': '🔥',
    'dragon_heart': '💎',
    'wind_whistler': '🌬️',
  };

  static const Map<String, String> accessoryNames = {
    'scholar_cap': 'Scholar\'s Cap',
    'frost_aura': 'Frost Aura',
    'night_vision': 'Night Vision',
    'phoenix_wings': 'Phoenix Wings',
    'dragon_heart': 'Dragon Heart',
    'wind_whistler': 'Wind Whistler',
  };

  static const Map<String, int> accessoryPrices = {
    'scholar_cap': 250,
    'frost_aura': 1200,
    'night_vision': 100,
    'phoenix_wings': 3500,
    'dragon_heart': 5000,
    'wind_whistler': 1800,
  };

  static const Map<String, Color> itemColors = {
    'vowl_prime': Color(0xFF3B82F6), // Premium Blue
    'silver_wing': Color(0xFF64748B), // Slate Grey
    'night_oracle': Color(0xFF6366F1), // Indigo
    'phantom_hoot': Color(0xFF10B981), // Emerald
    'golden_talon': Color(0xFFF59E0B), // Amber
    'moss_feather': Color(0xFF10B981), // Forest Green
    'scholar_cap': Color(0xFF4F46E5), // Scholar Indigo
    'frost_aura': Color(0xFF06B6D4), // Frost Cyan
    'night_vision': Color(0xFF475569), // Dark Vision Slate
    'phoenix_wings': Color(0xFFEF4444), // Phoenix Red
    'dragon_heart': Color(0xFFEC4899), // Dragon Pink
    'wind_whistler': Color(0xFF0EA5E9), // Sky Blue
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

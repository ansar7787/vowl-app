import 'package:flutter/material.dart';

class KidsAssets {
  static const Map<String, List<String>> stickerMap = {
    'alphabet': ['🔠', '🅰️', '🔡', '🎓'],
    'numbers': ['🔢', '1️⃣', '💯', '🏆'],
    'colors': ['🎨', '🌈', '🖍️', '🖌️'],
    'shapes': ['📐', '🔺', '💠', '💎'],
    'animals': ['🦁', '🐯', '🐘', '🐲'],
    'fruits': ['🍎', '🍓', '🍇', '🍍'],
    'family': ['👪', '🏠', '💖', '👨‍👩‍👧‍👦'],
    'school': ['🎒', '📚', '✏️', '🏅'],
    'verbs': ['🏃', '🤸', '🏊', '⚡'],
    'routine': ['🛁', '🦷', '👕', '🌟'],
    'emotions': ['😊', '🤩', '💖', '🌈'],
    'prepositions': ['📦', '📥', '📍', '🗺️'],
    'phonics': ['🔊', '👂', '🗣️', '📢'],
    'time': ['⏰', '📅', '⏳', '🏁'],
    'opposites': ['⚖️', '🌓', '🔄', '🎯'],
    'day_night': ['🌓', '☀️', '🌙', '🌌'],
    'nature': ['🌿', '🌳', '🏔️', '🌋'],
    'home_kids': ['🏠', '🛋️', '🛌', '🏰'],
    'food_kids': ['🍕', '🍔', '🍰', '🍳'],
    'transport': ['🚀', '🚁', '🚢', '🛸'],
    'body_parts': ['👀', '👂', '👃', '💪'],
    'clothing': ['👕', '👖', '👟', '🎩'],
  };

  static const Map<String, String> accessoryMap = {
    'cape_red': '🦸',
    'shades_cool': '🕶️',
    'wand_magic': '🪄',
    'bell_gold': '🔔',
    'hat_explorer': '🤠',
    'wings_star': '🦋',
    'crown_royal': '👑',
    'ribbon_pink': '🎀',
    'glasses_nerd': '🤓',
    'shield_hero': '🛡️',
    'balloon_red': '🎈',
    'aura_sparkle': '✨',
    'rocket_pack': '🚀',
    'dragon_tail': '🐲',
    'mask_hero': '🎭',
    'goggles_pilot': '🥽',
    'hat_chef': '👨‍🍳',
    'alien_antenna': '👽',
    'ninja_band': '🥷',
  };

  static final List<Map<String, dynamic>> shopItems = [
    {
      'id': 'cape_red',
      'name': 'Tiny Cape',
      'price': 50,
      'icon': '🦸',
      'color': const Color(0xFFEF4444),
      'category': 'Clothes',
    },
    {
      'id': 'shades_cool',
      'name': 'Cool Shades',
      'price': 30,
      'icon': '🕶️',
      'color': const Color(0xFF3B82F6),
      'category': 'Clothes',
    },
    {
      'id': 'wand_magic',
      'name': 'Magic Wand',
      'price': 100,
      'icon': '🪄',
      'color': const Color(0xFFA855F7),
      'category': 'Magic',
    },
    {
      'id': 'bell_gold',
      'name': 'Golden Bell',
      'price': 200,
      'icon': '🔔',
      'color': const Color(0xFFF59E0B),
      'category': 'Toys',
    },
    {
      'id': 'hat_explorer',
      'name': 'Explorer Hat',
      'price': 80,
      'icon': '🤠',
      'color': const Color(0xFF8B4513),
      'category': 'Clothes',
    },
    {
      'id': 'wings_star',
      'name': 'Star Wings',
      'price': 500,
      'icon': '🦋',
      'color': const Color(0xFF06B6D4),
      'category': 'Magic',
    },
    {
      'id': 'crown_royal',
      'name': 'Royal Crown',
      'price': 1000,
      'icon': '👑',
      'color': const Color(0xFFFFD700),
      'category': 'Clothes',
    },
    {
      'id': 'ribbon_pink',
      'name': 'Pink Ribbon',
      'price': 150,
      'icon': '🎀',
      'color': const Color(0xFFEC4899),
      'category': 'Clothes',
    },
    {
      'id': 'glasses_nerd',
      'name': 'Smarty Lens',
      'price': 250,
      'icon': '🤓',
      'color': const Color(0xFF6366F1),
      'category': 'Clothes',
    },
    {
      'id': 'shield_hero',
      'name': 'Hero Shield',
      'price': 750,
      'icon': '🛡️',
      'color': const Color(0xFF3B82F6),
      'category': 'Toys',
    },
    {
      'id': 'balloon_red',
      'name': 'Party Balloon',
      'price': 100,
      'icon': '🎈',
      'color': const Color(0xFFEF4444),
      'category': 'Toys',
    },
    {
      'id': 'aura_sparkle',
      'name': 'Magic Sparkles',
      'price': 1500,
      'icon': '✨',
      'color': const Color(0xFFF59E0B),
      'category': 'Magic',
    },
    {
      'id': 'rocket_pack',
      'name': 'Jetpack 3000',
      'price': 2500,
      'icon': '🚀',
      'color': const Color(0xFF10B981),
      'category': 'Magic',
    },
    {
      'id': 'dragon_tail',
      'name': 'Dragon Tail',
      'price': 3000,
      'icon': '🐲',
      'color': const Color(0xFF059669),
      'category': 'Magic',
    },
    {
      'id': 'mask_hero',
      'name': 'Hero Mask',
      'price': 120,
      'icon': '🎭',
      'color': const Color(0xFFF43F5E),
      'category': 'Clothes',
    },
    {
      'id': 'goggles_pilot',
      'name': 'Sky Goggles',
      'price': 350,
      'icon': '🥽',
      'color': const Color(0xFF0EA5E9),
      'category': 'Clothes',
    },
    {
      'id': 'hat_chef',
      'name': 'Star Chef',
      'price': 220,
      'icon': '👨‍🍳',
      'color': const Color(0xFFF97316),
      'category': 'Clothes',
    },
    {
      'id': 'alien_antenna',
      'name': 'Space Link',
      'price': 600,
      'icon': '👽',
      'color': const Color(0xFF22C55E),
      'category': 'Magic',
    },
    {
      'id': 'ninja_band',
      'name': 'Stealth Wrap',
      'price': 400,
      'icon': '🥷',
      'color': const Color(0xFF64748B),
      'category': 'Clothes',
    },
    // NEW BUDDIES CATEGORY
    {
      'id': 'mascot_unicorn',
      'name': 'Magic Unicorn',
      'price': 5000,
      'icon': '🦄',
      'color': const Color(0xFFF472B6),
      'category': 'Buddies',
    },
    {
      'id': 'mascot_robot',
      'name': 'Sparky Robot',
      'price': 3500,
      'icon': '🤖',
      'color': const Color(0xFF60A5FA),
      'category': 'Buddies',
    },
    {
      'id': 'mascot_lion',
      'name': 'Leo the Brave',
      'price': 4000,
      'icon': '🦁',
      'color': const Color(0xFFFBBF24),
      'category': 'Buddies',
    },
  ];

  static const Map<String, String> mascotMap = {
    'owly': '🦉',
    'foxie': '🦊',
    'dino': '🦖',
    'mascot_unicorn': '🦄',
    'mascot_robot': '🤖',
    'mascot_lion': '🦁',
  };

  static String getStickerEmoji(String stickerId) {
    // stickerId formats: "sticker_alphabet" (standard/lvl10) or "alphabet_sticker_50" etc.
    if (stickerId.contains('_sticker_')) {
      final parts = stickerId.split('_sticker_');
      final category = parts[0];
      final level = int.tryParse(parts[1]) ?? 10;
      final emojis = stickerMap[category];
      if (emojis == null) return '⭐';

      if (level >= 200) return emojis[3];
      if (level >= 100) return emojis[2];
      if (level >= 50) return emojis[1];
      return emojis[0];
    }

    final category = stickerId.replaceFirst('sticker_', '');
    return stickerMap[category]?[0] ?? '⭐';
  }
}

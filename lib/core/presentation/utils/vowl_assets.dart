import 'package:flutter/material.dart';

class VowlAssets {
  // Mascots for Vowl Users
  static const Map<String, String> mascotMap = {
    'vowl_prime': '🦉',
    'silver_wing': '🦅',
    'night_oracle': '🌙',
    'phantom_hoot': '👻',
    'golden_talon': '✨',
    'moss_feather': '🌿',
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
    'vowl_prime': Colors.blueAccent,
    'silver_wing': Colors.blueGrey,
    'night_oracle': Colors.indigoAccent,
    'phantom_hoot': Color(0xFF00FF41), 
    'golden_talon': Colors.amberAccent,
    'moss_feather': Color(0xFF2ECC71),
    'scholar_cap': Colors.indigo,
    'frost_aura': Colors.lightBlueAccent,
    'night_vision': Colors.blueGrey,
    'phoenix_wings': Colors.orangeAccent,
    'dragon_heart': Colors.redAccent,
    'wind_whistler': Colors.cyanAccent,
  };
}

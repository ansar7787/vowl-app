import 'package:flutter/material.dart';

/// Semantic topic icon resolver mapping category emojis and topic strings to
/// clean, unified Material icons, avoiding OEM emoji fragmentation on budget and older devices.
class TopicIconHelper {
  TopicIconHelper._();

  /// Resolves an [IconData] representing the given [emoji] and/or [categoryName].
  static IconData getIcon(String? emoji, [String? categoryName]) {
    final combined =
        '${emoji ?? ''} ${categoryName ?? ''}'.trim().toLowerCase();
    if (combined.isEmpty) return Icons.category_rounded;

    if (combined.contains('🔥') ||
        combined.contains('fire') ||
        combined.contains('heat') ||
        combined.contains('hot') ||
        combined.contains('boil') ||
        combined.contains('scorch')) {
      return Icons.whatshot_rounded;
    }
    if (combined.contains('❄️') ||
        combined.contains('🧊') ||
        combined.contains('cold') ||
        combined.contains('ice') ||
        combined.contains('freeze') ||
        combined.contains('chill')) {
      return Icons.ac_unit_rounded;
    }
    if (combined.contains('⚡') ||
        combined.contains('electric') ||
        combined.contains('energy') ||
        combined.contains('power') ||
        combined.contains('speed')) {
      return Icons.bolt_rounded;
    }
    if (combined.contains('🌟') ||
        combined.contains('✨') ||
        combined.contains('⭐') ||
        combined.contains('star') ||
        combined.contains('bright')) {
      return Icons.auto_awesome_rounded;
    }
    if (combined.contains('🌱') ||
        combined.contains('🌿') ||
        combined.contains('🍃') ||
        combined.contains('plant') ||
        combined.contains('nature') ||
        combined.contains('eco')) {
      return Icons.eco_rounded;
    }
    if (combined.contains('🌊') ||
        combined.contains('💧') ||
        combined.contains('water') ||
        combined.contains('ocean') ||
        combined.contains('sea') ||
        combined.contains('rain')) {
      return Icons.water_drop_rounded;
    }
    if (combined.contains('☀️') ||
        combined.contains('🌞') ||
        combined.contains('sun') ||
        combined.contains('light') ||
        combined.contains('day')) {
      return Icons.wb_sunny_rounded;
    }
    if (combined.contains('🧠') ||
        combined.contains('mind') ||
        combined.contains('thought') ||
        combined.contains('logic') ||
        combined.contains('brain') ||
        combined.contains('psych')) {
      return Icons.psychology_rounded;
    }
    if (combined.contains('❤️') ||
        combined.contains('💖') ||
        combined.contains('heart') ||
        combined.contains('feel') ||
        combined.contains('love') ||
        combined.contains('emotion')) {
      return Icons.favorite_rounded;
    }
    if (combined.contains('💼') ||
        combined.contains('work') ||
        combined.contains('business') ||
        combined.contains('office') ||
        combined.contains('career') ||
        combined.contains('job')) {
      return Icons.work_outline_rounded;
    }
    if (combined.contains('🎓') ||
        combined.contains('📚') ||
        combined.contains('study') ||
        combined.contains('school') ||
        combined.contains('academic') ||
        combined.contains('learn')) {
      return Icons.school_rounded;
    }
    if (combined.contains('🏥') ||
        combined.contains('💊') ||
        combined.contains('health') ||
        combined.contains('medical') ||
        combined.contains('doctor') ||
        combined.contains('cure')) {
      return Icons.medical_services_rounded;
    }
    if (combined.contains('✈️') ||
        combined.contains('🚀') ||
        combined.contains('travel') ||
        combined.contains('fly') ||
        combined.contains('journey') ||
        combined.contains('trip')) {
      return Icons.flight_takeoff_rounded;
    }
    if (combined.contains('🍔') ||
        combined.contains('🍎') ||
        combined.contains('food') ||
        combined.contains('eat') ||
        combined.contains('diet') ||
        combined.contains('cook')) {
      return Icons.restaurant_rounded;
    }
    if (combined.contains('🎵') ||
        combined.contains('🎶') ||
        combined.contains('music') ||
        combined.contains('sound') ||
        combined.contains('audio') ||
        combined.contains('song')) {
      return Icons.music_note_rounded;
    }
    if (combined.contains('🎨') ||
        combined.contains('art') ||
        combined.contains('design') ||
        combined.contains('color') ||
        combined.contains('paint')) {
      return Icons.palette_rounded;
    }
    if (combined.contains('🏠') ||
        combined.contains('home') ||
        combined.contains('house') ||
        combined.contains('room')) {
      return Icons.home_rounded;
    }
    if (combined.contains('🌍') ||
        combined.contains('🌎') ||
        combined.contains('earth') ||
        combined.contains('world') ||
        combined.contains('global')) {
      return Icons.public_rounded;
    }
    if (combined.contains('⚖️') ||
        combined.contains('law') ||
        combined.contains('legal') ||
        combined.contains('court') ||
        combined.contains('justice')) {
      return Icons.gavel_rounded;
    }
    if (combined.contains('🏷️') ||
        combined.contains('🔖') ||
        combined.contains('tag') ||
        combined.contains('label') ||
        combined.contains('topic')) {
      return Icons.label_rounded;
    }
    if (combined.contains('🛡️') ||
        combined.contains('shield') ||
        combined.contains('protect') ||
        combined.contains('defense') ||
        combined.contains('safety')) {
      return Icons.shield_rounded;
    }
    if (combined.contains('🔍') ||
        combined.contains('🔎') ||
        combined.contains('search') ||
        combined.contains('find') ||
        combined.contains('clue')) {
      return Icons.search_rounded;
    }
    if (combined.contains('💬') ||
        combined.contains('🗣️') ||
        combined.contains('speech') ||
        combined.contains('talk') ||
        combined.contains('dialogue') ||
        combined.contains('chat')) {
      return Icons.chat_bubble_outline_rounded;
    }

    return Icons.category_rounded;
  }
}

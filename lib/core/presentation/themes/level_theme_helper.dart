import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

enum GameCategory {
  speaking,
  listening,
  reading,
  writing,
  grammar,
  vocabulary,
  accent,
  roleplay,
  eliteMastery,
}

class ThemeResult {
  final Color primaryColor;
  final Color accentColor;
  final List<Color> backgroundColors;
  final String title;
  final IconData icon;
  final GameCategory category;

  const ThemeResult({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColors,
    required this.title,
    required this.icon,
    required this.category,
  });
}

class LevelThemeHelper {
  /// Known category names mapped for fast set operations
  static const _categoryNames = {
    'vocabulary',
    'grammar',
    'listening',
    'reading',
    'writing',
    'speaking',
    'accent',
    'roleplay',
    'elitemastery',
  };

  /// Core Category Base Colors (Mathematically Balanced for Distinction)
  static Color getCategoryBaseColor(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'speaking':
        return const Color(0xFFF44336); // Pure Red
      case 'writing':
        return const Color(0xFFFF9800); // Pure Orange
      case 'vocabulary':
        return const Color(0xFF673AB7); // Pure Deep Purple (Best Color)
      case 'reading':
        return const Color(0xFF4CAF50); // Pure Green
      case 'accent':
        return const Color(0xFF00BCD4); // Pure Cyan
      case 'grammar':
        return const Color(0xFF2196F3); // Pure Blue
      case 'listening':
        return const Color(0xFFE91E63); // Pure Pink
      case 'roleplay':
        return const Color(0xFF8BC34A); // Pure Lime
      case 'elitemastery':
        return const Color(0xFFFFD700); // Pure Gold
      default:
        return const Color(0xFF2196F3); // Default to Blue
    }
  }

  /// Map categories to readable, capitalized Titles
  static String _getCategoryTitle(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'speaking':
        return 'Speaking';
      case 'listening':
        return 'Listening';
      case 'reading':
        return 'Reading';
      case 'writing':
        return 'Writing';
      case 'grammar':
        return 'Grammar';
      case 'vocabulary':
        return 'Vocabulary';
      case 'accent':
        return 'Accent';
      case 'roleplay':
        return 'Roleplay';
      case 'elitemastery':
        return 'Elite Mastery';
      default:
        return category;
    }
  }

  /// Category icons
  static IconData _getCategoryIcon(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'speaking':
        return Icons.mic_rounded;
      case 'reading':
        return Icons.auto_stories_rounded;
      case 'writing':
        return Icons.edit_note_rounded;
      case 'grammar':
        return Icons.spellcheck_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'accent':
        return Icons.graphic_eq_rounded;
      case 'roleplay':
        return Icons.theater_comedy_rounded;
      case 'elitemastery':
        return Icons.workspace_premium_rounded;
      case 'vocabulary':
        return Icons.abc_rounded;
      default:
        return Icons.gamepad_rounded;
    }
  }

  static Color getKidsGameColor(String gameType) {
    switch (gameType) {
      case 'alphabet':
        return const Color(0xFFEF4444);
      case 'numbers':
        return const Color(0xFF3B82F6);
      case 'colors':
        return const Color(0xFFF59E0B);
      case 'shapes':
        return const Color(0xFF10B981);
      case 'animals':
        return const Color(0xFF8B5CF6);
      case 'fruits':
        return const Color(0xFFEC4899);
      case 'family':
        return const Color(0xFFF43F5E);
      case 'school':
        return const Color(0xFFEAB308);
      case 'verbs':
        return const Color(0xFF6366F1);
      case 'routine':
        return const Color(0xFFF97316);
      case 'emotions':
        return const Color(0xFF06B6D4);
      case 'prepositions':
        return const Color(0xFF64748B);
      case 'phonics':
        return const Color(0xFFD946EF);
      case 'jumble':
        return const Color(0xFF9333EA);
      case 'time':
        return const Color(0xFF84CC16);
      case 'opposites':
        return const Color(0xFF14B8A6);
      case 'day_night':
      case 'daynight':
        return const Color(0xFF1E3A8A);
      case 'nature':
        return const Color(0xFF22C55E);
      case 'home':
        return const Color(0xFFCA8A04);
      case 'food':
        return const Color(0xFFEA580C);
      case 'transport':
        return const Color(0xFF0EA5E9);
      case 'body_parts':
      case 'bodyparts':
        return const Color(0xFFE11D48);
      case 'clothing':
        return const Color(0xFFA855F7);
      case 'handwriting':
        return const Color(0xFF4F46E5);
      case 'weather':
        return const Color(0xFF38BDF8);
      case 'professions':
        return const Color(0xFF0D9488);
      default:
        return Colors.blue;
    }
  }

  /// Get a theme specifically for a category overview page.
  static ThemeResult getCategoryTheme(
    String category, {
    bool isDark = true,
    bool isMidnight = false,
  }) {
    final String normalized = category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    final Color base = getCategoryBaseColor(normalized);
    final HSLColor hsl = HSLColor.fromColor(base);

    Color bgTop;
    Color bgBottom;

    if (isDark) {
      bgTop = hsl.withLightness(0.15).withSaturation(0.6).toColor();
      bgBottom = isMidnight ? const Color(0xFF000000) : const Color(0xFF0F172A);
    } else {
      bgTop = hsl.withLightness(0.95).toColor();
      bgBottom = hsl.withLightness(0.85).toColor();
    }

    final gameCategory = GameCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == normalized,
      orElse: () => GameCategory.grammar,
    );

    return ThemeResult(
      primaryColor: base,
      accentColor: hsl.withLightness(0.7).toColor(),
      backgroundColors: [bgTop, bgBottom],
      title: _getCategoryTitle(normalized).toUpperCase(),
      icon: _getCategoryIcon(normalized),
      category: gameCategory,
    );
  }

  static ThemeResult getTheme(
    String gameType, {
    int level = 1,
    bool isDark = true,
    bool isMidnight = false,
  }) {
    final String normalizedType = gameType
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');

    // 1. Detect Category
    if (_categoryNames.contains(normalizedType)) {
      return getCategoryTheme(
        normalizedType,
        isDark: isDark,
        isMidnight: isMidnight,
      );
    }

    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name.toLowerCase() == normalizedType,
      orElse: () => GameSubtype.grammarQuest,
    );

    final categoryName = subtype.category.name;
    final Color baseColor = getCategoryBaseColor(categoryName);

    // 2. LEVEL SHADING LOGIC (The "Journey" feel)
    // We adjust Lightness based on level (1-100+)
    // Level 1 is lighter, Level 100 is deeper/richer
    final HSLColor baseHsl = HSLColor.fromColor(baseColor);

    // Normalize level to a factor between -0.15 and +0.15
    final double levelFactor = ((level.clamp(1, 100) - 50) / 50.0) * -0.15;

    final primaryHsl = baseHsl.withLightness(
      (baseHsl.lightness + levelFactor).clamp(0.1, 0.9),
    );
    final Color primary = primaryHsl.toColor();

    // 3. Background Gradient Creation
    Color bgTop;
    Color bgBottom;

    if (isDark) {
      // Background is a very dark version of the primary color for immersion
      bgTop = primaryHsl.withLightness(0.12).withSaturation(0.5).toColor();
      bgBottom = isMidnight ? const Color(0xFF000000) : const Color(0xFF0F172A);
    } else {
      bgTop = primaryHsl.withLightness(0.92).toColor();
      bgBottom = primaryHsl.withLightness(0.82).toColor();
    }

    final accent = primaryHsl.withLightness(isDark ? 0.7 : 0.4).toColor();

    // 4. Title Mapping
    String title = "Quest";

    final Map<String, String> gameTitles = {
      // Speaking
      'repeatsentence': "Repeat Sentence",
      'speakmissingword': "Speak Missing Word",
      'situationspeaking': "Situation Speaking",
      'scenedescriptionspeaking': "Scene Description",
      'yesnospeaking': "Yes/No Speaking",
      'speaksynonym': "Speak Synonym",
      'dialogueroleplay': "Dialogue Roleplay",
      'pronunciationfocus': "Pronunciation Focus",
      'speakopposite': "Speak Opposite",
      'dailyexpression': "Daily Expression",

      // Accent
      'minimalpairs': "Minimal Pairs",
      'intonationmimic': "Intonation Mimic",
      'syllablestress': "Syllable Stress",
      'wordlinking': "Word Linking",
      'shadowingchallenge': "Shadowing Challenge",
      'voweldistinction': "Vowel Distinction",
      'consonantclarity': "Consonant Clarity",
      'pitchpatternmatch': "Pitch Pattern Match",
      'speedvariance': "Speed Variance",
      'dialectdrill': "Dialect Drill",
      'connectedspeech': "Connected Speech",
      'pitchmodulation': "Pitch Modulation",

      // Roleplay
      'branchingdialogue': "Branching Dialogue",
      'situationalresponse': "Situational Response",
      'jobinterview': "Job Interview",
      'medicalconsult': "Medical Consult",
      'gourmetorder': "Gourmet Order",
      'traveldesk': "Travel Desk",
      'conflictresolver': "Conflict Resolver",
      'elevatorpitch': "Elevator Pitch",
      'socialspark': "Social Spark",
      'emergencyhub': "Emergency Hub",

      // Listening
      'audiofillblanks': "Audio Fill Blanks",
      'audiomultiplechoice': "Audio Multi Choice",
      'audiosentenceorder': "Audio Sentence Order",
      'audiotruefalse': "Audio True/False",
      'soundimagematch': "Sound-Image Match",
      'fastspeechdecoder': "Fast Speech Decoder",
      'emotionrecognition': "Emotion Recognition",
      'detailspotlight': "Detail Spotlight",
      'listeninginference': "Listening Inference",
      'ambientid': "Ambient ID",

      // Reading
      'readandanswer': "Read & Answer",
      'findwordmeaning': "Find Word Meaning",
      'truefalsereading': "True/False Reading",
      'sentenceorderreading': "Sentence Order",
      'readingspeedcheck': "Reading Speed",
      'guesstitle': "Guess Title",
      'readandmatch': "Read & Match",
      'paragraphsummary': "Paragraph Summary",
      'readinginference': "Reading Inference",
      'readingconclusion': "Reading Conclusion",
      'clozetest': "Cloze Test",
      'skimmingscanning': "Skimming & Scanning",

      // Writing
      'sentencebuilder': "Sentence Builder",
      'completesentence': "Complete Sentence",
      'describesituationwriting': "Describe Situation",
      'fixthesentence': "Fix The Sentence",
      'shortanswerwriting': "Short Answer",
      'opinionwriting': "Opinion Writing",
      'dailyjournal': "Daily Journal",
      'summarizestorywriting': "Summarize Story",
      'writingemail': "Writing Email",
      'correctionwriting': "Correction Writing",
      'essaydrafting': "Essay Drafting",

      // Grammar
      'grammarquest': "Grammar Quest",
      'sentencecorrection': "Sentence Correction",
      'wordreorder': "Word Reorder",
      'tensemastery': "Tense Mastery",
      'partsofspeech': "Parts of Speech",
      'subjectverbagreement': "Subject-Verb Agreement",
      'clauseconnector': "Clause Connector",
      'voiceswap': "Voice Swap",
      'questionformatter': "Question Formatter",
      'articleinsertion': "Article Insertion",
      'modifierplacement': "Modifier Placement",
      'modalsselection': "Modals Selection",
      'prepositionchoice': "Preposition Choice",
      'pronounresolution': "Pronoun Resolution",
      'punctuationmastery': "Punctuation Mastery",
      'relativeclauses': "Relative Clauses",
      'conditionals': "Conditionals",
      'conjunctions': "Conjunctions",
      'directindirectspeech': "Direct/Indirect Speech",

      // Vocabulary
      'flashcards': "Flashcards",
      'synonymsearch': "Synonym Search",
      'antonymsearch': "Antonym Search",
      'contextclues': "Context Clues",
      'phrasalverbs': "Phrasal Verbs",
      'idioms': "Idioms",
      'academicword': "Academic Word",
      'topicvocab': "Topic Vocab",
      'wordformation': "Word Formation",
      'prefixsuffix': "Prefix & Suffix",
      'collocations': "Collocations",
      'contextualusage': "Contextual Usage",

      // Elite Mastery
      'storybuilder': "Story Builder",
      'idiommatch': "Idiom Match",
      'speedspelling': "Speed Spelling",
      'accentshadowing': "Accent Shadowing",
    };

    if (gameTitles.containsKey(normalizedType)) {
      title = gameTitles[normalizedType]!;
    }

    // 5. Category Enum Mapping
    final GameCategory finalCategory = GameCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == subtype.category.name.toLowerCase(),
      orElse: () => GameCategory.grammar,
    );

    return ThemeResult(
      primaryColor: primary,
      accentColor: accent,
      backgroundColors: [bgTop, bgBottom],
      title: title.toUpperCase(),
      icon: _getSubtypeIcon(normalizedType),
      category: finalCategory,
    );
  }

  static IconData _getSubtypeIcon(String type) {
    return _subtypeIconMap[type.toLowerCase()] ?? _getCategoryIcon(type);
  }

  /// O(1) Map lookup replacing the original 60+ sequential if-statements.
  /// All keys are pre-lowercased; [_getSubtypeIcon] lowercases before lookup.
  static const Map<String, IconData> _subtypeIconMap = {
    // ── Speaking ──────────────────────────────────────────────────────────
    'repeatsentence': Icons.repeat_rounded,
    'speakmissingword': Icons.spellcheck_rounded,
    'situationspeaking': Icons.forum_rounded,
    'scenedescriptionspeaking': Icons.image_search_rounded,
    'yesnospeaking': Icons.thumbs_up_down_rounded,
    'speaksynonym': Icons.record_voice_over_rounded,
    'dialogueroleplay': Icons.groups_rounded,
    'pronunciationfocus': Icons.mic_external_on_rounded,
    'speakopposite': Icons.swap_horiz_rounded,
    'dailyexpression': Icons.chat_bubble_outline_rounded,
    // ── Listening ─────────────────────────────────────────────────────────
    'audiofillblanks': Icons.music_note_rounded,
    'audiomultiplechoice': Icons.queue_music_rounded,
    'audiosentenceorder': Icons.playlist_add_check_rounded,
    'audiotruefalse': Icons.rule_rounded,
    'soundimagematch': Icons.image_rounded,
    'fastspeechdecoder': Icons.speed_rounded,
    'emotionrecognition': Icons.sentiment_satisfied_rounded,
    'detailspotlight': Icons.center_focus_strong_rounded,
    'listeninginference': Icons.psychology_rounded,
    'ambientid': Icons.surround_sound_rounded,
    // ── Reading ───────────────────────────────────────────────────────────
    'readandanswer': Icons.menu_book_rounded,
    'findwordmeaning': Icons.search_rounded,
    'truefalsereading': Icons.verified_rounded,
    'sentenceorderreading': Icons.view_headline_rounded,
    'readandmatch': Icons.extension_rounded,
    'skimmingscanning': Icons.visibility_rounded,
    'paragraphsummary': Icons.short_text_rounded,
    'readingspeedcheck': Icons.shutter_speed_rounded,
    'readinginference': Icons.lightbulb_rounded,
    'readingconclusion': Icons.fact_check_rounded,
    'clozetest': Icons.border_color_rounded,
    'guesstitle': Icons.title_rounded,
    // ── Writing ───────────────────────────────────────────────────────────
    'sentencebuilder': Icons.build_rounded,
    'completesentence': Icons.edit_note_rounded,
    'fixthesentence': Icons.auto_fix_high_rounded,
    'describesituationwriting': Icons.description_rounded,
    'summarizestorywriting': Icons.history_edu_rounded,
    'shortanswerwriting': Icons.subject_rounded,
    'opinionwriting': Icons.rate_review_rounded,
    'dailyjournal': Icons.menu_book_rounded,
    'writingemail': Icons.email_rounded,
    'correctionwriting': Icons.spellcheck_rounded,
    'essaydrafting': Icons.article_rounded,
    // ── Grammar ───────────────────────────────────────────────────────────
    'grammarquest': Icons.account_tree_rounded,
    'sentencecorrection': Icons.check_circle_rounded,
    'wordreorder': Icons.low_priority_rounded,
    'tensemastery': Icons.update_rounded,
    'partsofspeech': Icons.category_rounded,
    'subjectverbagreement': Icons.handshake_rounded,
    'clauseconnector': Icons.link_rounded,
    'voiceswap': Icons.record_voice_over_rounded,
    'questionformatter': Icons.help_outline_rounded,
    'articleinsertion': Icons.text_fields_rounded,
    'modifierplacement': Icons.place_rounded,
    'modalsselection': Icons.star_border_rounded,
    'prepositionchoice': Icons.navigation_rounded,
    'pronounresolution': Icons.person_search_rounded,
    'punctuationmastery': Icons.format_quote_rounded,
    'relativeclauses': Icons.family_restroom_rounded,
    'conditionals': Icons.call_split_rounded,
    'conjunctions': Icons.join_inner_rounded,
    'directindirectspeech': Icons.record_voice_over_rounded,
    // ── Vocabulary ────────────────────────────────────────────────────────
    'flashcards': Icons.style_rounded,
    'synonymsearch': Icons.compare_arrows_rounded,
    'antonymsearch': Icons.swap_horiz_rounded,
    'contextclues': Icons.find_in_page_rounded,
    'phrasalverbs': Icons.alt_route_rounded,
    'idioms': Icons.auto_awesome_rounded,
    'academicword': Icons.school_rounded,
    'topicvocab': Icons.topic_rounded,
    'wordformation': Icons.reorder_rounded,
    'prefixsuffix': Icons.unfold_more_rounded,
    'collocations': Icons.link_rounded,
    'contextualusage': Icons.text_snippet_rounded,
    // ── Accent ────────────────────────────────────────────────────────────
    'minimalpairs': Icons.exposure_rounded,
    'intonationmimic': Icons.waves_rounded,
    'syllablestress': Icons.format_bold_rounded,
    'wordlinking': Icons.link_rounded,
    'shadowingchallenge': Icons.person_pin_circle_rounded,
    'voweldistinction': Icons.music_note_rounded,
    'consonantclarity': Icons.mic_external_on_rounded,
    'pitchpatternmatch': Icons.graphic_eq_rounded,
    'speedvariance': Icons.slow_motion_video_rounded,
    'dialectdrill': Icons.location_on_rounded,
    'connectedspeech': Icons.merge_type_rounded,
    'pitchmodulation': Icons.vibration_rounded,
    // ── Roleplay ──────────────────────────────────────────────────────────
    'branchingdialogue': Icons.alt_route_rounded,
    'situationalresponse': Icons.volunteer_activism_rounded,
    'jobinterview': Icons.work_rounded,
    'medicalconsult': Icons.medical_services_rounded,
    'gourmetorder': Icons.restaurant_rounded,
    'traveldesk': Icons.flight_rounded,
    'conflictresolver': Icons.balance_rounded,
    'elevatorpitch': Icons.trending_up_rounded,
    'socialspark': Icons.celebration_rounded,
    'emergencyhub': Icons.emergency_rounded,
    // ── Elite Mastery ─────────────────────────────────────────────────────
    'storybuilder': Icons.auto_stories_rounded,
    'idiommatch': Icons.extension_rounded,
    'speedspelling': Icons.bolt_rounded,
    'accentshadowing': Icons.mic_rounded,
  };
}

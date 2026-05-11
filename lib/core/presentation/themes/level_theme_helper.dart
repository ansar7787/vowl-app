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
  /// Known category names
  static const _categoryNames = {
    'vocabulary', 'grammar', 'listening', 'reading',
    'writing', 'speaking', 'accent', 'roleplay', 'elitemastery',
  };

  /// Core Category Base Colors (Mathematically Balanced for Distinction)
  static Color _getCategoryBaseColor(String category) {
    switch (category.toLowerCase()) {
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

  /// Category icons
  static IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
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

  /// Get a theme specifically for a category overview page.
  static ThemeResult getCategoryTheme(
    String category, {
    bool isDark = true,
    bool isMidnight = false,
  }) {
    final Color base = _getCategoryBaseColor(category);
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
      (c) => c.name.toLowerCase() == category.toLowerCase(),
      orElse: () => GameCategory.grammar,
    );

    return ThemeResult(
      primaryColor: base,
      accentColor: hsl.withLightness(0.7).toColor(),
      backgroundColors: [bgTop, bgBottom],
      title: category.toUpperCase(),
      icon: _getCategoryIcon(category),
      category: gameCategory,
    );
  }

  static ThemeResult getTheme(
    String gameType, {
    int level = 1,
    bool isDark = true,
    bool isMidnight = false,
  }) {
    // 1. Detect Category
    if (_categoryNames.contains(gameType.toLowerCase())) {
      return getCategoryTheme(gameType, isDark: isDark, isMidnight: isMidnight);
    }

    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name.toLowerCase() == gameType.toLowerCase(),
      orElse: () => GameSubtype.grammarQuest,
    );
    
    final categoryName = subtype.category.name;
    final Color baseColor = _getCategoryBaseColor(categoryName);
    
    // 2. LEVEL SHADING LOGIC (The "Journey" feel)
    // We adjust Lightness based on level (1-100+)
    // Level 1 is lighter, Level 100 is deeper/richer
    final HSLColor baseHsl = HSLColor.fromColor(baseColor);
    
    // Normalize level to a factor between -0.15 and +0.15
    final double levelFactor = ((level.clamp(1, 100) - 50) / 50.0) * -0.15;
    
    final primaryHsl = baseHsl.withLightness((baseHsl.lightness + levelFactor).clamp(0.1, 0.9));
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
    final type = gameType.toLowerCase();
    
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

    if (gameTitles.containsKey(type)) {
      title = gameTitles[type]!;
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
      icon: _getSubtypeIcon(type),
      category: finalCategory,
    );
  }

  static IconData _getSubtypeIcon(String type) {
    final t = type.toLowerCase();
    
    // Speaking
    if (t == 'repeatsentence') return Icons.repeat_rounded;
    if (t == 'speakmissingword') return Icons.spellcheck_rounded;
    if (t == 'situationspeaking') return Icons.forum_rounded;
    if (t == 'scenedescriptionspeaking') return Icons.image_search_rounded;
    if (t == 'yesnospeaking') return Icons.thumbs_up_down_rounded;
    if (t == 'speaksynonym') return Icons.record_voice_over_rounded;
    if (t == 'dialogueroleplay') return Icons.groups_rounded;
    if (t == 'pronunciationfocus') return Icons.mic_external_on_rounded;
    if (t == 'speakopposite') return Icons.swap_horiz_rounded;
    if (t == 'dailyexpression') return Icons.chat_bubble_outline_rounded;

    // Listening
    if (t == 'audiofillblanks') return Icons.music_note_rounded;
    if (t == 'audiomultiplechoice') return Icons.queue_music_rounded;
    if (t == 'audiosentenceorder') return Icons.playlist_add_check_rounded;
    if (t == 'audiotruefalse') return Icons.rule_rounded;
    if (t == 'soundimagematch') return Icons.image_rounded;
    if (t == 'fastspeechdecoder') return Icons.speed_rounded;
    if (t == 'emotionrecognition') return Icons.sentiment_satisfied_rounded;
    if (t == 'detailspotlight') return Icons.center_focus_strong_rounded;
    if (t == 'listeninginference') return Icons.psychology_rounded;
    if (t == 'ambientid') return Icons.surround_sound_rounded;

    // Reading
    if (t == 'readandanswer') return Icons.menu_book_rounded;
    if (t == 'findwordmeaning') return Icons.search_rounded;
    if (t == 'truefalsereading') return Icons.verified_rounded;
    if (t == 'sentenceorderreading') return Icons.view_headline_rounded;
    if (t == 'readandmatch') return Icons.extension_rounded;
    if (t == 'skimmingscanning') return Icons.visibility_rounded;
    if (t == 'paragraphsummary') return Icons.short_text_rounded;
    if (t == 'readingspeedcheck') return Icons.shutter_speed_rounded;
    if (t == 'readinginference') return Icons.lightbulb_rounded;
    if (t == 'readingconclusion') return Icons.fact_check_rounded;
    if (t == 'clozetest') return Icons.border_color_rounded;
    if (t == 'guesstitle') return Icons.title_rounded;

    // Writing
    if (t == 'sentencebuilder') return Icons.build_rounded;
    if (t == 'completesentence') return Icons.edit_note_rounded;
    if (t == 'fixthesentence') return Icons.auto_fix_high_rounded;
    if (t == 'describesituationwriting') return Icons.description_rounded;
    if (t == 'summarizestorywriting') return Icons.history_edu_rounded;
    if (t == 'shortanswerwriting') return Icons.subject_rounded;
    if (t == 'opinionwriting') return Icons.rate_review_rounded;
    if (t == 'dailyjournal') return Icons.menu_book_rounded;
    if (t == 'writingemail') return Icons.email_rounded;
    if (t == 'correctionwriting') return Icons.spellcheck_rounded;
    if (t == 'essaydrafting') return Icons.article_rounded;

    // Grammar
    if (t == 'grammarquest') return Icons.account_tree_rounded;
    if (t == 'sentencecorrection') return Icons.check_circle_rounded;
    if (t == 'wordreorder') return Icons.low_priority_rounded;
    if (t == 'tensemastery') return Icons.update_rounded;
    if (t == 'partsofspeech') return Icons.category_rounded;
    if (t == 'subjectverbagreement') return Icons.handshake_rounded;
    if (t == 'clauseconnector') return Icons.link_rounded;
    if (t == 'voiceswap') return Icons.record_voice_over_rounded;
    if (t == 'questionformatter') return Icons.help_outline_rounded;
    if (t == 'articleinsertion') return Icons.text_fields_rounded;
    if (t == 'modifierplacement') return Icons.place_rounded;
    if (t == 'modalsselection') return Icons.star_border_rounded;
    if (t == 'prepositionchoice') return Icons.navigation_rounded;
    if (t == 'pronounresolution') return Icons.person_search_rounded;
    if (t == 'punctuationmastery') return Icons.format_quote_rounded;
    if (t == 'relativeclauses') return Icons.family_restroom_rounded;
    if (t == 'conditionals') return Icons.call_split_rounded;
    if (t == 'conjunctions') return Icons.join_inner_rounded;
    if (t == 'directindirectspeech') return Icons.record_voice_over_rounded;

    // Vocabulary
    if (t == 'flashcards') return Icons.style_rounded;
    if (t == 'synonymsearch') return Icons.compare_arrows_rounded;
    if (t == 'antonymsearch') return Icons.swap_horiz_rounded;
    if (t == 'contextclues') return Icons.find_in_page_rounded;
    if (t == 'phrasalverbs') return Icons.alt_route_rounded;
    if (t == 'idioms') return Icons.auto_awesome_rounded;
    if (t == 'academicword') return Icons.school_rounded;
    if (t == 'topicvocab') return Icons.topic_rounded;
    if (t == 'wordformation') return Icons.reorder_rounded;
    if (t == 'prefixsuffix') return Icons.unfold_more_rounded;
    if (t == 'collocations') return Icons.link_rounded;
    if (t == 'contextualusage') return Icons.text_snippet_rounded;

    // Accent
    if (t == 'minimalpairs') return Icons.exposure_rounded;
    if (t == 'intonationmimic') return Icons.waves_rounded;
    if (t == 'syllablestress') return Icons.format_bold_rounded;
    if (t == 'wordlinking') return Icons.link_rounded;
    if (t == 'shadowingchallenge') return Icons.person_pin_circle_rounded;
    if (t == 'voweldistinction') return Icons.music_note_rounded;
    if (t == 'consonantclarity') return Icons.mic_external_on_rounded;
    if (t == 'pitchpatternmatch') return Icons.graphic_eq_rounded;
    if (t == 'speedvariance') return Icons.slow_motion_video_rounded;
    if (t == 'dialectdrill') return Icons.location_on_rounded;
    if (t == 'connectedspeech') return Icons.merge_type_rounded;
    if (t == 'pitchmodulation') return Icons.vibration_rounded;

    // Roleplay
    if (t == 'branchingdialogue') return Icons.alt_route_rounded;
    if (t == 'situationalresponse') return Icons.volunteer_activism_rounded;
    if (t == 'jobinterview') return Icons.work_rounded;
    if (t == 'medicalconsult') return Icons.medical_services_rounded;
    if (t == 'gourmetorder') return Icons.restaurant_rounded;
    if (t == 'traveldesk') return Icons.flight_rounded;
    if (t == 'conflictresolver') return Icons.balance_rounded;
    if (t == 'elevatorpitch') return Icons.trending_up_rounded;
    if (t == 'socialspark') return Icons.celebration_rounded;
    if (t == 'emergencyhub') return Icons.emergency_rounded;

    // Elite Mastery
    if (t == 'storybuilder') return Icons.auto_stories_rounded;
    if (t == 'idiommatch') return Icons.extension_rounded;
    if (t == 'speedspelling') return Icons.bolt_rounded;
    if (t == 'accentshadowing') return Icons.mic_rounded;

    return _getCategoryIcon(t);
  }
}

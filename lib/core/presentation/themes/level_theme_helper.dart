import 'package:flutter/material.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';

enum GameCategory {
  speaking,
  listening,
  reading,
  writing,
  grammar,
  vocabulary,
  accent,
  roleplay,
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
  static ThemeResult getTheme(
    String gameType, {
    int level = 1,
    bool isDark = true,
  }) {
    // 1. Find the subtype to get its unique index (0-79)
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name.toLowerCase() == gameType.toLowerCase(),
      orElse: () => GameSubtype.grammarQuest,
    );
    final index = GameSubtype.values.indexOf(subtype);

    // 2. Generate mathematically unique and VASTLY different hue for each of the 80 games
    // We use a jittered approach (Multiplying by a prime or golden ratio angle)
    // to ensure adjacent games (index 0 and 1) are visually very far apart.
    final double hue = (index * 137.5) % 360.0;

    // 3. Create Primary Color (Vibrant & Premium)
    final hsvPrimary = HSVColor.fromAHSV(1.0, hue, 0.75, 0.9);
    final Color primary = hsvPrimary.toColor();

    // 4. Create Unique Background Gradient (Related but distinct tones based on the unique hue)
    // We adjust based on light/dark mode for a "white-standard" or "proper-dark" look.
    Color bgTop;
    Color bgBottom;

    if (isDark) {
      // Proper Dark Mode Gradient (Deep, sophisticated, no flat black)
      bgTop = hsvPrimary.withSaturation(0.6).withValue(0.15).toColor();
      bgBottom = const Color(0xFF0F172A); // Navy/Deep Black base
    } else {
      // White-Standard Light Mode Gradient (Clean, premium, airy)
      bgTop = hsvPrimary.withSaturation(0.08).withValue(0.99).toColor();
      bgBottom = const Color(0xFFF8FAFC); // Off-white instead of pure white
    }

    // For lighter decorations or progress bars
    final accent = hsvPrimary.withSaturation(0.5).withValue(0.95).toColor();

    List<Color> bgColors = [bgTop, bgBottom];

    // 5. Title & Metadata
    String title = "Quest";
    IconData icon = Icons.gamepad;
    GameCategory category = GameCategory.grammar;

    final type = gameType.toLowerCase();

    // Mapping for All 80 Game Subtypes Titles
    final Map<String, String> gameTitles = {
      // Speaking (10)
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

      // Accent (10)
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

      // Roleplay (10)
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

      // Listening (10)
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

      // Reading (10)
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

      // Writing (10)
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

      // Grammar (10)
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

      // Vocabulary (10)
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
    };

    if (gameTitles.containsKey(type)) {
      title = gameTitles[type]!;
    }

    // Category Determination for Icons/Labels
    final questCategory =
        subtype.category; // Using the extension from game_quest.dart

    switch (questCategory) {
      case QuestType.speaking:
        icon = Icons.mic_rounded;
        category = GameCategory.speaking;
        break;
      case QuestType.listening:
        icon = Icons.headphones_rounded;
        category = GameCategory.listening;
        break;
      case QuestType.reading:
        icon = Icons.auto_stories_rounded;
        category = GameCategory.reading;
        break;
      case QuestType.writing:
        icon = Icons.edit_note_rounded;
        category = GameCategory.writing;
        break;
      case QuestType.grammar:
        icon = Icons.spellcheck_rounded;
        category = GameCategory.grammar;
        break;
      case QuestType.vocabulary:
        icon = Icons.abc_rounded;
        category = GameCategory.vocabulary;
        break;
      case QuestType.accent:
        icon = Icons.graphic_eq_rounded;
        category = GameCategory.accent;
        break;
      case QuestType.roleplay:
        icon = Icons.theater_comedy_rounded;
        category = GameCategory.roleplay;
        break;
    }

    return ThemeResult(
      primaryColor: primary,
      accentColor: accent,
      backgroundColors: bgColors,
      title: title.toUpperCase(),
      icon: icon,
      category: category,
    );
  }
}

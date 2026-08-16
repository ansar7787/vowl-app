import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Dynamic immutable entity representing resolved visual parameters for active screens.
class GameBriefing {
  final String title;
  final String objective;
  final List<String> rules;
  final IconData icon;
  final String actionText;
  final String tip;

  const GameBriefing({
    required this.title,
    required this.objective,
    required this.rules,
    required this.icon,
    required this.actionText,
    required this.tip,
  });
}

/// Performance-optimized instruction coordinator resolving game descriptions
/// using O(1) static lookup maps and concise, punchy visual instructions.
class GameInstructionService {
  // Private constructor to enforce static utility boundaries
  const GameInstructionService._();

  /// Resolves briefing assets, incorporating Milestone markers for Level 100.
  static GameBriefing getBriefing(
    BuildContext context,
    GameSubtype? type,
    String? fallbackTitle, {
    int level = 1,
  }) {
    final baseBriefing = _getBaseBriefing(type, fallbackTitle);

    final baseKey =
        type?.name ??
        fallbackTitle?.toLowerCase().replaceAll(' ', '_') ??
        "default";
    final title = context.tr(
      'instructions.$baseKey.title',
      fallback: baseBriefing.title,
    );
    final objective = context.tr(
      'instructions.$baseKey.objective',
      fallback: baseBriefing.objective,
    );
    final actionText = context.tr(
      'instructions.$baseKey.actionText',
      fallback: baseBriefing.actionText,
    );

    final tipFallback = level == 100
        ? "🏆 MILESTONE: You've reached Level 100! This is an Elite Mastery test. Show us your best! ${baseBriefing.tip}"
        : baseBriefing.tip;
    final tip = context.tr('instructions.$baseKey.tip', fallback: tipFallback);

    final translatedRules = baseBriefing.rules
        .asMap()
        .entries
        .map(
          (e) => context.tr(
            'instructions.$baseKey.rule_${e.key}',
            fallback: e.value,
          ),
        )
        .toList();

    return GameBriefing(
      title: title,
      icon: baseBriefing.icon,
      objective: objective,
      rules: translatedRules,
      actionText: actionText,
      tip: tip,
    );
  }

  static GameBriefing _getBaseBriefing(
    GameSubtype? type,
    String? fallbackTitle,
  ) {
    if (type == null) {
      if (fallbackTitle != null) {
        final kidsBriefing = _getKidsBriefing(fallbackTitle);
        if (kidsBriefing != null) return kidsBriefing;
      }
      return getDefaultBriefing(fallbackTitle ?? "Quest");
    }

    // Dynamic O(1) map resolution
    final resolved = _briefings[type];
    if (resolved != null) return resolved;

    // --- CATEGORY FALLBACKS ---
    final category = type.category;
    switch (category) {
      case QuestType.speaking:
        return const GameBriefing(
          title: "Voice Mastery",
          icon: Icons.record_voice_over_rounded,
          objective:
              "Tap mic and repeat the phrase clearly at a natural pace. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
          rules: [
            "Find a quiet place",
            "Speak at a natural pace",
            "Match the example",
          ],
          actionText: "Record Now",
          tip:
              "PRO TIP: Record yourself! Comparing your pitch to the model helps master the natural rhythm.",
        );
      case QuestType.listening:
        return const GameBriefing(
          title: "Audio Analysis",
          icon: Icons.headphones_rounded,
          objective:
              "Listen carefully and choose the correct answer option. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
          rules: ["Use headphones", "Focus on intonation", "Identify keywords"],
          actionText: "Initialize Feed",
          tip:
              "PRO TIP: Close your eyes! Focusing on pure sound helps catch subtle phoneme changes.",
        );
      case QuestType.reading:
        return const GameBriefing(
          title: "Text Comprehension",
          icon: Icons.menu_book_rounded,
          objective:
              "Read the passage carefully and answer the comprehension questions. Mastering reading comprehension allows you to quickly extract key information in the real world.",
          rules: [
            "Read the whole text",
            "Identify main ideas",
            "Check details carefully",
          ],
          actionText: "Analyze Text",
          tip:
              "PRO TIP: Scan for keywords first! Don't get stuck on one word; focus on the overall message.",
        );
      case QuestType.writing:
        return const GameBriefing(
          title: "Sentence Construction",
          icon: Icons.edit_note_rounded,
          objective:
              "Arrange the words in the correct order to build a complete sentence. Mastering this skill ensures your written communication is clear, professional, and effective.",
          rules: [
            "Check your spelling",
            "Check punctuation",
            "Structure logically",
          ],
          actionText: "Build Sentence",
          tip:
              "PRO TIP: Start with the verb! Finding the action helps the rest of the sentence fall into place.",
        );
      case QuestType.grammar:
        return const GameBriefing(
          title: "Structural Logic",
          icon: Icons.architecture_rounded,
          objective:
              "Fix the underlying structural errors to complete the sentence. Mastering structural rules ensures your English is accurate and easily understood.",
          rules: [
            "Identify errors",
            "Choose the correction",
            "Master the rules",
          ],
          actionText: "Fix Structure",
          tip:
              "PRO TIP: Read the sentence out loud in your head! Often, you can 'hear' if a rule is being broken.",
        );
      case QuestType.vocabulary:
        return const GameBriefing(
          title: "Word Power",
          icon: Icons.auto_awesome_rounded,
          objective:
              "Match words to their correct definitions to expand your vocabulary. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
          rules: [
            "Memorize the meanings",
            "Understand context",
            "Build word bank",
          ],
          actionText: "Acquire Lexicon",
          tip:
              "PRO TIP: Visual associations help! Try to link the word to a picture in your mind.",
        );
      case QuestType.accent:
        return const GameBriefing(
          title: "Phonetic Drill",
          icon: Icons.music_note_rounded,
          objective:
              "Focus on rhythm and pitch. Sound exactly like a native speaker. Mastering pronunciation ensures your spoken English sounds clear and natural.",
          rules: [
            "Listen to intonation",
            "Mimic the rhythm",
            "Repeat until perfect",
          ],
          actionText: "Start Drill",
          tip:
              "PRO TIP: Over-enunciate! Emphasizing the vowels helps clear up minimal pair confusion.",
        );
      case QuestType.roleplay:
        return const GameBriefing(
          title: "Social Simulation",
          icon: Icons.groups_rounded,
          objective:
              "Navigate social scenarios by selecting the best conversational response. Mastering situational responses ensures you can navigate social interactions with confidence.",
          rules: ["Stay in character", "Think of the goal", "React naturally"],
          actionText: "Enter Scenario",
          tip:
              "PRO TIP: Be expressive! The tone is just as important as the words in social interactions.",
        );
      default:
        return getDefaultBriefing(fallbackTitle ?? "Quest");
    }
  }

  // Large centralized static register matching GameSubtypes to their Briefing parameters.
  static const Map<GameSubtype, GameBriefing> _briefings = {
    GameSubtype.speedSpelling: GameBriefing(
      title: "Speed Spelling",
      icon: Icons.bolt_rounded,
      objective:
          "Tap the floating letters to spell the target word correctly. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Spelling must be exact",
        "Sound out the syllables",
        "Review before submitting",
      ],
      actionText: "Start Spelling",
      tip:
          "PRO TIP: Sound the word out slowly in your head before tapping the letters.",
    ),
    GameSubtype.idiomMatch: GameBriefing(
      title: "Idiom Master",
      icon: Icons.lightbulb_rounded,
      objective:
          "Match the idiom to its real meaning. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: [
        "Analyze the context clue",
        "Identify the core meaning",
        "Match the perfect idiom",
      ],
      actionText: "Match Idiom",
      tip:
          "PRO TIP: Idioms rarely mean what the individual words mean literally. Think about the feeling or situation they describe!",
    ),
    GameSubtype.minimalPairs: GameBriefing(
      title: "Minimal Pairs",
      icon: Icons.hearing_rounded,
      objective:
          "Listen to the word, select the correct matching sound, then speak it aloud to lock in the pronunciation. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the target word",
        "Select the exact phonetic match",
        "Speak the answer to confirm",
      ],
      actionText: "Identify Sound",
      tip:
          "PRO TIP: Pay attention to whether the vowel feels quick and relaxed, or long and stretched!",
    ),
    GameSubtype.consonantClarity: GameBriefing(
      title: "Consonant Clarity",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Identify the target consonant, then speak the word aloud to confirm your pronunciation. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the target word",
        "Tap the matching consonant",
        "Speak to confirm your answer",
      ],
      actionText: "Identify Sound",
      tip:
          "PRO TIP: Pay attention to whether your vocal cords vibrate (voiced) or not (voiceless) when you make the sound!",
    ),
    GameSubtype.pitchModulation: GameBriefing(
      title: "Pitch Modulation",
      icon: Icons.show_chart_rounded,
      objective:
          "Listen to the speaker's pitch and select the matching modulation pattern to master how English speakers convey energy and emotion through voice. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the phrase",
        "Analyze the pitch contour",
        "Select the correct pattern",
      ],
      actionText: "Identify Pitch",
      tip:
          "PRO TIP: Pay attention to whether the voice rises or falls at the end of the phrase to determine its exact meaning!",
    ),
    GameSubtype.pitchPatternMatch: GameBriefing(
      title: "Pitch Pattern Match",
      icon: Icons.music_note_rounded,
      objective:
          "Replicate the musical timing and pitch contour of the full sentence. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the sentence",
        "Analyze the emphasis",
        "Identify the correct pattern",
      ],
      actionText: "Identify Pattern",
      tip:
          "PRO TIP: Pay attention to which word is stressed—it completely changes the sentence's meaning!",
    ),
    GameSubtype.shadowingChallenge: GameBriefing(
      title: "Shadowing Challenge",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Listen to the spoken sentence and select the correct phonetic rule that explains how the words link or change. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the phrase closely",
        "Analyze the sound connection",
        "Select the matching rule",
      ],
      actionText: "Identify Pattern",
      tip:
          "PRO TIP: Try saying the sentence aloud exactly as you hear it. Feeling the sounds connect in your mouth will reveal the answer!",
    ),
    GameSubtype.wordLinking: GameBriefing(
      title: "Word Linking",
      icon: Icons.link_rounded,
      objective:
          "Master word boundary linking to speak with native fluid rhythms. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the phrase",
        "Find where sounds fuse",
        "Select the linked words",
      ],
      actionText: "Identify Link",
      tip:
          "PRO TIP: Pay attention to where the final consonant of one word connects directly to the opening vowel of the next!",
    ),

    // 2. Speaking
    GameSubtype.repeatSentence: GameBriefing(
      title: "Echo Master",
      icon: Icons.graphic_eq_rounded,
      objective:
          "Listen carefully and repeat the sentence matching cadence and wave patterns. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: ["Hold mic to record", "Trace sound wave", "Master the cadence"],
      actionText: "Start Echo",
      tip:
          "PRO TIP: Match the stress rhythm—English flows in stressed clusters!",
    ),
    GameSubtype.speakMissingWord: GameBriefing(
      title: "Vocal Decoder",
      icon: Icons.find_in_page_rounded,
      objective:
          "Read the prompt and speak the missing word clearly to fill the blank. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: [
        "Identify the gap",
        "Speak the word clearly",
        "Verify the context",
      ],
      actionText: "Speak Word",
      tip:
          "PRO TIP: Look at surrounding nouns and verbs to match singular vs plural context.",
    ),
    GameSubtype.situationSpeaking: GameBriefing(
      title: "Crisis Communicator",
      icon: Icons.emergency_rounded,
      objective:
          "Orally provide a clear, direct solution to the real-world scenario. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: [
        "Understand context",
        "Speak your solution",
        "Be clear and direct",
      ],
      actionText: "Resolve Now",
      tip:
          "PRO TIP: Focus on direct, simple language to convey your message quickly.",
    ),
    GameSubtype.sceneDescriptionSpeaking: GameBriefing(
      title: "Visual Narrator",
      icon: Icons.image_search_rounded,
      objective:
          "Describe the image scene clearly using descriptive adjectives. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: [
        "Analyze the image",
        "Speak descriptive details",
        "Build a narrative",
      ],
      actionText: "Describe Scene",
      tip:
          "PRO TIP: Start with foreground actions, then move to background details.",
    ),
    GameSubtype.yesNoSpeaking: GameBriefing(
      title: "Voice Validator",
      icon: Icons.fact_check_rounded,
      objective:
          "Answer the factual questions firmly with a spoken 'Yes' or 'No'. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: [
        "Listen to the question",
        "Speak confirmation clearly",
        "Be quick and clear",
      ],
      actionText: "Validate Voice",
      tip:
          "PRO TIP: Speak with confident, clear pronunciation directly into the mic.",
    ),
    GameSubtype.speakSynonym: GameBriefing(
      title: "Lexical Speaker",
      icon: Icons.library_books_rounded,
      objective:
          "Orally state a word that means the exact same thing. Having multiple words for the same idea gives your speech much more color and variety.",
      rules: [
        "Find the twin meaning",
        "Speak clearly",
        "Build a rich vocabulary",
      ],
      actionText: "Speak Synonym",
      tip:
          "PRO TIP: Don't stress! Even simple, everyday synonyms are perfectly acceptable.",
    ),
    GameSubtype.dialogueRoleplay: GameBriefing(
      title: "Scene Architect",
      icon: Icons.theater_comedy_rounded,
      objective:
          "Speak your roleplay script lines with correct emotion and phrasing. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: ["Follow the script", "Speak with feeling", "Keep the flow going"],
      actionText: "Enter Scene",
      tip:
          "PRO TIP: Match your voice acting to the simulated character's mood!",
    ),
    GameSubtype.pronunciationFocus: GameBriefing(
      title: "Phonetic Precision",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Perfect mouth movements to pronounce challenging sounds and clusters. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: [
        "Focus on mouth shape",
        "Repeat target phoneme",
        "Analyze feedback waves",
      ],
      actionText: "Practice Sound",
      tip:
          "PRO TIP: Pay attention to where your tongue touches the roof of your mouth.",
    ),
    GameSubtype.speakOpposite: GameBriefing(
      title: "Antonym Orator",
      icon: Icons.compare_arrows_rounded,
      objective:
          "Speak the exact opposite meaning of the prompt word. Thinking of opposites rapidly builds a flexible, expressive vocabulary.",
      rules: ["Think of the opposite", "Speak clearly", "Avoid synonyms"],
      actionText: "Speak Opposite",
      tip:
          "PRO TIP: Think magnetically: What is the polar opposite of the given word?",
    ),
    GameSubtype.dailyExpression: GameBriefing(
      title: "Social Fluent",
      icon: Icons.chat_bubble_rounded,
      objective:
          "Master common daily idioms to speak naturally and connect with native speakers in real-world conversations. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: [
        "Swipe to reveal idiom",
        "Listen to expression",
        "Review context & usage",
      ],
      actionText: "Speak Now",
      tip:
          "PRO TIP: Emphasize the keywords that carry the main emotional meaning.",
    ),
    // 2. Listening
    GameSubtype.audioFillBlanks: GameBriefing(
      title: "Ink Decoder",
      icon: Icons.water_drop_rounded,
      objective:
          "Listen to the audio feed and type the missing words in the transcript. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Smear the ink",
        "Listen for the gap",
        "Type exactly what you hear",
      ],
      actionText: "Start Decoding",
      tip:
          "Listen carefully to short helper words like 'a', 'the', 'in', or 'at'!",
    ),
    GameSubtype.audioMultipleChoice: GameBriefing(
      title: "Sonic Satellites",
      icon: Icons.track_changes_rounded,
      objective:
          "Listen to the audio passage and select the correct answer. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Spin satellites",
        "Listen to speaker",
        "Select correct data match",
      ],
      actionText: "Lock Signal",
      tip: "Filter out noise and focus entirely on the speaker's main message.",
    ),
    GameSubtype.audioSentenceOrder: GameBriefing(
      title: "Timeline Scrubber",
      icon: Icons.waves_rounded,
      objective:
          "Listen and arrange the spoken segments in their correct chronological order. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Listen to stream",
        "Snap segments to timeline",
        "Calibrate sequence",
      ],
      actionText: "Calibrate Signal",
      tip:
          "Logical connectors like 'first', 'then', and 'after that' are your clues.",
    ),
    GameSubtype.audioTrueFalse: GameBriefing(
      title: "Signal Validator",
      icon: Icons.verified_user_rounded,
      objective:
          "Listen to the speaker and verify if the claim is true or false. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Analyze the claim",
        "Compare with audio data",
        "Validate or Nullify",
      ],
      actionText: "Begin Validation",
      tip:
          "Be careful of exact details—names, numbers, and dates must match perfectly.",
    ),
    GameSubtype.soundImageMatch: GameBriefing(
      title: "Thematic Linker",
      icon: Icons.category_rounded,
      objective:
          "Listen to the audio sound and match it with the correct visual image. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: ["Scan tiles", "Match sound to symbol", "Confirm thematic link"],
      actionText: "Confirm Link",
      tip:
          "Try to describe the sound in one word before selecting your choice.",
    ),
    GameSubtype.fastSpeechDecoder: GameBriefing(
      title: "Nuance Calibrator",
      icon: Icons.settings_input_composite_rounded,
      objective:
          "Decode rapid native speech by picking out word boundaries. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Rotate gears",
        "Listen for speed transitions",
        "Unfold the meaning",
      ],
      actionText: "Calibrate Gears",
      tip:
          "Focus on stressed syllables—they carry the core meaning in fast speech.",
    ),
    GameSubtype.emotionRecognition: GameBriefing(
      title: "Sentiment Prober",
      icon: Icons.psychology_rounded,
      objective:
          "Identify the speaker's emotional state from their pitch and tone. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Navigate core",
        "Analyze pitch & rhythm",
        "Match exact sentiment",
      ],
      actionText: "Probe Sentiment",
      tip:
          "Rhythm, volume spikes, and sighing express more than literal words.",
    ),
    GameSubtype.detailSpotlight: GameBriefing(
      title: "Spotlight Search",
      icon: Icons.flashlight_on_rounded,
      objective:
          "Listen for specific names, numbers, or details within the passage. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: ["Scan details", "Listen for target keywords", "Identify match"],
      actionText: "Start Search",
      tip:
          "Note details as you listen—rushing to answer from memory can be tricky!",
    ),
    GameSubtype.listeningInference: GameBriefing(
      title: "Inference Lens",
      icon: Icons.biotech_rounded,
      objective:
          "Infer implications in the spoken passage that are not explicitly stated. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Read between waves",
        "Deduce the subtext",
        "Choose logical conclusion",
      ],
      actionText: "Focus Lens",
      tip:
          "Listen for hesitation or sarcasm—voice inflections hold crucial keys.",
    ),
    GameSubtype.ambientId: GameBriefing(
      title: "Spatial Anchor",
      icon: Icons.radar_rounded,
      objective:
          "Sharpen your situational awareness by identifying environments solely through their ambient soundscape, essential for real-world immersion. Mastering audio analysis helps you accurately understand native speakers in real-world conversations.",
      rules: [
        "Listen to background noise",
        "Scan the radar options",
        "Anchor the correct location",
      ],
      actionText: "Anchor Location",
      tip:
          "PRO TIP: Close your eyes and visualize the scene! Focus on ambient sounds like footsteps, echoes, wind, or humming machinery.",
    ),
    // 3. Reading
    GameSubtype.readAndAnswer: GameBriefing(
      title: "Insight Analyst",
      icon: Icons.fact_check_rounded,
      objective:
          "Read the passage and select correct answers to comprehension questions. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Refer back to text", "Verify every detail", "Think critically"],
      actionText: "Analyze Text",
      tip:
          "Don't guess! The answer is ALWAYS in the text—you just have to find it.",
    ),
    GameSubtype.findWordMeaning: GameBriefing(
      title: "Lexical Linker",
      icon: Icons.menu_book_rounded,
      objective:
          "Find and match word definitions directly within the passage context. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Analyze context", "Match word to meaning", "Build vocabulary"],
      actionText: "Link Words",
      tip:
          "Context is your best friend! The surrounding words often reveal hidden meanings.",
    ),
    GameSubtype.trueFalseReading: GameBriefing(
      title: "Truth Verifier",
      icon: Icons.verified_user_rounded,
      objective:
          "Determine if statements are true or false based on the text. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Locate the evidence", "Check for nuances", "Validate truth"],
      actionText: "Verify Truth",
      tip: "Be careful of 'absolute' words like 'always', 'never', or 'only'!",
    ),
    GameSubtype.sentenceOrderReading: GameBriefing(
      title: "Structure Architect",
      icon: Icons.architecture_rounded,
      objective:
          "Arrange scrambled sentences into their logical paragraph order. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Find the logic", "Check transitions", "Rebuild the system"],
      actionText: "Rebuild Flow",
      tip:
          "Look for transition words like 'however', 'moreover', and 'finally'.",
    ),
    GameSubtype.readingSpeedCheck: GameBriefing(
      title: "Velocity Reader",
      icon: Icons.speed_rounded,
      objective:
          "Test your reading speed and comprehension under a timer. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Read fast", "Maintain accuracy", "Beat the timer"],
      actionText: "Race Timer",
      tip:
          "Don't subvocalize (read out loud in your head)! Let your eyes glide over the text.",
    ),
    GameSubtype.guessTitle: GameBriefing(
      title: "Title Tactician",
      icon: Icons.title_rounded,
      objective:
          "Read the passage and choose the most appropriate title. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Identify main theme", "Check all options", "Summarize the core"],
      actionText: "Deduce Title",
      tip:
          "A great title captures the 'big picture'. Look for the most repeated themes!",
    ),
    GameSubtype.readAndMatch: GameBriefing(
      title: "Semantic Bridge",
      icon: Icons.bolt_rounded,
      objective:
          "Connect related facts and concepts from the reading passage. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Bridge the gaps", "Use lasers to link", "Confirm relationships"],
      actionText: "Bridge Gaps",
      tip:
          "Think about how concepts relate—is it cause and effect, or part and whole?",
    ),
    GameSubtype.paragraphSummary: GameBriefing(
      title: "Summary Sieve",
      icon: Icons.short_text_rounded,
      objective:
          "Select the single sentence that best summarizes the paragraph. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Filter out details", "Find the main point", "Stay objective"],
      actionText: "Summarize Now",
      tip:
          "Avoid sentences that only mention one small detail; look for the overarching idea!",
    ),
    GameSubtype.readingInference: GameBriefing(
      title: "Subtext Sleuth",
      icon: Icons.biotech_rounded,
      objective:
          "Identify implications in the text that are not explicitly stated. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Read between lines", "Detect subtext", "Infer correctly"],
      actionText: "Deduce Subtext",
      tip: "The author's tone and choice of words often hide a deeper meaning.",
    ),
    GameSubtype.readingConclusion: GameBriefing(
      title: "Logical Finisher",
      icon: Icons.last_page_rounded,
      objective:
          "Predict the most logical conclusion based on the reading text. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: ["Follow the logic", "Predict outcome", "Verify with evidence"],
      actionText: "Predict Final",
      tip:
          "Follow the clues the author left! Where does the logic naturally lead?",
    ),
    GameSubtype.clozeTest: GameBriefing(
      title: "Context Mastery",
      icon: Icons.format_color_text_rounded,
      objective:
          "Drag the correct word into the blank to complete the sentence. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: [
        "Read the full context",
        "Check the grammar fit",
        "Dock the word",
      ],
      actionText: "Fill Gaps",
      tip:
          "PRO TIP: Reading the surrounding words is crucial. Context gives away the required part of speech!",
    ),
    GameSubtype.skimmingScanning: GameBriefing(
      title: "Skim & Scan",
      icon: Icons.search_rounded,
      objective:
          "Scan the text fast to locate specific facts or main ideas. Mastering reading comprehension allows you to quickly extract key information in the real world.",
      rules: [
        "Speed is crucial",
        "Ignore filler words",
        "Locate specific data points",
      ],
      actionText: "Start Scanning",
      tip:
          "PRO TIP: Use your eyes like a radar! Hunt for capital letters or numbers first.",
    ),
    // 4. Writing
    GameSubtype.sentenceBuilder: GameBriefing(
      title: "Sentence Architect",
      icon: Icons.architecture_rounded,
      objective:
          "Arrange sentence fragments into a grammatically correct order. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Start with Subject",
        "Identify the Verb",
        "Check ending punctuation",
      ],
      actionText: "Build Sentence",
      tip: "PRO TIP: Start with the 'Who' or 'What', then find the 'Action'!",
    ),
    GameSubtype.completeSentence: GameBriefing(
      title: "Fragment Fixer",
      icon: Icons.healing_rounded,
      objective:
          "Launch the correct word fragment into the sentence gap. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Identify missing part",
        "Maintain the tone",
        "Verify logical structure",
      ],
      actionText: "Fix Fragment",
      tip:
          "PRO TIP: A complete sentence needs both a Subject and a Verb at minimum!",
    ),
    GameSubtype.describeSituationWriting: GameBriefing(
      title: "Context Scribe",
      icon: Icons.description_rounded,
      objective:
          "Tap the floating emojis to discover keywords and write a descriptive paragraph based on the scenario. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Tap emojis for keywords",
        "Use vivid adjectives",
        "Be specific & clear",
      ],
      actionText: "Scribe Scene",
      tip: "PRO TIP: Use sensory words! Describe what is seen, heard, or felt.",
    ),
    GameSubtype.fixTheSentence: GameBriefing(
      title: "Clarity Editor",
      icon: Icons.edit_rounded,
      objective:
          "Scrub the logical decay and select the correct replacement word. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Locate the error",
        "Scrub the decay away",
        "Select correct replacement",
      ],
      actionText: "Apply Edit",
      tip:
          "PRO TIP: Read the sentence out loud in your head! If it sounds clumsy, revise it.",
    ),
    GameSubtype.shortAnswerWriting: GameBriefing(
      title: "Briefing Pro",
      icon: Icons.short_text_rounded,
      objective:
          "Write a brief, concise, and direct response to the prompt using the required keywords. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Use all required keywords",
        "Check grammar and punctuation",
        "Write naturally and clearly",
      ],
      actionText: "Submit Answer",
      tip: "PRO TIP: Get straight to the point! Keep it short and accurate.",
    ),
    GameSubtype.opinionWriting: GameBriefing(
      title: "Vocal Pen",
      icon: Icons.rate_review_rounded,
      objective:
          "Analyze the statements and categorize them as supporting or opposing the given opinion. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: ["Read the prompt", "Weigh the arguments", "Balance the scale"],
      actionText: "Balance Scale",
      tip:
          "PRO TIP: A 'Pro' always supports the prompt's opinion, while a 'Con' highlights a drawback or opposing view.",
    ),
    GameSubtype.dailyJournal: GameBriefing(
      title: "Daily Chronicler",
      icon: Icons.auto_stories_rounded,
      objective:
          "Read the prompt and write a short personal journal reflection. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Be reflective",
        "Use appropriate tenses",
        "Focus on clear narrative",
      ],
      actionText: "Log Entry",
      tip:
          "PRO TIP: Use sequential markers like 'First', 'Later', and 'Eventually' to organize your thoughts.",
    ),
    GameSubtype.summarizeStoryWriting: GameBriefing(
      title: "Essence Extractor",
      icon: Icons.compress_rounded,
      objective:
          "Read the story and arrange the key events in chronological order to form a concise summary. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Read carefully",
        "Sequence the events",
        "Exclude incorrect details",
      ],
      actionText: "Summarize Now",
      tip:
          "PRO TIP: A good summary only includes events that actually happened in the story!",
    ),
    GameSubtype.writingEmail: GameBriefing(
      title: "Email Expert",
      icon: Icons.alternate_email_rounded,
      objective:
          "Compose a professional and contextually appropriate email by arranging its key parts. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Use right greeting",
        "State clear purpose",
        "Use formal closing",
      ],
      actionText: "Send Mail",
      tip:
          "PRO TIP: Clear subject lines and direct greetings set the professional tone.",
    ),
    GameSubtype.correctionWriting: GameBriefing(
      title: "Syntax Auditor",
      icon: Icons.fact_check_rounded,
      objective:
          "Identify and replace the errored syntax phrase. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Identify the error",
        "Select correct syntax",
        "Ensure 100% accuracy",
      ],
      actionText: "Audit Syntax",
      tip:
          "PRO TIP: Read the sentence out loud in your head! Clunky phrasing often reveals the grammatical flaw.",
    ),
    GameSubtype.essayDrafting: GameBriefing(
      title: "Essay Architect",
      icon: Icons.article_rounded,
      objective:
          "Sequence the paragraph blocks into their correct logical structure. Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Find the opening claim",
        "Sequence supporting reasons",
        "Lock the structural blueprint",
      ],
      actionText: "Construct Blueprint",
      tip: "PRO TIP: Ensure each body paragraph has a clear topic sentence.",
    ),
    // 5. Grammar
    GameSubtype.grammarQuest: GameBriefing(
      title: "Grammar Core",
      icon: Icons.gavel_rounded,
      objective:
          "Identify and choose the correct form to complete the sentence. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: ["Identify errors", "Choose the correction", "Master the rules"],
      actionText: "Fix Structure",
      tip:
          "PRO TIP: Read the sentence out loud in your head! Often, you can 'hear' if a rule is broken.",
    ),
    GameSubtype.sentenceCorrection: GameBriefing(
      title: "Error Auditor",
      icon: Icons.spellcheck_rounded,
      objective:
          "Scan the text for grammatical errors, apply the correct fix, then type the corrected sentence to lock it in. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: ["Find the glitch", "Apply the fix", "Type to confirm answer"],
      actionText: "Audit Text",
      tip:
          "PRO TIP: Focus on subject-verb agreement first—it's the most common source of errors!",
    ),
    GameSubtype.wordReorder: GameBriefing(
      title: "Syntax Reorder",
      icon: Icons.reorder_rounded,
      objective:
          "Arrange scrambled words into a grammatically sound sentence. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Identify the subject",
        "Find the main verb",
        "Arrange complements",
      ],
      actionText: "Align Syntax",
      tip:
          "PRO TIP: Adjectives usually come before nouns, and adverbs often follow verbs.",
    ),
    GameSubtype.tenseMastery: GameBriefing(
      title: "Tense Mastery",
      icon: Icons.history_toggle_off_rounded,
      objective:
          "Select or place verbs in their correct chronological tenses. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Check for time markers",
        "Identify frequency",
        "3 Hearts per mission",
      ],
      actionText: "Master Tenses",
      tip:
          "PRO TIP: Look for 'Signal Words'! 'Since' often needs Perfect, while 'Usually' needs Present.",
    ),
    GameSubtype.partsOfSpeech: GameBriefing(
      title: "Lexical Anatomy",
      icon: Icons.category_rounded,
      objective:
          "Identify and label the correct parts of speech in the sentence. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Analyze word function",
        "Categorize correctly",
        "Build structure",
      ],
      actionText: "Identify Role",
      tip:
          "PRO TIP: If it's an action, it's a verb. If it's a person/place/thing, it's a noun.",
    ),
    GameSubtype.subjectVerbAgreement: GameBriefing(
      title: "Agreement Sync",
      icon: Icons.sync_rounded,
      objective:
          "Choose the correct verb form to match the subject. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Identify subject",
        "Check singular vs plural",
        "Match verb form",
      ],
      actionText: "Sync Agreement",
      tip:
          "PRO TIP: Watch out for 'distractors'—prepositional phrases that sit between subject and verb!",
    ),
    GameSubtype.clauseConnector: GameBriefing(
      title: "Clause Linker",
      icon: Icons.link_rounded,
      objective:
          "Choose the appropriate conjunction to connect the clauses. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Analyze relationship",
        "Choose the connector",
        "Ensure logical flow",
      ],
      actionText: "Link Clauses",
      tip:
          "PRO TIP: Use 'Because' for reasons, 'Although' for contrast, and 'While' for simultaneous actions.",
    ),
    GameSubtype.voiceSwap: GameBriefing(
      title: "Voice Swap",
      icon: Icons.swap_horiz_rounded,
      objective:
          "Switch between Active and Passive voice without changing the meaning, then type the structure to confirm. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Identify the agent",
        "Change the verb form",
        "Type the sentence to confirm",
      ],
      actionText: "Swap Voice",
      tip:
          "PRO TIP: In Passive voice, the object becomes the star! Use 'by [someone]' only if needed.",
    ),
    GameSubtype.questionFormatter: GameBriefing(
      title: "Inquiry Logic",
      icon: Icons.help_outline_rounded,
      objective:
          "Arrange words or choose forms to create an accurate question. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: ["Invert subject/verb", "Add auxiliary verbs", "Match the tense"],
      actionText: "Format Inquiry",
      tip:
          "PRO TIP: Remember the 'Qu-A-S-V' rule: Question word, Auxiliary, Subject, Verb!",
    ),
    GameSubtype.articleInsertion: GameBriefing(
      title: "Article Orb",
      icon: Icons.bubble_chart_rounded,
      objective:
          "Insert the correct article to complete the sentence structure and specify the noun. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Read the sentence context",
        "Check if noun is specific",
        "Pop matching article orb",
      ],
      actionText: "Pop Orb",
      tip:
          "PRO TIP: Use 'the' for specific items, 'a/an' for general ones, and listen for vowel sounds!",
    ),
    GameSubtype.modifierPlacement: GameBriefing(
      title: "Modifier Map",
      icon: Icons.location_on_rounded,
      objective:
          "Place modifiers in the correct position to clarify the sentence. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Avoid dangling modifiers",
        "Link to target word",
        "Clear the meaning",
      ],
      actionText: "Map Modifiers",
      tip:
          "PRO TIP: Place the modifier as close as possible to the word it's describing!",
    ),
    GameSubtype.modalsSelection: GameBriefing(
      title: "Modal Matrix",
      icon: Icons.grid_view_rounded,
      objective:
          "Select the modal verb that best fits the sentence's context. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Analyze the mood",
        "Check for permission/duty",
        "Match the strength",
      ],
      actionText: "Select Modal",
      tip:
          "PRO TIP: 'Must' is for strong obligation, while 'Should' is for friendly advice.",
    ),
    GameSubtype.prepositionChoice: GameBriefing(
      title: "Position Pro",
      icon: Icons.directions_rounded,
      objective:
          "Choose the correct preposition to complete the sentence. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Analyze spatial data",
        "Check time markers",
        "Verify collocations",
      ],
      actionText: "Choose Position",
      tip:
          "PRO TIP: Use 'In' for large spaces, 'On' for surfaces, and 'At' for specific points.",
    ),
    GameSubtype.pronounResolution: GameBriefing(
      title: "Pronoun Pivot",
      icon: Icons.people_rounded,
      objective:
          "Select the correct pronoun that clearly resolves the sentence. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Find the antecedent",
        "Match gender & number",
        "Avoid ambiguity",
      ],
      actionText: "Resolve Pivot",
      tip:
          "PRO TIP: If there are two people, 'he' can be confusing. Use their names or clear markers!",
    ),
    GameSubtype.punctuationMastery: GameBriefing(
      title: "Symbol Scribe",
      icon: Icons.short_text_rounded,
      objective:
          "Place commas, periods, or semi-colons in the correct locations. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Separate list items",
        "Connect related ideas",
        "Define boundaries",
      ],
      actionText: "Scribe Symbols",
      tip:
          "PRO TIP: Use a comma before 'and' only in long lists or between independent clauses!",
    ),
    GameSubtype.relativeClauses: GameBriefing(
      title: "Relative Rail",
      icon: Icons.linear_scale_rounded,
      objective:
          "Use relative pronouns (who, which, that) to connect the clauses. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: ["Identify the noun", "Choose the pronoun", "Link the detail"],
      actionText: "Link Relative",
      tip:
          "PRO TIP: Use 'Who' for people and 'Which' or 'That' for things and animals.",
    ),
    GameSubtype.conditionals: GameBriefing(
      title: "If-Logic",
      icon: Icons.alt_route_rounded,
      objective:
          "Complete the conditional sentence and type the final structure to lock it in. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Identify the condition",
        "Match the tense sequence",
        "Type the clause to confirm",
      ],
      actionText: "Solve Logic",
      tip:
          "PRO TIP: In 'Second Conditional' (imaginary), use 'If I WERE' even for singular subjects!",
    ),
    GameSubtype.conjunctions: GameBriefing(
      title: "Logic Junction",
      icon: Icons.join_inner_rounded,
      objective:
          "Select the correct conjunction to bridge the thoughts. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Compare/Contrast ideas",
        "Identify cause/effect",
        "Connect the flow",
      ],
      actionText: "Join Junction",
      tip: "PRO TIP: Remember 'FANBOYS': For, And, Nor, But, Or, Yet, So!",
    ),
    GameSubtype.directIndirectSpeech: GameBriefing(
      title: "Speech Shift",
      icon: Icons.forum_rounded,
      objective:
          "Convert direct quotes into reported speech with correct tenses, then type the final sentence to verify. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Shift tenses backward",
        "Update time markers",
        "Type the sentence to confirm",
      ],
      actionText: "Report Speech",
      tip:
          "PRO TIP: 'Present' becomes 'Past'! If someone said 'I am here', report 'they were there'.",
    ),
    // 6. Vocabulary
    GameSubtype.flashcards: GameBriefing(
      title: "Flashcards",
      icon: Icons.style_rounded,
      objective:
          "Tap to flip flashcards and swipe through to master terms. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: ["Tap to flip", "Swipe Right = Known", "Swipe Left = Review"],
      actionText: "Master Now",
      tip:
          "Speed isn't the goal—mastery is! Take your time to review definitions.",
    ),
    GameSubtype.synonymSearch: GameBriefing(
      title: "Synonym Warp",
      icon: Icons.cyclone,
      objective:
          "Identify the exact same meaning for the target word. Learning multiple words for the same idea gives your speaking and writing much more color and variety.",
      rules: ["Find the twin word", "Warp the correct match", "Ignore visual tricks"],
      actionText: "Start Warp",
      tip: "Don't get tricked by words that just look similar. Focus entirely on the core meaning!",
    ),
    GameSubtype.antonymSearch: GameBriefing(
      title: "Polarity Master",
      icon: Icons.electrical_services_rounded,
      objective:
          "Identify the exact opposite meaning of the target word. Searching for opposites builds a flexible vocabulary, helping you sound much more expressive in real-world conversations.",
      rules: ["Find the opposite word", "Match to opposite pole", "Don't fall for synonyms"],
      actionText: "Start Search",
      tip: "Think magnetically: Opposite meaning goes to the opposite glowing pole!",
    ),
    GameSubtype.contextClues: GameBriefing(
      title: "Detective Lens",
      icon: Icons.search_rounded,
      objective:
          "Use context clues to identify the meaning of unknown words. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: ["Drag to reveal clues", "Analyze context", "3 Hearts left"],
      actionText: "Start Scan",
      tip: "Clues often hide right next to the redacted or highlighted word!",
    ),
    GameSubtype.phrasalVerbs: GameBriefing(
      title: "Verb Vault",
      icon: Icons.vpn_key_rounded,
      objective:
          "Select correct prepositions or particles to complete phrasal verbs. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: ["Read Definition", "Select Particle", "Crack Vault"],
      actionText: "Start Hack",
      tip:
          "Particles change everything! 'Turn up' has a completely different meaning than 'turn down'.",
    ),
    GameSubtype.idioms: GameBriefing(
      title: "Emojify",
      icon: Icons.forum_rounded,
      objective:
          "Decode emojis and phrases into correct English idioms. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: ["Interpret emojis", "Select matching idiom", "3 Hearts left"],
      actionText: "Send Message",
      tip: "Idioms are colorful cultural keys! Don't take them literally.",
    ),
    GameSubtype.academicWord: GameBriefing(
      title: "Thesis Thrust",
      icon: Icons.auto_stories_rounded,
      objective:
          "Read the context carefully and select the advanced vocabulary word that fits perfectly. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: [
        "Read the passage",
        "Analyze the context",
        "Drag the correct word",
      ],
      actionText: "Initiate Thrust",
      tip:
          "PRO TIP: Academic words are highly precise—pay attention to logical hints in the surrounding text!",
    ),
    GameSubtype.topicVocab: GameBriefing(
      title: "Word Sorter",
      icon: Icons.category_rounded,
      objective:
          "Sort words into the correct topic. Grouping words together makes them much easier to remember for real-world conversations.",
      rules: ["Look at the new word", "Swipe it to the right topic", "Sort them all to win"],
      actionText: "Start Sorting",
      tip: "PRO TIP: Try to picture the word in your mind before swiping it into the category!",
    ),
    GameSubtype.wordFormation: GameBriefing(
      title: "Word Builder",
      icon: Icons.science_rounded,
      objective:
          "Read the meaning closely and build the exact word it describes by adding the right ending to the root word. Mastering word construction unlocks a massive new vocabulary for you!",
      rules: ["Read the meaning", "Choose the right ending", "Build the new word"],
      actionText: "Start Building",
      tip: "Think about what kind of word you need—like a person, a feeling, or an action—before choosing the ending!",
    ),
    GameSubtype.prefixSuffix: GameBriefing(
      title: "Word Builder",
      icon: Icons.spa_rounded,
      objective:
          "Carefully analyze the root word and attach the correct prefix or suffix. Understanding how word parts connect is a powerful way to instantly grow your vocabulary!",
      rules: ["Read the meaning", "Find the matching affix", "Drag to connect"],
      actionText: "Start Building",
      tip:
          "PRO TIP: Look closely at the meaning first! A small prefix like 're-' completely changes the word.",
    ),
    GameSubtype.collocations: GameBriefing(
      title: "Pair Pop",
      icon: Icons.bubble_chart_rounded,
      objective:
          "Match words that naturally pair together (e.g., 'make a decision'). Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: ["Analyze anchor", "Select partner bubble", "Fuse the pair"],
      actionText: "Initiate Fusion",
      tip:
          "Collocations are words that naturally go together like peanut butter and jelly!",
    ),
    GameSubtype.contextualUsage: GameBriefing(
      title: "Usage Unfold",
      icon: Icons.auto_stories_rounded,
      objective:
          "Identify the word that fits perfectly in the context of the sentence. Expanding your vocabulary helps you express your thoughts precisely in everyday scenarios.",
      rules: ["Evaluate context", "Unfold the correct fit", "3 Hearts left"],
      actionText: "Unfold Truth",
      tip:
          "Nuance is key! Choose the word that logically belongs in the sentence.",
    ),

    // 7. Accent
    GameSubtype.intonationMimic: GameBriefing(
      title: "Intonation Mimic",
      icon: Icons.waves_rounded,
      objective:
          "Listen to the sentence and identify its pitch pattern to master the natural melody of the language Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the sentence",
        "Analyze pitch direction",
        "Choose correct intonation",
      ],
      actionText: "Start Mimicking",
      tip:
          "PRO TIP: Questions often rise at the end, while statements usually fall. Listen closely to the final word!",
    ),
    GameSubtype.syllableStress: GameBriefing(
      title: "Stress Spotter",
      icon: Icons.priority_high_rounded,
      objective:
          "Identify the stressed syllable in the spoken word by tapping the correct drum pad. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen for the loud part",
        "Check the length",
        "Select the stressed part",
      ],
      actionText: "Find Stress",
      tip:
          "PRO TIP: The stressed part of a word is always louder and slightly longer.",
    ),

    GameSubtype.vowelDistinction: GameBriefing(
      title: "Vowel Distinction",
      icon: Icons.tune_rounded,
      objective:
          "Isolate subtle English vowel phonemes, select the exact match, then speak it aloud to solidify your pronunciation. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the target word",
        "Select the exact match",
        "Speak to confirm your answer",
      ],
      actionText: "Identify Sound",
      tip:
          "PRO TIP: Pay attention to whether the vowel feels short and relaxed, or long and tense!",
    ),

    GameSubtype.speedVariance: GameBriefing(
      title: "Speed Variance",
      icon: Icons.speed_rounded,
      objective:
          "Listen carefully and identify the speaking speed of the phrase. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the phrase",
        "Analyze the tempo",
        "Select the correct speed",
      ],
      actionText: "Identify Speed",
      tip:
          "PRO TIP: Pay attention to whether the speaker is rushing or speaking carefully to emphasize a point!",
    ),
    GameSubtype.dialectDrill: GameBriefing(
      title: "Dialect Drill",
      icon: Icons.public_rounded,
      objective:
          "Identify and distinguish regional pronunciations to master global communication. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: ["Listen closely", "Compare pronunciations", "Select region"],
      actionText: "Start Drill",
      tip:
          "PRO TIP: Pay attention to vowel shapes! American English often flattens vowels, while British English rounds them.",
    ),
    GameSubtype.connectedSpeech: GameBriefing(
      title: "Connected Speech",
      icon: Icons.settings_input_composite_rounded,
      objective:
          "Listen closely to how the words connect, choose the correct sound change, then speak the phrase aloud to confirm. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: [
        "Listen to the linked words",
        "Select the rule that applies",
        "Speak to confirm your answer",
      ],
      actionText: "Connect Words",
      tip:
          "PRO TIP: Try saying the words fast yourself! If you force every single letter, it feels unnatural. Real speech takes shortcuts.",
    ),
    // 8. Roleplay
    GameSubtype.branchingDialogue: GameBriefing(
      title: "Social Simulator",
      icon: Icons.forum_rounded,
      objective:
          "Tap an answer or drag the decision probe to select the most natural, context-appropriate conversational response. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Analyze the scene", "Select your response", "Speak to confirm"],
      actionText: "Enter Simulation",
      tip:
          "PRO TIP: Pay attention to the subtle social cues! Being polite and direct often opens the right doors.",
    ),
    GameSubtype.situationalResponse: GameBriefing(
      title: "Reflex Responder",
      icon: Icons.flash_on_rounded,
      objective:
          "Choose the most appropriate and polite social response for the scenario. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Match social tone", "Be polite/direct", "3 Hearts left"],
      actionText: "Respond Now",
      tip:
          "PRO TIP: Use expressions like 'I would appreciate it' or 'Would you mind'!",
    ),
    GameSubtype.jobInterview: GameBriefing(
      title: "Career Closer",
      icon: Icons.business_center_rounded,
      objective:
          "Choose professional responses to nail your high-stakes job interview. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Be professional", "Select the best answer", "Speak to confirm"],
      actionText: "Start Interview",
      tip:
          "PRO TIP: Frame replies to show how your experience solves their business needs.",
    ),
    GameSubtype.medicalConsult: GameBriefing(
      title: "Health Liaison",
      icon: Icons.medical_services_rounded,
      objective:
          "Clearly explain symptoms or follow a doctor's detailed instructions. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Be accurate", "Describe physical feelings", "3 Hearts left"],
      actionText: "Start Consult",
      tip:
          "PRO TIP: Use specific descriptors like 'throbbing', 'sharp', or 'dull ache'.",
    ),
    GameSubtype.gourmetOrder: GameBriefing(
      title: "Order Master",
      icon: Icons.restaurant_rounded,
      objective:
          "Order food, request custom adjustments, and settle restaurant bills. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: [
        "Be highly polite",
        "Check details carefully",
        "Communicate clearly",
      ],
      actionText: "Place Order",
      tip:
          "PRO TIP: Using 'Could I get...' is the preferred way to place polite orders.",
    ),
    GameSubtype.travelDesk: GameBriefing(
      title: "Global Traveler",
      icon: Icons.flight_takeoff_rounded,
      objective:
          "Manage check-ins, navigate directions, and handle hotel booking requests. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Check travel tickets", "Follow directions", "Ask for support"],
      actionText: "Start Journey",
      tip:
          "PRO TIP: Confirm directions by repeating them back to check understanding.",
    ),
    GameSubtype.conflictResolver: GameBriefing(
      title: "Peace Maker",
      icon: Icons.handshake_rounded,
      objective:
          "Resolve conversational arguments and misunderstandings using tactful words. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: [
        "Use 'I' statements",
        "Acknowledge feelings",
        "Find middle ground",
      ],
      actionText: "Resolve Conflict",
      tip:
          "PRO TIP: De-escalate early by validating their perspective before replying.",
    ),
    GameSubtype.elevatorPitch: GameBriefing(
      title: "Pitch Perfect",
      icon: Icons.rocket_launch_rounded,
      objective:
          "Deliver a compelling, high-impact business message in 30 seconds. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Be concise", "High emotional impact", "3 Hearts left"],
      actionText: "Start Pitch",
      tip:
          "PRO TIP: Lead with a massive hook that frames a relatable daily problem.",
    ),
    GameSubtype.socialSpark: GameBriefing(
      title: "Charisma Core",
      icon: Icons.celebration_rounded,
      objective:
          "Initiate and sustain engaging small talk with new acquaintances. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: [
        "Ask open questions",
        "Show high interest",
        "Keep the tone light",
      ],
      actionText: "Spark Talk",
      tip:
          "PRO TIP: Ask 'what' or 'how' to keep the conversational partner sharing.",
    ),
    GameSubtype.emergencyHub: GameBriefing(
      title: "Emergency Voice",
      icon: Icons.emergency_share_rounded,
      objective:
          "Communicate clearly and stay calm under pressure in crisis scenarios. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Stay highly calm", "State location first", "Be exact & concise"],
      actionText: "Help Now",
      tip:
          "PRO TIP: Clear, slow, and specific directions save lives in critical moments.",
    ),
    // 9. Elite Mastery
    GameSubtype.storyBuilder: GameBriefing(
      title: "Story Builder",
      icon: Icons.reorder_rounded,
      objective:
          "Arrange the scrambled sentences into the correct logical order to master paragraph cohesion Mastering this skill ensures your written communication is clear, professional, and effective.",
      rules: [
        "Identify the starting sentence",
        "Look for logical transitions",
        "Build a cohesive paragraph",
      ],
      actionText: "Build Story",
      tip:
          "PRO TIP: Look for transition words like 'However' or 'Therefore' to link sentences!",
    ),

    GameSubtype.accentShadowing: GameBriefing(
      title: "Accent Shadowing",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Speak clearly to match the exact accent and rhythm of the speaker. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: ["Listen to the example", "Record your voice", "Match the accent"],
      actionText: "Start Shadowing",
      tip:
          "PRO TIP: Pay close attention to which syllables are stressed—it makes a huge difference!",
    ),
  };

  static GameBriefing? _getKidsBriefing(String category) {
    switch (category.toLowerCase()) {
      case 'alphabet':
        return const GameBriefing(
          title: "Alphabet Adventure",
          icon: Icons.abc_rounded,
          objective:
              "Let's unlock the magic of letters! Tap the mystery box to hear the hidden sound, and stick the correct letter onto the chalkboard.",
          rules: [
            "Listen to the phonetic sound",
            "Find the matching letter",
            "Place it on the board",
          ],
          actionText: "Play ABCs",
          tip:
              "PRO TIP: Listen closely! The phonetic sound will guide you to the right letter. 🎵",
        );
      case 'animals':
        return const GameBriefing(
          title: "Animal Safari",
          icon: Icons.pets_rounded,
          objective:
              "It's safari time! We need to identify the hidden animal. Read the field notes on the clipboard and hand the right tag to the explorer.",
          rules: [
            "Read the animal field notes",
            "Look for hidden clues",
            "Tag the correct species",
          ],
          actionText: "Go Safari",
          tip:
              "PRO TIP: Think about the sound the animal makes or where it lives! 🦁",
        );
      case 'numbers':
        return const GameBriefing(
          title: "Number Fun",
          icon: Icons.numbers_rounded,
          objective:
              "Houston, we are ready for liftoff! Look out the rocket window to read the clues, and lock the matching planet into the ship.",
          rules: [
            "Read the space clues",
            "Find the matching number",
            "Lock it into the rocket",
          ],
          actionText: "Start Counting",
          tip: "PRO TIP: Count the items carefully if you need to! 🚀",
        );
      case 'colors':
        return const GameBriefing(
          title: "Rainbow World",
          icon: Icons.palette_rounded,
          objective:
              "Time to paint a masterpiece! Look at the easel to see what color we are mixing, and squeeze the right paint tube onto the canvas.",
          rules: [
            "Check the requested color",
            "Find the matching tube",
            "Squeeze the paint",
          ],
          actionText: "Paint Colors",
          tip:
              "PRO TIP: Colors are everywhere! Think about the color of the sky or grass. 🎨",
        );
      case 'fruits':
        return const GameBriefing(
          title: "Fruit Garden",
          icon: Icons.shopping_basket_rounded,
          objective:
              "Let's harvest some yummy treats! Check the wooden sign to see what fruit we need, and pack it safely into the picnic basket.",
          rules: [
            "Identify the fresh fruit",
            "Pick the matching shape",
            "Pack it in the basket",
          ],
          actionText: "Pick Fruits",
          tip:
              "PRO TIP: Fruits can be sweet or sour. Think about how they taste! 🍎",
        );
      case 'shapes':
        return const GameBriefing(
          title: "Shape Explorer",
          icon: Icons.category_rounded,
          objective:
              "Let's learn about geometry! Look closely at the notebook to see which shape we need, and place the right block on the desk.",
          rules: [
            "Count the edges carefully",
            "Match the silhouette",
            "Drop the shape in place",
          ],
          actionText: "Explore Shapes",
          tip: "PRO TIP: Count the corners or edges if you are stuck! 📐",
        );
      case 'body_parts':
        return const GameBriefing(
          title: "My Body",
          icon: Icons.accessibility_new_rounded,
          objective:
              "Time for a quick checkup! Read the symptoms on the doctor's clipboard, and place the healing bandage on the correct body part.",
          rules: [
            "Read the medical clues",
            "Identify the body part",
            "Apply the bandage",
          ],
          actionText: "Start Learning",
          tip: "PRO TIP: Can you point to that body part on yourself? 🧍",
        );
      case 'family':
        return const GameBriefing(
          title: "Family Tree",
          icon: Icons.family_restroom_rounded,
          objective:
              "Let's build our family history! Check the grand banner to see who we are looking for, and hang their portrait on the family tree.",
          rules: [
            "Read the family title",
            "Find the right relative",
            "Hang the portrait",
          ],
          actionText: "Meet Family",
          tip:
              "PRO TIP: Family words show how people are related, like brother or sister! ❤️",
        );
      case 'food':
        return const GameBriefing(
          title: "Yummy Food",
          icon: Icons.restaurant_rounded,
          objective:
              "Order up! The customers are hungry. Read the order on the restaurant menu, and serve the correct yummy dish onto the plate.",
          rules: [
            "Read the hungry order",
            "Find the tasty dish",
            "Serve it on the plate",
          ],
          actionText: "Eat Up",
          tip:
              "PRO TIP: Think about what you eat for breakfast, lunch, or dinner! 🥛",
        );
      case 'clothing':
        return const GameBriefing(
          title: "Dress Up",
          icon: Icons.checkroom_rounded,
          objective:
              "Let's get dressed for the day! Look at the mirror to see what the weather is like, and put the perfect outfit into the wardrobe.",
          rules: [
            "Check the weather clue",
            "Pick the right outfit",
            "Hang it in the closet",
          ],
          actionText: "Get Dressed",
          tip:
              "PRO TIP: Think about what you wear when it's hot or cold outside! 👕",
        );
      case 'nature':
        return const GameBriefing(
          title: "Nature Walk",
          icon: Icons.forest_rounded,
          objective:
              "Let's go on a wilderness adventure! Read the wooden trail sign, and collect the correct piece of nature on the tree stump.",
          rules: [
            "Read the nature guide",
            "Find the forest item",
            "Collect it on the stump",
          ],
          actionText: "Start Walk",
          tip:
              "PRO TIP: Look outside! Nature is everything that grows and lives outside. 🌳",
        );
      case 'transport':
        return const GameBriefing(
          title: "Zoom Zoom!",
          icon: Icons.directions_car_rounded,
          objective:
              "Beep beep! Let's manage the city traffic. Read the directions on the asphalt, and guide the correct vehicle to the intersection.",
          rules: [
            "Read the travel clues",
            "Spot the right vehicle",
            "Guide it to the road",
          ],
          actionText: "Start Engine",
          tip:
              "PRO TIP: Think about whether it goes on land, in the water, or in the sky! 🚗",
        );
      case 'emotions':
        return const GameBriefing(
          title: "Feeling Happy",
          icon: Icons.mood_rounded,
          objective:
              "How are you feeling today? Read the feelings banner, and help the actor put on the correct emotion mask on the stage.",
          rules: [
            "Read the feeling word",
            "Find the matching expression",
            "Put on the mask",
          ],
          actionText: "Share Feelings",
          tip:
              "PRO TIP: Try making that face in a mirror to see how it feels! 😊",
        );
      case 'school':
        return const GameBriefing(
          title: "School Days",
          icon: Icons.school_rounded,
          objective:
              "Ring ring, time for class! Check the teacher's notepad, and pack the correct school supply onto your desk.",
          rules: [
            "Check the supply list",
            "Find your school tool",
            "Place it on the desk",
          ],
          actionText: "Go to School",
          tip: "PRO TIP: Think about what you carry in your backpack! 🎒",
        );
      case 'home':
        return const GameBriefing(
          title: "My Sweet Home",
          icon: Icons.home_rounded,
          objective:
              "Let's decorate our dream house! Read the architect's blueprint, and move the correct piece of furniture into the home.",
          rules: [
            "Read the room blueprint",
            "Find the furniture box",
            "Move it into the house",
          ],
          actionText: "Enter House",
          tip:
              "PRO TIP: Think about which room you would find this item in! 🏠",
        );
      case 'opposites':
        return const GameBriefing(
          title: "Big and Small",
          icon: Icons.compare_rounded,
          objective:
              "Let's find the perfect balance! Read the clue on the golden scale, and drop the exact opposite word to level it out.",
          rules: [
            "Read the starting word",
            "Think of its total opposite",
            "Balance the scale",
          ],
          actionText: "Match Pairs",
          tip:
              "PRO TIP: Opposites are totally different, like Hot and Cold! 🧊",
        );
      case 'verbs':
        return const GameBriefing(
          title: "Action Time!",
          icon: Icons.directions_run_rounded,
          objective:
              "Get ready for the big game! Look at the jumbotron scoreboard, and throw the correct action-word sports ball into the stadium.",
          rules: [
            "Read the action word",
            "Find the matching ball",
            "Throw it in the stadium",
          ],
          actionText: "Get Active",
          tip: "PRO TIP: A verb is something you can DO, like jump or run! 🏃",
        );
      case 'prepositions':
        return const GameBriefing(
          title: "Where is it?",
          icon: Icons.location_on_rounded,
          objective:
              "Let's go on a treasure hunt! Read the directional banner, and drop the correct arrow block onto the treasure map.",
          rules: [
            "Read the position clue",
            "Find the matching arrow",
            "Place it on the map",
          ],
          actionText: "Find It",
          tip:
              "PRO TIP: Think about where things are placed, like IN a box or ON a table! 📦",
        );
      case 'handwriting':
        return const GameBriefing(
          title: "Write and Learn",
          icon: Icons.draw_rounded,
          objective:
              "Unlock your magic pen! Follow the glowing arrows to trace the letter perfectly on the chalkboard.",
          rules: [
            "Follow the glowing arrows",
            "Trace inside the lines",
            "Write the letter yourself",
          ],
          actionText: "Start Writing",
          tip:
              "PRO TIP: Take your time and stay inside the lines to unlock the magic! ✨",
        );
      case 'routine':
        return const GameBriefing(
          title: "My Daily Day",
          icon: Icons.today_rounded,
          objective:
              "Let's plan a healthy day! Check the alarm clock to see what time it is, and stick the right daily habit on your calendar.",
          rules: [
            "Check the time of day",
            "Find the healthy habit",
            "Stick it on the schedule",
          ],
          actionText: "Start Day",
          tip:
              "PRO TIP: Think about what you do when you wake up or go to bed! 🪥",
        );
      case 'phonics':
        return const GameBriefing(
          title: "Sound Master",
          icon: Icons.record_voice_over_rounded,
          objective:
              "Turn up the volume! Read the phonetic clue on the speaker, and plug the matching sound wave into the amplifier.",
          rules: [
            "Read the sound blend",
            "Find the matching wave",
            "Plug it into the amp",
          ],
          actionText: "Make Sounds",
          tip:
              "PRO TIP: Say the sound out loud to help you find the right match! 🗣️",
        );
      case 'time':
        return const GameBriefing(
          title: "Tick Tock!",
          icon: Icons.access_time_rounded,
          objective:
              "Tick tock! Look at the time on the chalkboard, and strap the matching digital clock onto the smartwatch.",
          rules: [
            "Read the chalkboard time",
            "Find the matching digital clock",
            "Strap it to the watch",
          ],
          actionText: "Check Time",
          tip: "PRO TIP: Remember, 12:00 can be noon or midnight! ⏰",
        );
      case 'day_night':
        return const GameBriefing(
          title: "Sun and Moon",
          icon: Icons.brightness_6_rounded,
          objective:
              "Look up at the sky! Peer through the telescope to read the clue, and switch the window to show the correct time of day.",
          rules: [
            "Read the sky clue",
            "Decide if it's day or night",
            "Switch the window scene",
          ],
          actionText: "Switch Sky",
          tip: "PRO TIP: Does this happen when it's sunny or dark outside? 🌙",
        );
      case 'weather':
        return const GameBriefing(
          title: "Sky Explorer",
          icon: Icons.cloud_rounded,
          objective:
              "Let's become a meteorologist! Read the weather report on the billboard, and float the correct cloud into the sky.",
          rules: [
            "Read the weather report",
            "Find the matching cloud",
            "Float it into the sky",
          ],
          actionText: "Check Sky",
          tip: "PRO TIP: Think about what you wear when it rains or snows! ☁️",
        );
      case 'professions':
        return const GameBriefing(
          title: "Community Helpers",
          icon: Icons.work_rounded,
          objective:
              "Meet our community heroes! Read the job description on the building, and pin the correct worker badge to the town board.",
          rules: [
            "Read the job description",
            "Find the right worker",
            "Pin their badge",
          ],
          actionText: "Go to Work",
          tip:
              "PRO TIP: Think about what this person does to help the town! 👩‍🚒",
        );
      default:
        return null;
    }
  }

  static GameBriefing getDefaultBriefing(String title) {
    return GameBriefing(
      title: title,
      icon: Icons.extension_rounded,
      objective:
          "Complete the challenge to earn rewards and master your skills!",
      rules: [
        "3 Hearts per mission",
        "2 Strikes (Mistakes Re-queued)",
        "Achieve 100% Mastery",
      ],
      actionText: "Start Quest",
      tip:
          "PRO TIP: Stay focused and listen to your buddy! They have the answers you need.",
    );
  }
}

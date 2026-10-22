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
    final baseBriefing = _getBaseBriefing(type, fallbackTitle, level: level);

    final baseKey =
        type?.name ??
        fallbackTitle?.toLowerCase().replaceAll(' ', '_') ??
        "default";
    final isLevel100 = level == 100;
    final prefix = isLevel100
        ? 'instructions.$baseKey.level_100'
        : 'instructions.$baseKey';

    final title = context.tr(
      '$prefix.title',
      fallback: context.tr(
        'instructions.$baseKey.title',
        fallback: baseBriefing.title,
      ),
    );
    final objective = context.tr(
      '$prefix.objective',
      fallback: context.tr(
        'instructions.$baseKey.objective',
        fallback: baseBriefing.objective,
      ),
    );
    final actionText = context.tr(
      '$prefix.actionText',
      fallback: context.tr(
        'instructions.$baseKey.actionText',
        fallback: baseBriefing.actionText,
      ),
    );

    final rawTip = context.tr(
      '$prefix.tip',
      fallback: context.tr(
        'instructions.$baseKey.tip',
        fallback: baseBriefing.tip,
      ),
    );
    final tip = rawTip;

    final translatedRules = baseBriefing.rules
        .asMap()
        .entries
        .map(
          (e) => context.tr(
            '$prefix.rule_${e.key}',
            fallback: context.tr(
              'instructions.$baseKey.rule_${e.key}',
              fallback: e.value,
            ),
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
    String? fallbackTitle, {
    int level = 1,
  }) {
    if (type == null) {
      if (fallbackTitle != null) {
        final kidsBriefing = _getKidsBriefing(fallbackTitle, level: level);
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
              "Record yourself! Comparing your pitch to the model helps master the natural rhythm.",
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
              "Close your eyes! Focusing on pure sound helps catch subtle phoneme changes.",
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
              "Scan for keywords first! Don't get stuck on one word; focus on the overall message.",
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
              "Start with the verb! Finding the action helps the rest of the sentence fall into place.",
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
              "Read the sentence out loud in your head! Often, you can 'hear' if a rule is being broken.",
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
              "Visual associations help! Try to link the word to a picture in your mind.",
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
              "Over-enunciate! Emphasizing the vowels helps clear up minimal pair confusion.",
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
              "Be expressive! The tone is just as important as the words in social interactions.",
        );
      default:
        return getDefaultBriefing(fallbackTitle ?? "Quest");
    }
  }

  // Large centralized static register matching GameSubtypes to their Briefing parameters.
  static const Map<GameSubtype, GameBriefing> _briefings = {
    GameSubtype.academicWord: GameBriefing(
      title: "Academic Word",
      icon: Icons.school_rounded,
      objective:
          "Read the context of the sentence carefully and drop in the perfect academic word. Expanding this vocabulary helps you sound highly professional and articulate in any setting.",
      rules: [
        "Analyze context clues",
        "Look for collocations",
        "Drop in the exact word",
      ],
      actionText: "Start Challenge",
      tip:
          "Pay close attention to the surrounding words and prepositions—they naturally pull the correct answer towards them!",
    ),
    GameSubtype.speedSpelling: GameBriefing(
      title: "Speed Spelling",
      icon: Icons.bolt_rounded,
      objective:
          "Listen to the word carefully, then tap the floating letters to spell it out. Spelling correctly helps you write with confidence in everyday life!",
      rules: [
        "Listen to the spoken word",
        "You have 30 seconds to answer",
        "Tap the letters in the correct order",
      ],
      actionText: "Start Spelling",
      tip:
          "If you missed the word, tap the replay button to hear it again!",
    ),
    GameSubtype.idiomMatch: GameBriefing(
      title: "Idiom Match",
      icon: Icons.lightbulb_rounded,
      objective:
          "Match each idiom with what it actually means in daily conversation.",
      rules: [
        "Read the sentence and context",
        "Choose the idiom that fits best",
        "Say it aloud to practice speaking",
      ],
      actionText: "Match Idiom",
      tip:
          "Idioms aren't literal. Focus on what the speaker is really trying to express!",
    ),
    GameSubtype.minimalPairs: GameBriefing(
      title: "Minimal Pairs",
      icon: Icons.hearing_rounded,
      objective:
          "Some English words sound almost exactly the same! Listen carefully, pick the right word, and then say it out loud to lock in the correct pronunciation.",
      rules: [
        "Listen to the word",
        "Pick the matching sound",
        "Speak to confirm your answer",
      ],
      actionText: "Start Listening",
      tip:
          "Pay close attention to the vowels! Notice if they sound quick and relaxed, or long and stretched out.",
    ),
    GameSubtype.consonantClarity: GameBriefing(
      title: "Consonant Clarity",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Let's make your consonants crystal clear! Identify the missing sound, then say the word out loud to practice your pronunciation.",
      rules: [
        "Listen to the target word",
        "Tap the matching consonant",
        "Speak to confirm your answer",
      ],
      actionText: "Start Playing",
      tip:
          "Pay attention to whether your throat vibrates (voiced) or stays still (voiceless) when you make the sound!",
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
          "Pay attention to whether the voice rises or falls at the end of the phrase to determine its exact meaning!",
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
          "Pay attention to which word is stressed—it completely changes the sentence's meaning!",
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
          "Try saying the sentence aloud exactly as you hear it. Feeling the sounds connect in your mouth will reveal the answer!",
    ),
    GameSubtype.wordLinking: GameBriefing(
      title: "Word Linking",
      icon: Icons.link_rounded,
      objective:
          "Native speakers don't pause between every word. They link sounds together to create a smooth, continuous flow. Your goal is to identify exactly where this happens.",
      rules: [
        "Listen to the natural flow",
        "Tap the link between the words",
        "Record yourself saying it",
      ],
      actionText: "Find the Link",
      tip:
          "If a word ends in a consonant and the next starts with a vowel, they usually merge into one smooth sound.",
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
          "Match the stress rhythm—English flows in stressed clusters!",
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
          "Look at surrounding nouns and verbs to match singular vs plural context.",
    ),
    GameSubtype.situationSpeaking: GameBriefing(
      title: "Situation Speaking",
      icon: Icons.forum_rounded,
      objective:
          "Read the scenario, decide what you would say in real life, and speak your response. Mastering this helps you sound natural, polite, and confident in everyday English conversations.",
      rules: [
        "Listen to the scenario context",
        "Think about what you would say",
        "Hold the mic and speak naturally",
      ],
      actionText: "Start Situation",
      tip:
          "Don't stress about being perfect. Focus on being polite and clear, just like you would with a real person!",
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
          "Start with foreground actions, then move to background details.",
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
          "Speak with confident, clear pronunciation directly into the mic.",
    ),
    GameSubtype.speakSynonym: GameBriefing(
      title: "Synonym Challenge",
      icon: Icons.library_books_rounded,
      objective:
          "Say a different word that means the exact same thing. Having multiple words for the same idea makes your speaking much more interesting and natural!",
      rules: ["Think of a similar word", "Say it out loud", "Speak clearly"],
      actionText: "Start Speaking",
      tip:
          "Keep it simple! You don't need to use big fancy words—everyday words work perfectly.",
    ),
    GameSubtype.dialogueRoleplay: GameBriefing(
      title: "Scene Architect",
      icon: Icons.theater_comedy_rounded,
      objective:
          "Speak your roleplay script lines with correct emotion and phrasing. Mastering this skill ensures your spoken English sounds clear and natural in real-world conversations.",
      rules: ["Follow the script", "Speak with feeling", "Keep the flow going"],
      actionText: "Enter Scene",
      tip:
          "Match your voice acting to the simulated character's mood!",
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
          "Pay attention to where your tongue touches the roof of your mouth.",
    ),
    GameSubtype.speakOpposite: GameBriefing(
      title: "Antonym Orator",
      icon: Icons.compare_arrows_rounded,
      objective:
          "Speak the exact opposite meaning of the prompt word. Thinking of opposites rapidly builds a flexible, expressive vocabulary.",
      rules: ["Think of the opposite", "Speak clearly", "Avoid synonyms"],
      actionText: "Speak Opposite",
      tip:
          "Think magnetically: What is the polar opposite of the given word?",
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
          "Emphasize the keywords that carry the main emotional meaning.",
    ),
    // 2. Listening
    GameSubtype.audioFillBlanks: GameBriefing(
      title: "Ink Decoder",
      icon: Icons.water_drop_rounded,
      objective:
          "Let's train your ears to catch every single word. Listen to the sentence, scratch the ink, and type exactly what you hear!",
      rules: [
        "Scratch the ink",
        "Listen for the missing word",
        "Type exactly what you hear",
      ],
      actionText: "Start Decoding",
      tip:
          "Listen carefully to short helper words like 'a', 'the', 'in', or 'at'!",
    ),
    GameSubtype.audioMultipleChoice: GameBriefing(
      title: "Listen & Choose",
      icon: Icons.headphones_rounded,
      objective:
          "Listen carefully to the audio and choose the correct answer from the options.",
      rules: [
        "Tap the center button to listen",
        "Spin or browse the answer options",
        "Tap the correct answer to submit",
      ],
      actionText: "Start",
      tip:
          "Tip: You can tap the center button again anytime if you need to re-listen to the audio.",
    ),
    GameSubtype.audioSentenceOrder: GameBriefing(
      title: "Sentence Builder",
      icon: Icons.waves_rounded,
      objective:
          "Let's put the puzzle pieces together! Listen closely to the speaker and build the exact sentence by placing the scrambled words in the order you hear them.",
      rules: [
        "Listen to the audio clip",
        "Find the first word you hear",
        "Snap the words together in order",
      ],
      actionText: "Let's Build!",
      tip:
          "Don't just guess the grammar! Listen closely to the rhythm and how the speaker links words together.",
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
      title: "Sound Image Match",
      icon: Icons.headphones_rounded,
      objective:
          "Listen to the audio clip and tap the picture that matches what you hear.",
      rules: [
        "Tap the speaker to listen",
        "Focus on the key words",
        "Choose the matching picture",
      ],
      actionText: "Let's Play",
      tip:
          "Listen for key words like objects, animals, or actions before making your choice.",
    ),
    GameSubtype.fastSpeechDecoder: GameBriefing(
      title: "Fast Speech Decoder",
      icon: Icons.speed_rounded,
      objective:
          "Listen to natural fast English speech and understand connected words. Use the speed dial to slow down audio if needed.",
      rules: [
        "Turn the dial to adjust speed",
        "Listen closely to the audio",
        "Select the matching sentence",
      ],
      actionText: "Start Practice",
      tip:
          "Focus on stressed syllables—they carry the core meaning in fast speech.",
    ),
    GameSubtype.emotionRecognition: GameBriefing(
      title: "Emotion Recognition",
      icon: Icons.sentiment_satisfied_alt_rounded,
      objective:
          "Listen to the speaker's tone of voice and identify how they are feeling. Recognizing emotions helps you understand conversations naturally.",
      rules: [
        "Listen to the audio",
        "Pay attention to tone of voice",
        "Choose the matching emotion",
      ],
      actionText: "Start",
      tip:
          "Rhythm, volume changes, and pauses often express more than the literal words.",
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
          "Listen carefully and figure out what the speaker really means, even if they don't say it directly. This helps you understand real-world English conversations!",
      rules: [
        "Listen to the tone",
        "Understand the context",
        "Pick the hidden meaning",
      ],
      actionText: "Focus Lens",
      tip:
          "Pay close attention to how the speaker sounds, not just the exact words they use!",
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
          "Close your eyes and visualize the scene! Focus on ambient sounds like footsteps, echoes, wind, or humming machinery.",
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
      title: "Name That Story",
      icon: Icons.title_rounded,
      objective:
          "Read the story and figure out the main point. Picking the right title proves you understand the whole picture, not just a random detail.",
      rules: [
        "Read the whole story",
        "Find the main point",
        "Drag the best title",
      ],
      actionText: "Play Now",
      tip:
          "Don't get tricked by a word that only appeared once. A good title summarizes the entire text!",
    ),
    GameSubtype.readAndMatch: GameBriefing(
      title: "Read & Match",
      icon: Icons.extension_rounded,
      objective:
          "Connect the words on the left to their correct meanings on the right. Match all pairs to complete the level.",
      rules: [
        "Tap a word on the left",
        "Tap its meaning on the right",
        "Clear all matches to win",
      ],
      actionText: "Match Items",
      tip: "Read each meaning carefully before tapping your match.",
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
          "Reading the surrounding words is crucial. Context gives away the required part of speech!",
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
          "Use your eyes like a radar! Hunt for capital letters or numbers first.",
    ),
    // 4. Writing
    GameSubtype.sentenceBuilder: GameBriefing(
      title: "Sentence Architect",
      icon: Icons.architecture_rounded,
      objective:
          "Connect the scattered word fragments to build a natural-sounding sentence. It's a great way to develop an instinctive feel for how native speakers put words together.",
      rules: [
        "Find the main subject",
        "Identify the verb",
        "Complete the thought",
      ],
      actionText: "Build Sentence",
      tip:
          "Start with 'who' or 'what' the sentence is about, then look for the action word!",
    ),
    GameSubtype.completeSentence: GameBriefing(
      title: "Complete Sentence",
      icon: Icons.edit_note_rounded,
      objective:
          "Read the sentence and find the missing word. Select the word that fits grammatically, then spell it to lock in your answer.",
      rules: [
        "Read the whole sentence",
        "Select the missing word",
        "Spell it correctly",
      ],
      actionText: "Let's Go!",
      tip:
          "Read the sentence out loud in your head. Your intuition will often tell you which word belongs before you look at the options!",
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
      tip: "Use sensory words! Describe what is seen, heard, or felt.",
    ),
    GameSubtype.fixTheSentence: GameBriefing(
      title: "Clarity Editor",
      icon: Icons.edit_rounded,
      objective:
          "Find the mistake in the sentence! Scrub the wrong word to erase it, then type the correct word to make the sentence clear and natural.",
      rules: ["Locate the error", "Scrub to erase it", "Type the correct word"],
      actionText: "Fix the Sentence",
      tip:
          "Read the sentence out loud! If something sounds a little weird, that's probably the word you need to scrub.",
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
      tip:
          "Don't overcomplicate it! Simple, direct sentences are the best.",
    ),
    GameSubtype.clauseConnector: GameBriefing(
      title: "Clause Connector",
      icon: Icons.add_link_rounded,
      objective:
          "Drag the correct connector to link the two clauses together. Connecting short sentences makes your English flow much more naturally in real conversations.",
      rules: [
        "Read both parts carefully",
        "Find the logical link",
        "Drop the correct connector",
      ],
      actionText: "Link Clauses",
      tip:
          "Think about the relationship. Is it showing a result (so), a contrast (but), or adding info (and)?",
    ),
    GameSubtype.opinionWriting: GameBriefing(
      title: "Opinion Writing",
      icon: Icons.rate_review_rounded,
      objective:
          "Read each prompt carefully, then choose the statements that express personal opinions or facts as requested.",
      rules: [
        "Read the prompt carefully",
        "Choose the best statements",
        "Check your answer",
      ],
      actionText: "Start Practice",
      tip:
          "Facts can be proven with evidence. Opinions express personal feelings, beliefs, or judgements.",
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
          "Use sequential markers like 'First', 'Later', and 'Eventually' to organize your thoughts.",
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
          "A good summary only includes events that actually happened in the story!",
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
          "Clear subject lines and direct greetings set the professional tone.",
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
          "Read the sentence out loud in your head! Clunky phrasing often reveals the grammatical flaw.",
    ),
    GameSubtype.essayDrafting: GameBriefing(
      title: "Essay Drafting",
      icon: Icons.article_rounded,
      objective:
          "Look at the empty hex slots (e.g., REQUEST, CURRENT PROBLEM). Grab the sentence cards from the bottom (using the dotted drag handles) and drag and drop them into their correct logical slots. (If you make a mistake, just tap a filled slot to remove the card and send it back to the bottom).",
      rules: [
        "Check the empty slots",
        "Drag the sentence cards",
        "Fill all slots to submit",
      ],
      actionText: "Start Drafting",
      tip:
          "Pay attention to the labels on the hex slots—they tell you exactly what kind of sentence belongs there!",
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
          "Read the sentence out loud in your head! Often, you can 'hear' if a rule is broken.",
    ),
    GameSubtype.sentenceCorrection: GameBriefing(
      title: "Error Auditor",
      icon: Icons.spellcheck_rounded,
      objective:
          "Scan the text for grammatical errors, apply the correct fix, then type the corrected sentence to lock it in. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: ["Find the glitch", "Apply the fix", "Type to confirm answer"],
      actionText: "Audit Text",
      tip:
          "Focus on subject-verb agreement first—it's the most common source of errors!",
    ),
    GameSubtype.wordReorder: GameBriefing(
      title: "Sentence Builder",
      icon: Icons.reorder_rounded,
      objective:
          "First, tap the words to build a natural-sounding English sentence. Once you get it right, type it out to lock it into your muscle memory!",
      rules: [
        "Tap words to build",
        "No changing after check",
        "Type the exact sentence",
      ],
      actionText: "Start Building",
      tip:
          "Look for capital letters to find the first word, and punctuation for the last!",
    ),
    GameSubtype.tenseMastery: GameBriefing(
      title: "Tense Mastery",
      icon: Icons.history_toggle_off_rounded,
      objective:
          "Select or place verbs in their correct chronological tenses. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: [
        "Check for time markers",
        "Identify frequency",
        "Achieve 100% accuracy",
      ],
      actionText: "Master Tenses",
      tip:
          "Look for 'Signal Words'! 'Since' often needs Perfect, while 'Usually' needs Present.",
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
          "If it's an action, it's a verb. If it's a person/place/thing, it's a noun.",
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
          "Watch out for 'distractors'—prepositional phrases that sit between subject and verb!",
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
          "In Passive voice, the object becomes the star! Use 'by [someone]' only if needed.",
    ),
    GameSubtype.questionFormatter: GameBriefing(
      title: "Question Formatter",
      icon: Icons.help_outline_rounded,
      objective:
          "Master the art of asking questions. Spin the crank to reveal the options, find the one that correctly flips the sentence, and type the final question to lock it in.",
      rules: [
        "Read the statement",
        "Spin to reveal options",
        "Find the perfect question",
      ],
      actionText: "Start Formatting",
      tip:
          "Pay attention to the helping verb! If the sentence uses 'is' or 'can', the question usually starts with it.",
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
          "Use 'the' for specific items, 'a/an' for general ones, and listen for vowel sounds!",
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
          "Place the modifier as close as possible to the word it's describing!",
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
          "'Must' is for strong obligation, while 'Should' is for friendly advice.",
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
          "Use 'In' for large spaces, 'On' for surfaces, and 'At' for specific points.",
    ),
    GameSubtype.pronounResolution: GameBriefing(
      title: "Pronoun Gravity",
      icon: Icons.gps_fixed_rounded,
      objective:
          "Words like 'he', 'she', or 'it' only make sense if we know who they belong to. Align the gravity well to the matching word, then type it out to lock it in.",
      rules: [
        "Read the sentence carefully",
        "Align beam to the match",
        "Type the word to lock it in",
      ],
      actionText: "Align Gravity",
      tip:
          "If you're not sure, try swapping the words! If 'the dog' fits perfectly where 'it' was, you've found your match.",
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
          "Use a comma before 'and' only in long lists or between independent clauses!",
    ),
    GameSubtype.relativeClauses: GameBriefing(
      title: "Relative Rail",
      icon: Icons.linear_scale_rounded,
      objective:
          "Use relative pronouns (who, which, that) to connect the clauses. Mastering structural rules ensures your English is accurate and easily understood.",
      rules: ["Identify the noun", "Choose the pronoun", "Link the detail"],
      actionText: "Link Relative",
      tip:
          "Use 'Who' for people and 'Which' or 'That' for things and animals.",
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
          "In 'Second Conditional' (imaginary), use 'If I WERE' even for singular subjects!",
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
      tip: "Remember 'FANBOYS': For, And, Nor, But, Or, Yet, So!",
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
          "'Present' becomes 'Past'! If someone said 'I am here', report 'they were there'.",
    ),

    // 6. Vocabulary
    GameSubtype.flashcards: GameBriefing(
      title: "Vocabulary Flashcards",
      icon: Icons.style_rounded,
      objective:
          "Test your memory! Try to recall the word's meaning before flipping the card, then swipe right if you knew it or left to practice again.",
      rules: [
        "Guess the meaning first",
        "Tap to flip the card",
        "Swipe Right: Mastered, Left: Review",
      ],
      actionText: "Start Review",
      tip:
          "Be honest with yourself! Swiping left ensures you'll get another chance to really lock the word into your memory.",
    ),
    GameSubtype.synonymSearch: GameBriefing(
      title: "Synonym Match",
      icon: Icons.compare_arrows_rounded,
      objective:
          "Find the word that has the same meaning as the target word. Tap or drag the matching word to the center, then practice using it in a natural sentence.",
      rules: [
        "Find the matching synonym",
        "Tap or drag to the center",
        "Practice with a sentence",
      ],
      actionText: "Start Practice",
      tip:
          "Don't get tricked by words that just look similar. Focus entirely on the core meaning!",
    ),
    GameSubtype.antonymSearch: GameBriefing(
      title: "Antonym Search",
      icon: Icons.electrical_services_rounded,
      objective:
          "Identify the core word's exact opposite and snap it into the center core to fuse them. Then, speak the pair aloud to confirm your answer.",
      rules: [
        "Read the center core word",
        "Snap the opposite word into the core",
        "Speak the pair clearly aloud",
      ],
      actionText: "Begin Search",
      tip:
          "Antonyms are completely opposite concepts. If the core says 'hot', you're looking for 'cold' to neutralize it!",
    ),
    GameSubtype.contextClues: GameBriefing(
      title: "Context Clues",
      icon: Icons.search_rounded,
      objective:
          "Use the scanner to investigate the blurred text and deduce the missing word, then highlight the exact evidence that proves your answer.",
      rules: [
        "Drag the scanner to reveal text",
        "Tap the missing word tag",
        "Highlight the proof in the text",
      ],
      actionText: "Investigate Case",
      tip:
          "Look for synonyms, antonyms, or cause-and-effect relationships hidden in the surrounding words!",
    ),
    GameSubtype.phrasalVerbs: GameBriefing(
      title: "Verb Vault",
      icon: Icons.vpn_key_rounded,
      objective:
          "Phrasal verbs are tricky combinations like 'turn up' or 'break down'. Read the clue, choose the missing word to crack the vault, and then speak the full sentence aloud.",
      rules: [
        "Read the vault's clue",
        "Choose the missing word",
        "Speak the full sentence",
      ],
      actionText: "Crack Vault",
      tip:
          "The second word changes everything! 'Turn up' (increase) means something totally different than 'turn down' (refuse).",
    ),
    GameSubtype.idioms: GameBriefing(
      title: "Emojify",
      icon: Icons.forum_rounded,
      objective:
          "Decode the incoming emoji transmission by selecting the correct English idiom. Mastering idioms is the ultimate secret to sounding like a true native speaker!",
      rules: [
        "Interpret the emojis",
        "Select the matching idiom",
        "Speak it aloud to secure",
      ],
      actionText: "Decrypt Message",
      tip:
          "Idioms are colorful cultural keys! Don't translate them literally word-for-word.",
    ),
    GameSubtype.topicVocab: GameBriefing(
      title: "Topic Sorter",
      icon: Icons.category_rounded,
      objective:
          "Flick the vocabulary word into the correct containment bin based on its topic. Grouping words helps you recall them faster during real-world conversations.",
      rules: [
        "Analyze the floating word",
        "Flick it to the correct bin",
        "Sort the entire batch",
      ],
      actionText: "Start Sorting",
      tip:
          "Try to picture the word in your mind before flicking it into the category!",
    ),
    GameSubtype.wordFormation: GameBriefing(
      title: "Word Morph",
      icon: Icons.science_rounded,
      objective:
          "Native speakers constantly bend words to fit different grammatical situations. Slide the correct injection rail into the reaction core, then type the final result.",
      rules: [
        "Check the target meaning",
        "Slide the correct ending rail",
        "Type the final word to lock it",
      ],
      actionText: "Start Morphing",
      tip:
          "Ask yourself what kind of word you need. Are you turning a noun into an adjective, or a verb into a person?",
    ),
    GameSubtype.prefixSuffix: GameBriefing(
      title: "Affix Synthesizer",
      icon: Icons.spa_rounded,
      objective:
          "A few tiny letters can completely change a word's meaning. Tap the correct prefix or suffix chip to snap it onto the root word, then type the final result to lock it in.",
      rules: [
        "Read the target meaning",
        "Tap to snap the affix chip",
        "Type the final word to confirm",
      ],
      actionText: "Start Synthesizing",
      tip:
          "If the target meaning says 'again', look for 're-'. If it says 'without', look for '-less'.",
    ),
    GameSubtype.collocations: GameBriefing(
      title: "Natural Word Pairs",
      icon: Icons.join_inner_rounded,
      objective:
          "Find the word that naturally belongs with the anchor, then confirm the complete phrase in a real sentence.",
      rules: [
        "Read the main anchor word",
        "Drag the matching word to the drop zone",
        "Review the complete sentence and confirm",
      ],
      actionText: "Start Pairing",
      tip:
          "Try not to translate word-for-word. Just trust your ear and choose the pair that sounds right to you.",
    ),
    GameSubtype.contextualUsage: GameBriefing(
      title: "Contextual Usage",
      icon: Icons.auto_stories_rounded,
      objective:
          "Select the word that best fits the sentence's context, then speak the complete sentence aloud to confirm.",
      rules: [
        "Read the sentence carefully",
        "Select the best fitting word",
        "Speak the full sentence aloud",
      ],
      actionText: "Analyze Context",
      tip:
          "Pay close attention to the register meter. Sometimes two words mean the same thing, but one is much more formal than the other!",
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
          "Questions often rise at the end, while statements usually fall. Listen closely to the final word!",
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
          "The stressed part of a word is always louder and slightly longer.",
    ),

    GameSubtype.vowelDistinction: GameBriefing(
      title: "Vowel Distinction",
      icon: Icons.tune_rounded,
      objective:
          "Vowels can be tricky! Listen to the native speaker, slide the fader to pick the right sound, and then say the word out loud to confirm it.",
      rules: [
        "Listen to the word carefully",
        "Slide to match the vowel",
        "Speak out loud to confirm",
      ],
      actionText: "Start Playing",
      tip:
          "Don't just listen—pay attention to the mouth shape in the chart! It'll help you pronounce it perfectly.",
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
          "Pay attention to whether the speaker is rushing or speaking carefully to emphasize a point!",
    ),
    GameSubtype.dialectDrill: GameBriefing(
      title: "Dialect Drill",
      icon: Icons.public_rounded,
      objective:
          "English sounds different depending on where you are in the world! Let's train your ears to pick up on those regional differences.",
      rules: [
        "Listen to the speaker",
        "Notice the accent",
        "Match them to the map",
      ],
      actionText: "Start Drill",
      tip:
          "Pay attention to the vowels! American English often flattens them, while British English rounds them out.",
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
          "Try saying the words fast yourself! If you force every single letter, it feels unnatural. Real speech takes shortcuts.",
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
          "Pay attention to the subtle social cues! Being polite and direct often opens the right doors.",
    ),
    GameSubtype.situationalResponse: GameBriefing(
      title: "Reflex Responder",
      icon: Icons.flash_on_rounded,
      objective:
          "Choose the most appropriate and polite social response for the scenario. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: [
        "Match social tone",
        "Be polite/direct",
        "Navigate social nuances",
      ],
      actionText: "Respond Now",
      tip:
          "Use expressions like 'I would appreciate it' or 'Would you mind'!",
    ),
    GameSubtype.jobInterview: GameBriefing(
      title: "Career Closer",
      icon: Icons.business_center_rounded,
      objective:
          "Choose professional responses to nail your high-stakes job interview. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Be professional", "Select the best answer", "Speak to confirm"],
      actionText: "Start Interview",
      tip:
          "Frame replies to show how your experience solves their business needs.",
    ),
    GameSubtype.medicalConsult: GameBriefing(
      title: "Health Liaison",
      icon: Icons.medical_services_rounded,
      objective:
          "Review the patient's symptoms carefully, examine the affected areas, and select the correct medical diagnosis.",
      rules: [
        "Listen carefully to symptoms",
        "Scan the body to locate findings",
        "Select the matching diagnosis",
      ],
      actionText: "Start Consult",
      tip:
          "Look for specific symptom descriptors like throbbing, sharp pain, or swelling.",
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
          "Using 'Could I get...' is the preferred way to place polite orders.",
    ),
    GameSubtype.travelDesk: GameBriefing(
      title: "Global Traveler",
      icon: Icons.flight_takeoff_rounded,
      objective:
          "Manage check-ins, navigate directions, and handle hotel booking requests. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Check travel tickets", "Follow directions", "Ask for support"],
      actionText: "Start Journey",
      tip:
          "Confirm directions by repeating them back to check understanding.",
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
          "De-escalate early by validating their perspective before replying.",
    ),
    GameSubtype.elevatorPitch: GameBriefing(
      title: "Pitch Perfect",
      icon: Icons.rocket_launch_rounded,
      objective:
          "Deliver a compelling, high-impact business message in 30 seconds. Mastering situational responses ensures you can navigate social interactions with confidence.",
      rules: ["Be concise", "High emotional impact", "Deliver with confidence"],
      actionText: "Start Pitch",
      tip:
          "Lead with a massive hook that frames a relatable daily problem.",
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
          "Ask 'what' or 'how' to keep the conversational partner sharing.",
    ),
    GameSubtype.emergencyHub: GameBriefing(
      title: "Emergency Voice",
      icon: Icons.emergency_share_rounded,
      objective:
          "Relay critical information clearly and calmly during emergency situations. Clear, direct communication ensures fast and accurate response.",
      rules: [
        "Stay calm and speak clearly",
        "State the location and issue",
        "Transmit the required override",
      ],
      actionText: "Help Now",
      tip:
          "Take a breath and speak at a steady pace. Clear phrases prevent confusion.",
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
          "Look for transition words like 'However' or 'Therefore' to link sentences!",
    ),

    GameSubtype.accentShadowing: GameBriefing(
      title: "Accent Shadowing",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Speak clearly to match the exact accent and rhythm of the speaker. Mastering pronunciation ensures your spoken English sounds clear and natural.",
      rules: ["Listen to the example", "Record your voice", "Match the accent"],
      actionText: "Start Shadowing",
      tip:
          "Pay close attention to which syllables are stressed—it makes a huge difference!",
    ),
  };

  static GameBriefing? _getKidsBriefing(String category, {int level = 1}) {
    switch (category.toLowerCase()) {
      case 'alphabet':
        return const GameBriefing(
          title: "Alphabet Game",
          icon: Icons.abc_rounded,
          objective:
              "Listen to the instruction and tap the correct letter block to reveal a fun word on the chalkboard.",
          rules: [
            "Tap the chalkboard to hear the instruction",
            "Find the matching letter block",
            "Tap it to reveal the word",
          ],
          actionText: "Start Playing",
          tip:
              "If you get stuck, tap the chalkboard question mark again to hear the instruction as many times as you need!",
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
              "Think about the sound the animal makes or where it lives! 🦁",
        );
      case 'numbers':
        return const GameBriefing(
          title: "Numbers in Space",
          icon: Icons.numbers_rounded,
          objective:
              "Look through your rocket window to count the items, then choose the planet that matches to help your spaceship fly!",
          rules: [
            "Look at the pictures or numbers in the rocket window",
            "Tap a planet or drag it up to your rocket to answer",
            "Tap the speaker button any time you want to hear the numbers out loud",
          ],
          actionText: "Let's Count!",
          tip:
              "Helpful tip: You can tap each item on the screen with your finger while counting out loud so you never lose your place! 🚀",
        );
      case 'colors':
        return const GameBriefing(
          title: "Learning Colors",
          icon: Icons.palette_rounded,
          objective:
              "Look at the color word on the easel, then drag the matching color or item onto the canvas.",
          rules: [
            "Read the color word",
            "Find the matching item",
            "Drag it to the easel",
          ],
          actionText: "Start",
          tip:
              "Tip: Think about things you see every day that match the color.",
        );
      case 'fruits':
        return const GameBriefing(
          title: "Fruit Stand",
          icon: Icons.shopping_basket_rounded,
          objective:
              "Read the clue on the wooden board and drag the correct fruit into the basket. Let's harvest some healthy treats!",
          rules: [
            "Read or listen to the clue",
            "Drag the matching fruit to the basket",
          ],
          actionText: "Play Now",
          tip:
              "Fruits can be sweet or sour. Think about how they taste! 🍎",
        );
      case 'shapes':
        return const GameBriefing(
          title: "Shapes",
          icon: Icons.category_rounded,
          objective:
              "Look at the clue and picture to find the matching shape, then tap or drag the block to answer.",
          rules: [
            "Read or listen to the shape clue",
            "Tap or drag the matching shape block to answer",
            "Tap any block's speaker to hear the shape name out loud",
          ],
          actionText: "Start Playing",
          tip:
              "Tip: Count the sides and corners to help you find the right shape! 📐",
        );
      case 'body_parts':
        return const GameBriefing(
          title: "My Body",
          icon: Icons.accessibility_new_rounded,
          objective:
              "Listen to the fun clue, find the band-aid for that body part, and place it on the X-Ray!",
          rules: [
            "Listen to the clue",
            "Pick the right band-aid",
            "Place it on the X-Ray",
          ],
          actionText: "Play Now",
          tip:
              "Tip: Try pointing to that body part on yourself to guess the answer! 🧠",
        );
      case 'family':
        return const GameBriefing(
          title: "Family",
          icon: Icons.family_restroom_rounded,
          objective:
              "Match the family member to the description by placing their photo in the frame.",
          rules: [
            "Listen to the clue",
            "Find the matching photo",
            "Drag or tap to select",
          ],
          actionText: "Start",
          tip:
              "Pay attention to key relationship words like 'parent' or 'sibling'.",
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
              "Think about what you eat for breakfast, lunch, or dinner! 🥛",
        );
      case 'clothing':
        return const GameBriefing(
          title: "Clothing Riddles",
          icon: Icons.checkroom_rounded,
          objective:
              "Let's solve some fun clothing riddles! Listen carefully to the clue, find the matching clothing tag, and hang it in the closet.",
          rules: [
            "Listen to the riddle",
            "Find the matching clothes",
            "Hang it in the closet",
          ],
          actionText: "Play Now",
          tip:
              "If you missed the clue, just tap the glowing closet to hear the riddle again! 👕",
        );
      case 'nature':
        return const GameBriefing(
          title: "Nature",
          icon: Icons.forest_rounded,
          objective:
              "Explore living things, weather, seasons, and habitats. Read or listen to the clue on the tree sign, then choose the matching answer on the stones.",
          rules: [
            "Read or listen to the clue on the tree sign",
            "Tap or drag the matching stone to answer",
            "Tap any stone's speaker to hear it spoken aloud",
          ],
          actionText: "Start Playing",
          tip:
              "Tip: Tap the speaker icon on any stone to hear how the word is pronounced before choosing.",
        );
      case 'transport':
        if (level == 100) {
          return const GameBriefing(
            title: "Century Traveler! 🏆",
            icon: Icons.emoji_events_rounded,
            objective:
                "Congratulations on reaching Level 100! You've learned so many ways we travel around our world. Let's solve this milestone travel challenge together!",
            rules: [
              "Read or listen to the milestone clue on the sign",
              "Tap or drag the matching vehicle to answer",
              "Celebrate 100 levels of travel vocabulary!",
            ],
            actionText: "Start Level 100",
            tip:
                "Tip: You know vehicles that travel by land, sea, and air. Trust your skills and enjoy this special milestone!",
          );
        }
        return const GameBriefing(
          title: "Zoom Zoom!",
          icon: Icons.directions_car_rounded,
          objective:
              "Explore vehicles and ways to travel! Read or listen to the clue on the highway sign, then choose the matching vehicle.",
          rules: [
            "Read or listen to the clue on the highway sign",
            "Tap or drag the matching vehicle to answer",
            "Tap any card's speaker to hear the word pronounced",
          ],
          actionText: "Start Engine",
          tip:
              "Tip: Think about where each vehicle travels—on the road, in the water, or in the air!",
        );
      case 'emotions':
        return const GameBriefing(
          title: "Emotions",
          icon: Icons.mood_rounded,
          objective:
              "Listen to the scenario, understand how the person is feeling, and match the correct emotion mask to the stage.",
          rules: [
            "Listen to the scenario",
            "Identify the correct emotion",
            "Match the mask to the stage",
          ],
          actionText: "Play Now",
          tip:
              "Think about how you would feel in that exact situation.",
        );
      case 'school':
        return const GameBriefing(
          title: "School Days",
          icon: Icons.school_rounded,
          objective:
              "Read or listen to the teacher's classroom clue, then choose or place the matching answer on the desk.",
          rules: [
            "Read or listen to the clue on the chalkboard",
            "Tap your answer or drag it onto the desk",
            "Tap any card's speaker to hear the word pronounced aloud",
          ],
          actionText: "Go to School",
          tip:
              "Tip: Tap the Listen button on the board anytime to hear the teacher's clue again.",
        );
      case 'home':
        return const GameBriefing(
          title: "Home",
          icon: Icons.home_rounded,
          objective:
              "Explore parts of a house, different rooms, daily items, and home safety. Read or listen to each clue and choose the answer.",
          rules: [
            "Read or listen to the clue",
            "Tap or drag the matching answer to the house",
            "Tap the speaker anytime to hear words spoken aloud",
          ],
          actionText: "Start Playing",
          tip:
              "Tip: Tap any card's speaker to hear how the word is pronounced before answering.",
        );
      case 'opposites':
        return const GameBriefing(
          title: "Opposites",
          icon: Icons.compare_arrows_rounded,
          objective:
              "Look at the clue word, think of its opposite, and tap or drag the matching word to complete the pair.",
          rules: [
            "Read or listen to the clue word",
            "Tap or drag the matching opposite word",
            "Tap any speaker to hear words spoken aloud",
          ],
          actionText: "Start Playing",
          tip:
              "Tip: Tap any card's speaker to hear how the word sounds before choosing.",
        );
      case 'verbs':
        if (level == 100) {
          return const GameBriefing(
            title: "Action Champion! 🏆",
            icon: Icons.emoji_events_rounded,
            objective:
                "Congratulations on reaching Level 100! You've learned so many action words for what people and animals do. Let's score this milestone action challenge together!",
            rules: [
              "Read or listen to the story clue on the scoreboard",
              "Tap or throw the matching sports ball into the stadium",
              "Celebrate 100 levels of action words!",
            ],
            actionText: "Play Level 100",
            tip:
                "Tip: Action words tell what someone is doing, like jump, throw, cook, or swim. You're an action champion!",
          );
        }
        return const GameBriefing(
          title: "Action Time!",
          icon: Icons.directions_run_rounded,
          objective:
              "Read or listen to the story clue on the scoreboard, then find the sports ball with the matching action word.",
          rules: [
            "Read or listen to the story clue on the scoreboard",
            "Tap your answer or drag the ball into the stadium",
            "Tap any speaker icon to hear the action words spoken aloud",
          ],
          actionText: "Play Ball!",
          tip:
              "Tip: A verb is an action word that tells what someone is doing, like run, jump, or play.",
        );
      case 'prepositions':
        return const GameBriefing(
          title: "Where Is It?",
          icon: Icons.location_on_rounded,
          objective:
              "Read or listen to the sentence, find where the object is, and choose the correct position word to complete the blank.",
          rules: [
            "Read or listen to the sentence clue",
            "Tap or drag the matching preposition to the blank",
            "Tap any speaker icon to hear the words spoken aloud",
          ],
          actionText: "Start Playing",
          tip:
              "Tip: Words like 'in', 'on', and 'under' tell you exactly where things are placed.",
        );
      case 'handwriting':
        return const GameBriefing(
          title: "Chalkboard Writing",
          icon: Icons.draw_rounded,
          objective:
              "Pick up your chalk and practice drawing lines, shapes, and letters right on the chalkboard slate.",
          rules: [
            "Tap Demo to watch how each stroke is drawn step by step",
            "Turn on Trace to follow the dotted lines, or practice on your own",
            "Tap Check My Answer when ready, or use the duster to try again",
          ],
          actionText: "Let's Write",
          tip:
              "Take your time. Drawing strokes from top to bottom and left to right makes writing so much easier!",
        );
      case 'routine':
        return const GameBriefing(
          title: "Daily Routines",
          icon: Icons.bed_rounded,
          objective:
              "Match daily routines to the right time of day. Read or listen to the clue, look outside the window, and choose the routine that fits best.",
          rules: [
            "Read or listen to the clue at the top",
            "Look outside the window to see the time of day",
            "Tap or drag the matching routine pillow to the window",
          ],
          actionText: "Let's Play",
          tip:
              "Tip: Tap the speaker on any pillow to hear the routine words out loud before you choose!",
        );
      case 'phonics':
        return const GameBriefing(
          title: "Sound Match",
          icon: Icons.hearing_rounded,
          objective:
              "Listen to the sound clue, check the word or letters on the speaker, and choose the matching sound to complete the word.",
          rules: [
            "Listen to the sound clue",
            "Choose the matching sound",
            "Complete the word",
          ],
          actionText: "Let's Play",
          tip:
              "Say the sound out loud as you listen—it helps your brain connect letters to real words!",
        );
      case 'time':
        return const GameBriefing(
          title: "Telling Time",
          icon: Icons.access_time_rounded,
          objective:
              "Look at the clock or listen to the daily clue, then pick the matching time or part of the day.",
          rules: [
            "Look at the clock hands and read the clue",
            "Tap an answer or drag it right to the clock",
            "Tap the speaker anytime to hear the clue again",
          ],
          actionText: "Let's Play",
          tip:
              "Helpful tip: The short hand shows the hour, and the long hand shows the minutes! ⏰",
        );
      case 'day_night':
        return const GameBriefing(
          title: "Day and Night",
          icon: Icons.brightness_6_rounded,
          objective:
              "Read the clue in the sky, then select the right option to show when it happens.",
          rules: [
            "Read the clue",
            "Think about the time",
            "Select the correct answer",
          ],
          actionText: "Play",
          tip:
              "Think about whether the sun is up or the stars are out! ☀️🌙",
        );
      case 'weather':
        return const GameBriefing(
          title: "Weather Window",
          icon: Icons.wb_sunny_rounded,
          objective:
              "Look outside the window and read the clue, then tap or drag the matching weather to solve it!",
          rules: [
            "Read or listen to the weather clue",
            "Find the weather that matches",
            "Drag it to the window or tap to choose",
          ],
          actionText: "Let's Play",
          tip:
              "Tip: Picture what you see outside, or tap the speaker to hear the clue read aloud! ☀️",
        );
      case 'professions':
        return const GameBriefing(
          title: "Community Helpers",
          icon: Icons.work_rounded,
          objective:
              "Read the clue on the board to find out who can help, then tap or drag the right helper to solve it!",
          rules: [
            "Read the clue on the board",
            "Tap or drag the helper who fits the job",
            "Tap the speaker to hear any word aloud",
          ],
          actionText: "Let's Play",
          tip:
              "Tip: Tap the Listen button if you want to hear the clue read aloud! 💡",
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
        "Complete the mission",
        "2 Strikes (Mistakes Re-queued)",
        "Achieve 100% Mastery",
      ],
      actionText: "Start Quest",
      tip:
          "Stay focused and listen to your buddy! They have the answers you need.",
    );
  }
}

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
          objective: "Tap mic and repeat the phrase clearly at a natural pace.",
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
          objective: "Listen carefully and choose the correct answer option.",
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
              "Read the passage carefully and answer the comprehension questions.",
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
              "Arrange the words in the correct order to build a complete sentence.",
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
              "Fix the underlying structural errors to complete the sentence.",
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
              "Match words to their correct definitions to expand your vocabulary.",
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
              "Focus on rhythm and pitch. Sound exactly like a native speaker.",
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
              "Navigate social scenarios by selecting the best conversational response.",
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
          "Tap the floating letters to spell the target word correctly. Mastering spelling patterns ensures your written communication is professional and easily understood in the real world.",
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
          "Match the idiom to its real meaning. Mastering idioms helps you speak more naturally and understand native speakers in everyday conversations.",
      rules: [
        "Analyze the context clue",
        "Identify the core meaning",
        "Match the perfect idiom",
      ],
      actionText: "Match Idiom",
      tip:
          "PRO TIP: Idioms rarely mean what the individual words mean literally. Think about the feeling or situation they describe!",
    ),
    // 2. Speaking
    GameSubtype.repeatSentence: GameBriefing(
      title: "Echo Master",
      icon: Icons.graphic_eq_rounded,
      objective:
          "Listen carefully and repeat the sentence matching cadence and wave patterns.",
      rules: ["Hold mic to record", "Trace sound wave", "Master the cadence"],
      actionText: "Start Echo",
      tip:
          "PRO TIP: Match the stress rhythm—English flows in stressed clusters!",
    ),
    GameSubtype.speakMissingWord: GameBriefing(
      title: "Vocal Decoder",
      icon: Icons.find_in_page_rounded,
      objective:
          "Read the prompt and speak the missing word clearly to fill the blank.",
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
          "Orally provide a clear, direct solution to the real-world scenario.",
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
          "Describe the image scene clearly using descriptive adjectives.",
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
          "Answer the factual questions firmly with a spoken 'Yes' or 'No'.",
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
      objective: "Orally state a correct synonym for the target word.",
      rules: [
        "Find similar meaning",
        "Speak synonym clearly",
        "Expand your voice",
      ],
      actionText: "Vocalize Synonym",
      tip:
          "PRO TIP: Expand your vocabulary by grouping similar words together.",
    ),
    GameSubtype.dialogueRoleplay: GameBriefing(
      title: "Scene Architect",
      icon: Icons.theater_comedy_rounded,
      objective:
          "Speak your roleplay script lines with correct emotion and phrasing.",
      rules: ["Follow the script", "Speak with feeling", "Keep the flow going"],
      actionText: "Enter Scene",
      tip:
          "PRO TIP: Match your voice acting to the simulated character's mood!",
    ),
    GameSubtype.pronunciationFocus: GameBriefing(
      title: "Phonetic Precision",
      icon: Icons.record_voice_over_rounded,
      objective:
          "Perfect mouth movements to pronounce challenging sounds and clusters.",
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
      objective: "Orally state the direct opposite/antonym of the prompt word.",
      rules: ["Analyze target", "Speak the antonym", "Maintain accuracy"],
      actionText: "Vocalize Opposite",
      tip:
          "PRO TIP: Think of contrasting poles (e.g. fast/slow, build/destroy).",
    ),
    GameSubtype.dailyExpression: GameBriefing(
      title: "Social Fluent",
      icon: Icons.chat_bubble_rounded,
      objective:
          "Master common daily idioms to speak naturally and connect with native speakers in real-world conversations.",
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
          "Listen to the audio feed and type the missing words in the transcript.",
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
      objective: "Listen to the audio passage and select the correct answer.",
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
          "Listen and arrange the spoken segments in their correct chronological order.",
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
          "Listen to the speaker and verify if the claim is true or false.",
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
          "Listen to the audio sound and match it with the correct visual image.",
      rules: ["Scan tiles", "Match sound to symbol", "Confirm thematic link"],
      actionText: "Confirm Link",
      tip:
          "Try to describe the sound in one word before selecting your choice.",
    ),
    GameSubtype.fastSpeechDecoder: GameBriefing(
      title: "Nuance Calibrator",
      icon: Icons.settings_input_composite_rounded,
      objective: "Decode rapid native speech by picking out word boundaries.",
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
          "Identify the speaker's emotional state from their pitch and tone.",
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
          "Listen for specific names, numbers, or details within the passage.",
      rules: ["Scan details", "Listen for target keywords", "Identify match"],
      actionText: "Start Search",
      tip:
          "Note details as you listen—rushing to answer from memory can be tricky!",
    ),
    GameSubtype.listeningInference: GameBriefing(
      title: "Inference Lens",
      icon: Icons.biotech_rounded,
      objective:
          "Infer implications in the spoken passage that are not explicitly stated.",
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
          "Sharpen your situational awareness by identifying environments solely through their ambient soundscape, essential for real-world immersion.",
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
          "Read the passage and select correct answers to comprehension questions.",
      rules: ["Refer back to text", "Verify every detail", "Think critically"],
      actionText: "Analyze Text",
      tip:
          "Don't guess! The answer is ALWAYS in the text—you just have to find it.",
    ),
    GameSubtype.findWordMeaning: GameBriefing(
      title: "Lexical Linker",
      icon: Icons.menu_book_rounded,
      objective:
          "Find and match word definitions directly within the passage context.",
      rules: ["Analyze context", "Match word to meaning", "Build vocabulary"],
      actionText: "Link Words",
      tip:
          "Context is your best friend! The surrounding words often reveal hidden meanings.",
    ),
    GameSubtype.trueFalseReading: GameBriefing(
      title: "Truth Verifier",
      icon: Icons.verified_user_rounded,
      objective: "Determine if statements are true or false based on the text.",
      rules: ["Locate the evidence", "Check for nuances", "Validate truth"],
      actionText: "Verify Truth",
      tip: "Be careful of 'absolute' words like 'always', 'never', or 'only'!",
    ),
    GameSubtype.sentenceOrderReading: GameBriefing(
      title: "Structure Architect",
      icon: Icons.architecture_rounded,
      objective:
          "Arrange scrambled sentences into their logical paragraph order.",
      rules: ["Find the logic", "Check transitions", "Rebuild the system"],
      actionText: "Rebuild Flow",
      tip:
          "Look for transition words like 'however', 'moreover', and 'finally'.",
    ),
    GameSubtype.readingSpeedCheck: GameBriefing(
      title: "Velocity Reader",
      icon: Icons.speed_rounded,
      objective: "Test your reading speed and comprehension under a timer.",
      rules: ["Read fast", "Maintain accuracy", "Beat the timer"],
      actionText: "Race Timer",
      tip:
          "Don't subvocalize (read out loud in your head)! Let your eyes glide over the text.",
    ),
    GameSubtype.guessTitle: GameBriefing(
      title: "Title Tactician",
      icon: Icons.title_rounded,
      objective: "Read the passage and choose the most appropriate title.",
      rules: ["Identify main theme", "Check all options", "Summarize the core"],
      actionText: "Deduce Title",
      tip:
          "A great title captures the 'big picture'. Look for the most repeated themes!",
    ),
    GameSubtype.readAndMatch: GameBriefing(
      title: "Semantic Bridge",
      icon: Icons.bolt_rounded,
      objective: "Connect related facts and concepts from the reading passage.",
      rules: ["Bridge the gaps", "Use lasers to link", "Confirm relationships"],
      actionText: "Bridge Gaps",
      tip:
          "Think about how concepts relate—is it cause and effect, or part and whole?",
    ),
    GameSubtype.paragraphSummary: GameBriefing(
      title: "Summary Sieve",
      icon: Icons.short_text_rounded,
      objective:
          "Select the single sentence that best summarizes the paragraph.",
      rules: ["Filter out details", "Find the main point", "Stay objective"],
      actionText: "Summarize Now",
      tip:
          "Avoid sentences that only mention one small detail; look for the overarching idea!",
    ),
    GameSubtype.readingInference: GameBriefing(
      title: "Subtext Sleuth",
      icon: Icons.biotech_rounded,
      objective:
          "Identify implications in the text that are not explicitly stated.",
      rules: ["Read between lines", "Detect subtext", "Infer correctly"],
      actionText: "Deduce Subtext",
      tip: "The author's tone and choice of words often hide a deeper meaning.",
    ),
    GameSubtype.readingConclusion: GameBriefing(
      title: "Logical Finisher",
      icon: Icons.last_page_rounded,
      objective:
          "Predict the most logical conclusion based on the reading text.",
      rules: ["Follow the logic", "Predict outcome", "Verify with evidence"],
      actionText: "Predict Final",
      tip:
          "Follow the clues the author left! Where does the logic naturally lead?",
    ),
    GameSubtype.clozeTest: GameBriefing(
      title: "Context Mastery",
      icon: Icons.format_color_text_rounded,
      objective:
          "Drag the correct word into the blank to complete the sentence.",
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
      objective: "Scan the text fast to locate specific facts or main ideas.",
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
          "Arrange sentence fragments into a grammatically correct order. Mastering sentence structure ensures your writing is clear, professional, and easily understood in real-world communication.",
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
          "Launch the correct word fragment into the sentence gap. Mastering sentence structure ensures your writing is clear, professional, and easily understood in real-world communication.",
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
          "Tap the floating emojis to discover keywords and write a descriptive paragraph based on the scenario. Mastering descriptive writing ensures you can paint clear pictures with words in real-world communication.",
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
          "Scrub the logical decay and select the correct replacement word. Mastering structural clarity ensures your writing is professional and highly effective in real-world communication.",
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
      objective: "Write a brief, concise, and direct response to the prompt. Mastering clear short-form writing ensures you can communicate ideas effectively and professionally in real-world scenarios.",
      rules: ["Be direct", "Stay on topic", "Mind your grammar"],
      actionText: "Submit Answer",
      tip: "PRO TIP: Get straight to the point! Keep it short and accurate.",
    ),
    GameSubtype.opinionWriting: GameBriefing(
      title: "Vocal Pen",
      icon: Icons.rate_review_rounded,
      objective:
          "Analyze the statements and categorize them as supporting or opposing the given opinion. Mastering this logical classification improves your ability to structure persuasive arguments in real-world communication.",
      rules: [
        "Read the prompt",
        "Weigh the arguments",
        "Balance the scale",
      ],
      actionText: "Balance Scale",
      tip:
          "PRO TIP: A 'Pro' always supports the prompt's opinion, while a 'Con' highlights a drawback or opposing view.",
    ),
    GameSubtype.dailyJournal: GameBriefing(
      title: "Daily Chronicler",
      icon: Icons.auto_stories_rounded,
      objective:
          "Read the prompt and write a short personal journal reflection. Mastering this helps you articulate your daily experiences logically in real-world conversations.",
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
          "Read the story and arrange the key events in chronological order to form a concise summary. Mastering summary writing helps you process complex information and communicate ideas clearly in the real world.",
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
      objective: "Compose a professional and contextually appropriate email by arranging its key parts. Mastering email structure ensures your writing is clear, polite, and effective for real-world communication.",
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
          "Identify and replace the errored syntax phrase. Mastering structural accuracy ensures your writing is professional, clear, and highly effective in real-world communication.",
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
          "Sequence the paragraph blocks into their correct logical structure. Mastering structural progression ensures your ideas flow logically, making your writing persuasive and clear in real-world communication.",
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
          "Identify and choose the correct form to complete the sentence.",
      rules: ["Identify errors", "Choose the correction", "Master the rules"],
      actionText: "Fix Structure",
      tip:
          "PRO TIP: Read the sentence out loud in your head! Often, you can 'hear' if a rule is broken.",
    ),
    GameSubtype.sentenceCorrection: GameBriefing(
      title: "Error Auditor",
      icon: Icons.spellcheck_rounded,
      objective:
          "Scan the text for grammatical errors and apply the correct fix.",
      rules: ["Find the glitch", "Apply the fix", "Verify the meaning"],
      actionText: "Audit Text",
      tip:
          "PRO TIP: Focus on subject-verb agreement first—it's the most common source of errors!",
    ),
    GameSubtype.wordReorder: GameBriefing(
      title: "Syntax Reorder",
      icon: Icons.reorder_rounded,
      objective: "Arrange scrambled words into a grammatically sound sentence.",
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
      objective: "Select or place verbs in their correct chronological tenses.",
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
          "Identify and label the correct parts of speech in the sentence.",
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
      objective: "Choose the correct verb form to match the subject.",
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
      objective: "Choose the appropriate conjunction to connect the clauses.",
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
          "Switch between Active and Passive voice without changing the meaning.",
      rules: [
        "Identify the agent",
        "Change the verb form",
        "Keep meaning intact",
      ],
      actionText: "Swap Voice",
      tip:
          "PRO TIP: In Passive voice, the object becomes the star! Use 'by [someone]' only if needed.",
    ),
    GameSubtype.questionFormatter: GameBriefing(
      title: "Inquiry Logic",
      icon: Icons.help_outline_rounded,
      objective:
          "Arrange words or choose forms to create an accurate question.",
      rules: ["Invert subject/verb", "Add auxiliary verbs", "Match the tense"],
      actionText: "Format Inquiry",
      tip:
          "PRO TIP: Remember the 'Qu-A-S-V' rule: Question word, Auxiliary, Subject, Verb!",
    ),
    GameSubtype.articleInsertion: GameBriefing(
      title: "Article Orb",
      icon: Icons.bubble_chart_rounded,
      objective:
          "Insert the correct article to complete the sentence structure and specify the noun.",
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
          "Place modifiers in the correct position to clarify the sentence.",
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
      objective: "Select the modal verb that best fits the sentence's context.",
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
      objective: "Choose the correct preposition to complete the sentence.",
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
          "Select the correct pronoun that clearly resolves the sentence.",
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
          "Place commas, periods, or semi-colons in the correct locations.",
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
          "Use relative pronouns (who, which, that) to connect the clauses.",
      rules: ["Identify the noun", "Choose the pronoun", "Link the detail"],
      actionText: "Link Relative",
      tip:
          "PRO TIP: Use 'Who' for people and 'Which' or 'That' for things and animals.",
    ),
    GameSubtype.conditionals: GameBriefing(
      title: "If-Logic",
      icon: Icons.alt_route_rounded,
      objective:
          "Complete the conditional sentence using the correct verb form.",
      rules: [
        "Identify the condition",
        "Match the tense sequence",
        "Predict the result",
      ],
      actionText: "Solve Logic",
      tip:
          "PRO TIP: In 'Second Conditional' (imaginary), use 'If I WERE' even for singular subjects!",
    ),
    GameSubtype.conjunctions: GameBriefing(
      title: "Logic Junction",
      icon: Icons.join_inner_rounded,
      objective: "Select the correct conjunction to bridge the thoughts.",
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
          "Convert direct quotes into reported speech with correct tenses.",
      rules: [
        "Shift tenses backward",
        "Update time markers",
        "Correct tenses & pronouns",
      ],
      actionText: "Report Speech",
      tip:
          "PRO TIP: 'Present' becomes 'Past'! If someone said 'I am here', report 'they were there'.",
    ),
    // 6. Vocabulary
    GameSubtype.flashcards: GameBriefing(
      title: "Flashcards",
      icon: Icons.style_rounded,
      objective: "Tap to flip flashcards and swipe through to master terms.",
      rules: ["Tap to flip", "Swipe Right = Known", "Swipe Left = Review"],
      actionText: "Master Now",
      tip:
          "Speed isn't the goal—mastery is! Take your time to review definitions.",
    ),
    GameSubtype.synonymSearch: GameBriefing(
      title: "Word Warp",
      icon: Icons.cyclone,
      objective: "Identify and match the correct synonym for the target word.",
      rules: ["Find the twin", "Drag into Warp Gate", "Avoid distractions"],
      actionText: "Start Warp",
      tip: "Focus on the core meaning, and filter out visual distractions!",
    ),
    GameSubtype.antonymSearch: GameBriefing(
      title: "Polarity Pull",
      icon: Icons.electrical_services_rounded,
      objective: "Identify and select the correct antonym for the target word.",
      rules: ["Find the Antonym", "Opposites Attract", "3 Hearts left"],
      actionText: "Start Pull",
      tip: "Opposite meaning = Opposite pole! Match them quickly.",
    ),
    GameSubtype.contextClues: GameBriefing(
      title: "Detective Lens",
      icon: Icons.search_rounded,
      objective: "Use context clues to identify the meaning of unknown words.",
      rules: ["Drag to reveal clues", "Analyze context", "3 Hearts left"],
      actionText: "Start Scan",
      tip: "Clues often hide right next to the redacted or highlighted word!",
    ),
    GameSubtype.phrasalVerbs: GameBriefing(
      title: "Verb Vault",
      icon: Icons.vpn_key_rounded,
      objective:
          "Select correct prepositions or particles to complete phrasal verbs.",
      rules: ["Read Definition", "Select Particle", "Crack Vault"],
      actionText: "Start Hack",
      tip:
          "Particles change everything! 'Turn up' has a completely different meaning than 'turn down'.",
    ),
    GameSubtype.idioms: GameBriefing(
      title: "Emojify",
      icon: Icons.forum_rounded,
      objective: "Decode emojis and phrases into correct English idioms.",
      rules: ["Interpret emojis", "Select matching idiom", "3 Hearts left"],
      actionText: "Send Message",
      tip: "Idioms are colorful cultural keys! Don't take them literally.",
    ),
    GameSubtype.academicWord: GameBriefing(
      title: "Thesis Thrust",
      icon: Icons.auto_stories_rounded,
      objective:
          "Read the context carefully and select the advanced vocabulary word that fits perfectly.",
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
      title: "Topic Nexus",
      icon: Icons.category_rounded,
      objective: "Sort words into their correct thematic category bins.",
      rules: ["Analyze the word", "Swipe into matching bin", "Clear the queue"],
      actionText: "Start Sorting",
      tip: "Sorting by topic builds semantic memory 2x faster!",
    ),
    GameSubtype.wordFormation: GameBriefing(
      title: "Morpheme Mixer",
      icon: Icons.science_rounded,
      objective: "Combine prefixes, suffixes, and roots to form correct words.",
      rules: ["Analyze root", "Slide suffix", "Form word"],
      actionText: "Ready to Mix?",
      tip: "Suffixes change words from verbs to nouns or adjectives!",
    ),
    GameSubtype.prefixSuffix: GameBriefing(
      title: "Word Roots",
      icon: Icons.spa_rounded,
      objective:
          "Build words by attaching the correct prefixes or suffixes to roots.",
      rules: ["Analyze root", "Attach correct affix", "3 Hearts left"],
      actionText: "Build Words",
      tip:
          "Roots are the DNA of English! Master them to expand vocabulary rapidly.",
    ),
    GameSubtype.collocations: GameBriefing(
      title: "Pair Pop",
      icon: Icons.bubble_chart_rounded,
      objective:
          "Match words that naturally pair together (e.g., 'make a decision').",
      rules: ["Analyze anchor", "Select partner bubble", "Fuse the pair"],
      actionText: "Initiate Fusion",
      tip:
          "Collocations are words that naturally go together like peanut butter and jelly!",
    ),
    GameSubtype.contextualUsage: GameBriefing(
      title: "Usage Unfold",
      icon: Icons.auto_stories_rounded,
      objective:
          "Identify the word that fits perfectly in the context of the sentence.",
      rules: ["Evaluate context", "Unfold the correct fit", "3 Hearts left"],
      actionText: "Unfold Truth",
      tip:
          "Nuance is key! Choose the word that logically belongs in the sentence.",
    ),
    // 7. Accent
    GameSubtype.minimalPairs: GameBriefing(
      title: "Sound Sorter",
      icon: Icons.compare_arrows_rounded,
      objective:
          "Master subtle phonetic differences by selecting the exact word you hear.",
      rules: [
        "Listen to the speaker",
        "Identify the subtle sound",
        "Select the correct option",
      ],
      actionText: "Sort Sounds",
      tip: "PRO TIP: Pay close attention to vowel length and tension!",
    ),
    GameSubtype.intonationMimic: GameBriefing(
      title: "Intonation Mimic",
      icon: Icons.waves_rounded,
      objective:
          "Listen to the sentence and identify its pitch pattern to master the natural melody of the language, which is highly useful for conveying emotion and intent clearly.",
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
          "Listen to the word and identify which part of the word is spoken the loudest.",
      rules: [
        "Listen for the loud part",
        "Check the length",
        "Select the stressed part",
      ],
      actionText: "Find Stress",
      tip:
          "PRO TIP: The stressed part of a word is always louder and slightly longer.",
    ),
    GameSubtype.wordLinking: GameBriefing(
      title: "Connect Words",
      icon: Icons.link_rounded,
      objective:
          "Listen to how two separate words are linked together into one smooth sound.",
      rules: [
        "Listen to the gap",
        "Find the linked words",
        "Choose the correct link",
      ],
      actionText: "Link Words",
      tip:
          "PRO TIP: English speakers often push the end of one word into the start of the next.",
    ),
    GameSubtype.shadowingChallenge: GameBriefing(
      title: "Shadow Challenge",
      icon: Icons.bolt_rounded,
      objective:
          "Listen to the speaker and tap the correct dialogue bubble to shadow their voice.",
      rules: [
        "Listen to the sentence",
        "Read the chat bubbles",
        "Tap the exact match",
      ],
      actionText: "Start Shadowing",
      tip:
          "PRO TIP: Don't overthink! Pick the sentence that exactly matches the audio.",
    ),
    GameSubtype.vowelDistinction: GameBriefing(
      title: "Vowel Sounds",
      icon: Icons.cyclone_rounded,
      objective:
          "Listen to the vowel sound and use the horizontal slider to find the perfect match.",
      rules: [
        "Listen to the open sound",
        "Slide left or right",
        "Lock your answer",
      ],
      actionText: "Find Vowel",
      tip:
          "PRO TIP: Vowels are a spectrum! Slide carefully until you find the exact sound.",
    ),
    GameSubtype.consonantClarity: GameBriefing(
      title: "Crystal Consonants",
      icon: Icons.graphic_eq_rounded,
      objective:
          "Identify the target consonant to refine your pronunciation and clear up real-world communication.",
      rules: [
        "Listen to the target word",
        "Analyze the mouth position",
        "Select the precise consonant",
      ],
      actionText: "Analyze Sound",
      tip:
          "PRO TIP: Feel where your tongue and lips are placed—physical awareness is key!",
    ),
    GameSubtype.pitchPatternMatch: GameBriefing(
      title: "Musical Melody",
      icon: Icons.music_note_rounded,
      objective:
          "Listen to the melody of the sentence and use the vertical fader to match the pitch.",
      rules: [
        "Listen to the melody",
        "Use the vertical fader",
        "Lock your choice",
      ],
      actionText: "Match Melody",
      tip:
          "PRO TIP: Slide the fader up if the speaker's voice gets higher at the end!",
    ),
    GameSubtype.speedVariance: GameBriefing(
      title: "Speaking Speed",
      icon: Icons.speed_rounded,
      objective:
          "Listen to the phrase and identify if it was spoken at a fast, medium, or slow tempo.",
      rules: ["Listen to the speed", "Check the options", "Select the tempo"],
      actionText: "Select Speed",
      tip:
          "PRO TIP: Even when people speak fast, the words still link together smoothly.",
    ),
    GameSubtype.dialectDrill: GameBriefing(
      title: "Dialect Drill",
      icon: Icons.public_rounded,
      objective:
          "Identify and distinguish regional pronunciations to master global communication.",
      rules: [
        "Listen closely",
        "Compare pronunciations",
        "Select region",
      ],
      actionText: "Start Drill",
      tip:
          "PRO TIP: Pay attention to vowel shapes! American English often flattens vowels, while British English rounds them.",
    ),
    GameSubtype.connectedSpeech: GameBriefing(
      title: "Connected Speech",
      icon: Icons.settings_input_composite_rounded,
      objective:
          "Native speakers link words together. Listen closely to how the words connect, then choose the card that shows the correct sound change. Mastering connected speech ensures you can understand fast native speakers and sound fluent yourself in real-world communication.",
      rules: [
        "Listen to the linked words",
        "Notice which sound changes or drops",
        "Select the rule that applies",
      ],
      actionText: "Connect Words",
      tip:
          "PRO TIP: Try saying the words fast yourself! If you force every single letter, it feels unnatural. Real speech takes shortcuts.",
    ),
    GameSubtype.pitchModulation: GameBriefing(
      title: "Voice Emotion",
      icon: Icons.legend_toggle_rounded,
      objective:
          "Listen to the speaker's pitch and select the matching modulation pattern to master how English speakers convey energy and emotion through voice.",
      rules: [
        "Listen to the pitch",
        "Analyze the emotion",
        "Select the correct pattern",
      ],
      actionText: "Select Emotion",
      tip:
          "PRO TIP: A rising-falling pitch often shows energy or warmth, while a falling-rising pitch can signal hesitation or mild concern.",
    ),
    // 8. Roleplay
    GameSubtype.branchingDialogue: GameBriefing(
      title: "Social Simulator",
      icon: Icons.forum_rounded,
      objective:
          "Tap an answer or drag the decision probe to select the most natural, context-appropriate conversational response.",
      rules: ["Analyze the scene", "Flick decision probe", "React naturally"],
      actionText: "Enter Simulation",
      tip:
          "PRO TIP: Pay attention to the subtle social cues! Being polite and direct often opens the right doors.",
    ),
    GameSubtype.situationalResponse: GameBriefing(
      title: "Reflex Responder",
      icon: Icons.flash_on_rounded,
      objective:
          "Choose the most appropriate and polite social response for the scenario.",
      rules: ["Match social tone", "Be polite/direct", "3 Hearts left"],
      actionText: "Respond Now",
      tip:
          "PRO TIP: Use expressions like 'I would appreciate it' or 'Would you mind'!",
    ),
    GameSubtype.jobInterview: GameBriefing(
      title: "Career Closer",
      icon: Icons.business_center_rounded,
      objective:
          "Choose professional responses to nail your high-stakes job interview.",
      rules: ["Be professional", "Highlight core skills", "Stay confident"],
      actionText: "Start Interview",
      tip:
          "PRO TIP: Frame replies to show how your experience solves their business needs.",
    ),
    GameSubtype.medicalConsult: GameBriefing(
      title: "Health Liaison",
      icon: Icons.medical_services_rounded,
      objective:
          "Clearly explain symptoms or follow a doctor's detailed instructions.",
      rules: ["Be accurate", "Describe physical feelings", "3 Hearts left"],
      actionText: "Start Consult",
      tip:
          "PRO TIP: Use specific descriptors like 'throbbing', 'sharp', or 'dull ache'.",
    ),
    GameSubtype.gourmetOrder: GameBriefing(
      title: "Order Master",
      icon: Icons.restaurant_rounded,
      objective:
          "Order food, request custom adjustments, and settle restaurant bills.",
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
          "Manage check-ins, navigate directions, and handle hotel booking requests.",
      rules: ["Check travel tickets", "Follow directions", "Ask for support"],
      actionText: "Start Journey",
      tip:
          "PRO TIP: Confirm directions by repeating them back to check understanding.",
    ),
    GameSubtype.conflictResolver: GameBriefing(
      title: "Peace Maker",
      icon: Icons.handshake_rounded,
      objective:
          "Resolve conversational arguments and misunderstandings using tactful words.",
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
          "Deliver a compelling, high-impact business message in 30 seconds.",
      rules: ["Be concise", "High emotional impact", "3 Hearts left"],
      actionText: "Start Pitch",
      tip:
          "PRO TIP: Lead with a massive hook that frames a relatable daily problem.",
    ),
    GameSubtype.socialSpark: GameBriefing(
      title: "Charisma Core",
      icon: Icons.celebration_rounded,
      objective:
          "Initiate and sustain engaging small talk with new acquaintances.",
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
          "Communicate clearly and stay calm under pressure in crisis scenarios.",
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
          "Arrange the scrambled sentences into the correct logical order to master paragraph cohesion, which is highly useful for clear and effective communication.",
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
          "Listen carefully to the native speaker and repeat the sentence, matching their exact pronunciation, stress, and rhythm.",
      rules: [
        "Listen to the example",
        "Record your voice",
        "Match the accent",
      ],
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
              "LEARN LETTERS: Match the letters to their sounds and shapes!",
          rules: [
            "Follow the ABCs",
            "Find the matching pair",
            "Listen to the letter",
          ],
          actionText: "Play ABCs",
          tip: "Sing the ABC song to help you remember the order! 🎵",
        );
      case 'animals':
        return const GameBriefing(
          title: "Animal Safari",
          icon: Icons.pets_rounded,
          objective:
              "EXPLORE NATURE: Learn the names and sounds of your favorite animals!",
          rules: [
            "Watch the animals",
            "Listen to their sounds",
            "Match the names",
          ],
          actionText: "Go Safari",
          tip: "Try making the animal sound yourself to remember it better! 🦁",
        );
      case 'numbers':
        return const GameBriefing(
          title: "Number Fun",
          icon: Icons.numbers_rounded,
          objective:
              "COUNTING TIME: Learn to count and recognize numbers 1 to 100!",
          rules: [
            "Count the objects",
            "Pick the right number",
            "Say it out loud",
          ],
          actionText: "Start Counting",
          tip: "Use your fingers to count along with the game! 🖐️",
        );
      case 'colors':
        return const GameBriefing(
          title: "Rainbow World",
          icon: Icons.palette_rounded,
          objective:
              "COLOR MIXER: Identify and name all the colors of the rainbow!",
          rules: ["Look at the colors", "Match the word", "Paint the world"],
          actionText: "Paint Colors",
          tip:
              "Look around your room—how many colors from the game can you see? 🌈",
        );
      case 'fruits':
        return const GameBriefing(
          title: "Fruit Garden",
          icon: Icons.shopping_basket_rounded,
          objective:
              "TASTY LEARNING: Discover delicious fruits and their healthy names!",
          rules: ["Pick the fruit", "Match the shape", "Learn the name"],
          actionText: "Pick Fruits",
          tip: "Fruits are super healthy and give you energy to play! 🍎",
        );
      case 'shapes':
        return const GameBriefing(
          title: "Shape Explorer",
          icon: Icons.category_rounded,
          objective:
              "GEOMETRY FUN: Learn about circles, squares, triangles, and more!",
          rules: ["Find the shape", "Match the edges", "Learn the name"],
          actionText: "Explore Shapes",
          tip:
              "Shapes are everywhere! A clock is a circle and a door is a rectangle. 📐",
        );
      case 'body_parts':
        return const GameBriefing(
          title: "My Body",
          icon: Icons.accessibility_new_rounded,
          objective:
              "SELF DISCOVERY: Learn the names of different parts of your body!",
          rules: ["Touch your nose", "Find the eyes", "Name the parts"],
          actionText: "Start Learning",
          tip: "Can you point to the body part as you hear its name? 🧍",
        );
      case 'family':
        return const GameBriefing(
          title: "Family Tree",
          icon: Icons.family_restroom_rounded,
          objective:
              "KINDRED SPIRITS: Learn about family members like Mom, Dad, and more!",
          rules: ["Meet the family", "Match the names", "Listen to the roles"],
          actionText: "Meet Family",
          tip: "Family is all about love and helping each other! ❤️",
        );
      case 'food_kids':
        return const GameBriefing(
          title: "Yummy Food",
          icon: Icons.restaurant_rounded,
          objective:
              "CHEF'S KITCHEN: Learn the names of yummy foods we eat every day!",
          rules: ["See the food", "Match the taste", "Name the meal"],
          actionText: "Eat Up",
          tip: "Eating a variety of foods helps you grow big and strong! 🥛",
        );
      case 'clothing':
        return const GameBriefing(
          title: "Dress Up",
          icon: Icons.checkroom_rounded,
          objective:
              "FASHION FUN: Learn the names of clothes like shirts, hats, and shoes!",
          rules: ["Pick the outfit", "Dress the buddy", "Name the clothes"],
          actionText: "Get Dressed",
          tip: "What are you wearing today? Try to name it in English! 👕",
        );
      case 'nature':
        return const GameBriefing(
          title: "Nature Walk",
          icon: Icons.forest_rounded,
          objective:
              "OUTDOOR FUN: Explore trees, flowers, the sun, and the moon!",
          rules: ["See the plants", "Look at the sky", "Name nature"],
          actionText: "Start Walk",
          tip:
              "Nature is beautiful! Always remember to be kind to the Earth. 🌳",
        );
      case 'transport':
        return const GameBriefing(
          title: "Zoom Zoom!",
          icon: Icons.directions_car_rounded,
          objective:
              "FAST TRAVEL: Learn about cars, planes, trains, and boats!",
          rules: ["Watch them go", "Listen to engines", "Match the vehicle"],
          actionText: "Start Engine",
          tip: "Which way do you like to travel? Beep beep! 🚗",
        );
      case 'emotions':
        return const GameBriefing(
          title: "Feeling Happy",
          icon: Icons.mood_rounded,
          objective:
              "EMOTION CHECK: Understand feelings like happy, sad, and surprised!",
          rules: ["Look at the faces", "Match the feeling", "Be kind"],
          actionText: "Share Feelings",
          tip:
              "It's okay to feel different things! Talk to a buddy about it. 😊",
        );
      case 'school':
        return const GameBriefing(
          title: "School Days",
          icon: Icons.school_rounded,
          objective:
              "CLASSROOM FUN: Learn about pencils, books, and your teacher!",
          rules: ["Pack your bag", "Find the tools", "Learn and play"],
          actionText: "Go to School",
          tip: "School is a place to make friends and learn new things! 🎒",
        );
      case 'home_kids':
        return const GameBriefing(
          title: "My Sweet Home",
          icon: Icons.home_rounded,
          objective:
              "HOUSE TOUR: Discover rooms and things found in your house!",
          rules: ["Visit the rooms", "Find the items", "Name the furniture"],
          actionText: "Enter House",
          tip: "There's no place like home! What's your favorite room? 🏠",
        );
      case 'opposites':
        return const GameBriefing(
          title: "Big and Small",
          icon: Icons.compare_rounded,
          objective:
              "DIFFERENCE DETECTOR: Learn about opposites like hot/cold and up/down!",
          rules: ["See the difference", "Match the pair", "Find the opposite"],
          actionText: "Match Pairs",
          tip:
              "Opposites are everywhere! Like the sun is 'hot' and ice is 'cold'. 🧊",
        );
      case 'verbs':
        return const GameBriefing(
          title: "Action Time!",
          icon: Icons.directions_run_rounded,
          objective:
              "ACTIVE LEARNING: Learn action words like run, jump, and sleep!",
          rules: ["Do the action", "Watch the buddy", "Match the verb"],
          actionText: "Get Active",
          tip: "Can you jump as you hear the word 'jump'? Give it a try! 🏃",
        );
      case 'prepositions':
        return const GameBriefing(
          title: "Where is it?",
          icon: Icons.location_on_rounded,
          objective:
              "POSITION FINDER: Learn words like in, on, under, and next to!",
          rules: ["Find the object", "Check the spot", "Learn the position"],
          actionText: "Find It",
          tip:
              "The cat is 'on' the mat! Can you find something 'under' your chair? 📦",
        );
      case 'routine':
        return const GameBriefing(
          title: "My Daily Day",
          icon: Icons.today_rounded,
          objective:
              "DAILY HABITS: Learn about brushing teeth, eating, and sleeping!",
          rules: ["Follow the day", "Sequence the habits", "Learn the names"],
          actionText: "Start Day",
          tip: "Having a good routine helps you stay healthy and happy! 🪥",
        );
      case 'phonics':
        return const GameBriefing(
          title: "Sound Master",
          icon: Icons.record_voice_over_rounded,
          objective:
              "PHONICS POWER: Master the sounds of different letters and blends!",
          rules: ["Listen to sound", "Say it clearly", "Match the blend"],
          actionText: "Make Sounds",
          tip:
              "Phonics is the secret key to reading! Keep practicing your sounds. 🗣️",
        );
      case 'time':
        return const GameBriefing(
          title: "Tick Tock!",
          icon: Icons.access_time_rounded,
          objective:
              "TIME TELLER: Learn about morning, afternoon, and the clock!",
          rules: ["Check the clock", "Follow the sun", "Name the time"],
          actionText: "Check Time",
          tip:
              "What time is it? The clock tells us when to play and when to eat! ⏰",
        );
      case 'day_night':
        return const GameBriefing(
          title: "Sun and Moon",
          icon: Icons.brightness_6_rounded,
          objective:
              "DAY & NIGHT: Learn about the differences between day and night!",
          rules: ["Watch the sky", "See the stars", "Match the activity"],
          actionText: "Switch Sky",
          tip: "The sun brings the day, and the moon brings the stars! 🌙",
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

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
    // 1. ELITE MASTERY
    GameSubtype.storyBuilder: const GameBriefing(
      title: "Story Builder",
      icon: Icons.reorder_rounded,
      objective:
          "Drag sentences into chronological order to rebuild the story.",
      rules: [
        "3 Hearts per mission",
        "2 Strikes (Mistakes Re-queued)",
        "Logic and context are key",
      ],
      actionText: "Build Story",
      tip:
          "PRO TIP: Look for transition words like 'However', 'Consequently', or 'Subsequently' to link sequences!",
    ),
    GameSubtype.idiomMatch: const GameBriefing(
      title: "Idiom Match",
      icon: Icons.psychology_rounded,
      objective: "Pair the idioms with their true definitions and meanings.",
      rules: [
        "Match correctly to win",
        "Avoid literal traps",
        "3 Hearts per mission",
      ],
      actionText: "Match Idioms",
      tip:
          "PRO TIP: Don't take idioms literally! They usually describe a feeling or social situation.",
    ),
    GameSubtype.speedSpelling: const GameBriefing(
      title: "Speed Spelling",
      icon: Icons.spellcheck_rounded,
      objective: "Spell the target word correctly before the timer runs out.",
      rules: [
        "Spelling must be exact",
        "Watch the timer",
        "3 Hearts per mission",
      ],
      actionText: "Start Spelling",
      tip:
          "PRO TIP: Trust your muscle memory! Trying to think about every letter can slow you down.",
    ),
    GameSubtype.accentShadowing: const GameBriefing(
      title: "Accent Shadowing",
      icon: Icons.mic_external_on_rounded,
      objective:
          "Speak along with the audio. Match the speaker's pitch and rhythm.",
      rules: [
        "Listen first, then speak",
        "Match the waveform",
        "3 Hearts per mission",
      ],
      actionText: "Shadow Voice",
      tip:
          "PRO TIP: Focus on the musicality! Accent is about the 'song' of the language.",
    ),

    // 2. GRAMMAR
    GameSubtype.voiceSwap: const GameBriefing(
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
    GameSubtype.directIndirectSpeech: const GameBriefing(
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
    GameSubtype.tenseMastery: const GameBriefing(
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
    GameSubtype.grammarQuest: const GameBriefing(
      title: "Grammar Core",
      icon: Icons.gavel_rounded,
      objective:
          "Identify and choose the correct form to complete the sentence.",
      rules: ["Identify errors", "Choose the correction", "Master the rules"],
      actionText: "Fix Structure",
      tip:
          "PRO TIP: Read the sentence out loud in your head! Often, you can 'hear' if a rule is broken.",
    ),
    GameSubtype.sentenceCorrection: const GameBriefing(
      title: "Error Auditor",
      icon: Icons.spellcheck_rounded,
      objective:
          "Scan the text for grammatical errors and apply the correct fix.",
      rules: ["Find the glitch", "Apply the fix", "Verify the meaning"],
      actionText: "Audit Text",
      tip:
          "PRO TIP: Focus on subject-verb agreement first—it's the most common source of errors!",
    ),
    GameSubtype.wordReorder: const GameBriefing(
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
    GameSubtype.partsOfSpeech: const GameBriefing(
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
    GameSubtype.subjectVerbAgreement: const GameBriefing(
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
    GameSubtype.clauseConnector: const GameBriefing(
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
    GameSubtype.questionFormatter: const GameBriefing(
      title: "Inquiry Logic",
      icon: Icons.help_outline_rounded,
      objective:
          "Arrange words or choose forms to create an accurate question.",
      rules: ["Invert subject/verb", "Add auxiliary verbs", "Match the tense"],
      actionText: "Format Inquiry",
      tip:
          "PRO TIP: Remember the 'Qu-A-S-V' rule: Question word, Auxiliary, Subject, Verb!",
    ),
    GameSubtype.articleInsertion: const GameBriefing(
      title: "Article Anchor",
      icon: Icons.anchor_rounded,
      objective:
          "Insert the correct article (a, an, the) or choose 'no article'.",
      rules: [
        "Check for specificity",
        "Identify first sounds",
        "Countable vs Uncountable",
      ],
      actionText: "Insert Articles",
      tip:
          "PRO TIP: Use 'The' for specific things we both know about, and 'A/An' for general things.",
    ),
    GameSubtype.modifierPlacement: const GameBriefing(
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
    GameSubtype.modalsSelection: const GameBriefing(
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
    GameSubtype.prepositionChoice: const GameBriefing(
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
    GameSubtype.pronounResolution: const GameBriefing(
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
    GameSubtype.punctuationMastery: const GameBriefing(
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
    GameSubtype.relativeClauses: const GameBriefing(
      title: "Relative Rail",
      icon: Icons.linear_scale_rounded,
      objective:
          "Use relative pronouns (who, which, that) to connect the clauses.",
      rules: ["Identify the noun", "Choose the pronoun", "Link the detail"],
      actionText: "Link Relative",
      tip:
          "PRO TIP: Use 'Who' for people and 'Which' or 'That' for things and animals.",
    ),
    GameSubtype.conditionals: const GameBriefing(
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
    GameSubtype.conjunctions: const GameBriefing(
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

    // 3. READING
    GameSubtype.skimmingScanning: const GameBriefing(
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
    GameSubtype.clozeTest: const GameBriefing(
      title: "Context Mastery",
      icon: Icons.format_color_text_rounded,
      objective: "Fill the blanks by choosing contextually correct words.",
      rules: [
        "Read before and after",
        "Check for collocations",
        "Ensure logical flow",
      ],
      actionText: "Fill Gaps",
      tip:
          "PRO TIP: Read the whole sentence first! Surrounding words reveal the needed part of speech.",
    ),
    GameSubtype.findWordMeaning: const GameBriefing(
      title: "Lexical Linker",
      icon: Icons.menu_book_rounded,
      objective:
          "Find and match word definitions directly within the passage context.",
      rules: ["Analyze context", "Match word to meaning", "Build vocabulary"],
      actionText: "Link Words",
      tip:
          "Context is your best friend! The surrounding words often reveal hidden meanings.",
    ),
    GameSubtype.guessTitle: const GameBriefing(
      title: "Title Tactician",
      icon: Icons.title_rounded,
      objective: "Read the passage and choose the most appropriate title.",
      rules: ["Identify main theme", "Check all options", "Summarize the core"],
      actionText: "Deduce Title",
      tip:
          "A great title captures the 'big picture'. Look for the most repeated themes!",
    ),
    GameSubtype.paragraphSummary: const GameBriefing(
      title: "Summary Sieve",
      icon: Icons.short_text_rounded,
      objective:
          "Select the single sentence that best summarizes the paragraph.",
      rules: ["Filter out details", "Find the main point", "Stay objective"],
      actionText: "Summarize Now",
      tip:
          "Avoid sentences that only mention one small detail; look for the overarching idea!",
    ),
    GameSubtype.readAndAnswer: const GameBriefing(
      title: "Insight Analyst",
      icon: Icons.fact_check_rounded,
      objective:
          "Read the passage and select correct answers to comprehension questions.",
      rules: ["Refer back to text", "Verify every detail", "Think critically"],
      actionText: "Analyze Text",
      tip:
          "Don't guess! The answer is ALWAYS in the text—you just have to find it.",
    ),
    GameSubtype.readAndMatch: const GameBriefing(
      title: "Semantic Bridge",
      icon: Icons.bolt_rounded,
      objective: "Connect related facts and concepts from the reading passage.",
      rules: ["Bridge the gaps", "Use lasers to link", "Confirm relationships"],
      actionText: "Bridge Gaps",
      tip:
          "Think about how concepts relate—is it cause and effect, or part and whole?",
    ),
    GameSubtype.readingConclusion: const GameBriefing(
      title: "Logical Finisher",
      icon: Icons.last_page_rounded,
      objective:
          "Predict the most logical conclusion based on the reading text.",
      rules: ["Follow the logic", "Predict outcome", "Verify with evidence"],
      actionText: "Predict Final",
      tip:
          "Follow the clues the author left! Where does the logic naturally lead?",
    ),
    GameSubtype.readingInference: const GameBriefing(
      title: "Subtext Sleuth",
      icon: Icons.biotech_rounded,
      objective:
          "Identify implications in the text that are not explicitly stated.",
      rules: ["Read between lines", "Detect subtext", "Infer correctly"],
      actionText: "Deduce Subtext",
      tip: "The author's tone and choice of words often hide a deeper meaning.",
    ),
    GameSubtype.readingSpeedCheck: const GameBriefing(
      title: "Velocity Reader",
      icon: Icons.speed_rounded,
      objective: "Test your reading speed and comprehension under a timer.",
      rules: ["Read fast", "Maintain accuracy", "Beat the timer"],
      actionText: "Race Timer",
      tip:
          "Don't subvocalize (read out loud in your head)! Let your eyes glide over the text.",
    ),
    GameSubtype.sentenceOrderReading: const GameBriefing(
      title: "Structure Architect",
      icon: Icons.architecture_rounded,
      objective:
          "Arrange scrambled sentences into their logical paragraph order.",
      rules: ["Find the logic", "Check transitions", "Rebuild the system"],
      actionText: "Rebuild Flow",
      tip:
          "Look for transition words like 'however', 'moreover', and 'finally'.",
    ),
    GameSubtype.trueFalseReading: const GameBriefing(
      title: "Truth Verifier",
      icon: Icons.verified_user_rounded,
      objective: "Determine if statements are true or false based on the text.",
      rules: ["Locate the evidence", "Check for nuances", "Validate truth"],
      actionText: "Verify Truth",
      tip: "Be careful of 'absolute' words like 'always', 'never', or 'only'!",
    ),

    // 4. VOCABULARY
    GameSubtype.flashcards: const GameBriefing(
      title: "Flashcards",
      icon: Icons.style_rounded,
      objective: "Tap to flip flashcards and swipe through to master terms.",
      rules: ["Tap to flip", "Swipe Right = Known", "Swipe Left = Review"],
      actionText: "Master Now",
      tip:
          "Speed isn't the goal—mastery is! Take your time to review definitions.",
    ),
    GameSubtype.topicVocab: const GameBriefing(
      title: "Topic Nexus",
      icon: Icons.category_rounded,
      objective: "Sort words into their correct thematic category bins.",
      rules: ["Analyze the word", "Swipe into matching bin", "Clear the queue"],
      actionText: "Start Sorting",
      tip: "Sorting by topic builds semantic memory 2x faster!",
    ),
    GameSubtype.prefixSuffix: const GameBriefing(
      title: "Word Roots",
      icon: Icons.spa_rounded,
      objective:
          "Build words by attaching the correct prefixes or suffixes to roots.",
      rules: ["Analyze root", "Attach correct affix", "3 Hearts left"],
      actionText: "Build Words",
      tip:
          "Roots are the DNA of English! Master them to expand vocabulary rapidly.",
    ),
    GameSubtype.wordFormation: const GameBriefing(
      title: "Morpheme Mixer",
      icon: Icons.science_rounded,
      objective: "Combine prefixes, suffixes, and roots to form correct words.",
      rules: ["Analyze root", "Slide suffix", "Form word"],
      actionText: "Ready to Mix?",
      tip: "Suffixes change words from verbs to nouns or adjectives!",
    ),
    GameSubtype.synonymSearch: const GameBriefing(
      title: "Word Warp",
      icon: Icons.cyclone,
      objective: "Identify and match the correct synonym for the target word.",
      rules: ["Find the twin", "Drag into Warp Gate", "Avoid distractions"],
      actionText: "Start Warp",
      tip: "Focus on the core meaning, and filter out visual distractions!",
    ),
    GameSubtype.antonymSearch: const GameBriefing(
      title: "Polarity Pull",
      icon: Icons.electrical_services_rounded,
      objective: "Identify and select the correct antonym for the target word.",
      rules: ["Find the Antonym", "Opposites Attract", "3 Hearts left"],
      actionText: "Start Pull",
      tip: "Opposite meaning = Opposite pole! Match them quickly.",
    ),
    GameSubtype.academicWord: const GameBriefing(
      title: "Thesis Thrust",
      icon: Icons.auto_stories_rounded,
      objective: "Identify advanced academic vocabulary matching the context.",
      rules: ["Analyze context", "Thrust the correct shard", "3 Hearts left"],
      actionText: "Initiate Thrust",
      tip: "Academic words are highly precise—pay attention to logical hints!",
    ),
    GameSubtype.contextClues: const GameBriefing(
      title: "Detective Lens",
      icon: Icons.search_rounded,
      objective: "Use context clues to identify the meaning of unknown words.",
      rules: ["Drag to reveal clues", "Analyze context", "3 Hearts left"],
      actionText: "Start Scan",
      tip: "Clues often hide right next to the redacted or highlighted word!",
    ),
    GameSubtype.collocations: const GameBriefing(
      title: "Pair Pop",
      icon: Icons.bubble_chart_rounded,
      objective:
          "Match words that naturally pair together (e.g., 'make a decision').",
      rules: ["Analyze anchor", "Select partner bubble", "Fuse the pair"],
      actionText: "Initiate Fusion",
      tip:
          "Collocations are words that naturally go together like peanut butter and jelly!",
    ),
    GameSubtype.phrasalVerbs: const GameBriefing(
      title: "Verb Vault",
      icon: Icons.vpn_key_rounded,
      objective:
          "Select correct prepositions or particles to complete phrasal verbs.",
      rules: ["Read Definition", "Select Particle", "Crack Vault"],
      actionText: "Start Hack",
      tip:
          "Particles change everything! 'Turn up' has a completely different meaning than 'turn down'.",
    ),
    GameSubtype.idioms: const GameBriefing(
      title: "Emojify",
      icon: Icons.forum_rounded,
      objective: "Decode emojis and phrases into correct English idioms.",
      rules: ["Interpret emojis", "Select matching idiom", "3 Hearts left"],
      actionText: "Send Message",
      tip: "Idioms are colorful cultural keys! Don't take them literally.",
    ),
    GameSubtype.contextualUsage: const GameBriefing(
      title: "Usage Unfold",
      icon: Icons.auto_stories_rounded,
      objective:
          "Identify the word that fits perfectly in the context of the sentence.",
      rules: ["Evaluate context", "Unfold the correct fit", "3 Hearts left"],
      actionText: "Unfold Truth",
      tip:
          "Nuance is key! Choose the word that logically belongs in the sentence.",
    ),

    // 5. WRITING
    GameSubtype.sentenceBuilder: const GameBriefing(
      title: "Sentence Architect",
      icon: Icons.architecture_rounded,
      objective:
          "Arrange sentence fragments into a grammatically correct order.",
      rules: [
        "Start with Subject",
        "Identify the Verb",
        "Check ending punctuation",
      ],
      actionText: "Build Sentence",
      tip: "PRO TIP: Start with the 'Who' or 'What', then find the 'Action'!",
    ),
    GameSubtype.completeSentence: const GameBriefing(
      title: "Fragment Fixer",
      icon: Icons.healing_rounded,
      objective:
          "Complete fragments by choosing or writing correct missing parts.",
      rules: [
        "Identify missing part",
        "Maintain the tone",
        "Verify logical structure",
      ],
      actionText: "Fix Fragment",
      tip:
          "PRO TIP: A complete sentence needs both a Subject and a Verb at minimum!",
    ),
    GameSubtype.describeSituationWriting: const GameBriefing(
      title: "Context Scribe",
      icon: Icons.description_rounded,
      objective:
          "Write a descriptive paragraph based on the scenario or image.",
      rules: [
        "Use vivid adjectives",
        "Be specific & clear",
        "Show, don't just tell",
      ],
      actionText: "Scribe Scene",
      tip: "PRO TIP: Use sensory words! Describe what is seen, heard, or felt.",
    ),
    GameSubtype.fixTheSentence: const GameBriefing(
      title: "Clarity Editor",
      icon: Icons.edit_rounded,
      objective:
          "Scan the sentence and correct grammatical and stylistic errors.",
      rules: ["Find the flaw", "Rewrite for clarity", "3 Hearts left"],
      actionText: "Apply Edit",
      tip:
          "PRO TIP: Read it out loud in your head! If it sounds clumsy, revise it.",
    ),
    GameSubtype.shortAnswerWriting: const GameBriefing(
      title: "Briefing Pro",
      icon: Icons.short_text_rounded,
      objective: "Write a brief, concise, and direct response to the prompt.",
      rules: ["Be direct", "Stay on topic", "Mind your grammar"],
      actionText: "Submit Answer",
      tip: "PRO TIP: Get straight to the point! Keep it short and accurate.",
    ),
    GameSubtype.opinionWriting: const GameBriefing(
      title: "Vocal Pen",
      icon: Icons.rate_review_rounded,
      objective:
          "Write a brief statement expressing and defending your opinion.",
      rules: [
        "State opinion",
        "Provide one solid reason",
        "Use persuasive language",
      ],
      actionText: "Express View",
      tip:
          "PRO TIP: Use transitions like 'In my view', 'For instance', or 'Consequently'.",
    ),
    GameSubtype.dailyJournal: const GameBriefing(
      title: "Daily Chronicler",
      icon: Icons.auto_stories_rounded,
      objective:
          "Write a short personal journal reflection based on the prompt.",
      rules: [
        "Be reflective",
        "Use appropriate tenses",
        "Focus on clear narrative",
      ],
      actionText: "Log Entry",
      tip:
          "PRO TIP: Use sequential markers like 'First', 'Later', and 'Eventually'.",
    ),
    GameSubtype.summarizeStoryWriting: const GameBriefing(
      title: "Essence Extractor",
      icon: Icons.compress_rounded,
      objective: "Read the story and draft a concise, objective summary.",
      rules: ["Remove fluff", "Highlight key events", "Stay objective"],
      actionText: "Summarize Now",
      tip:
          "PRO TIP: Identify the 'Who', 'What', 'Where', and 'Why' of the plot.",
    ),
    GameSubtype.writingEmail: const GameBriefing(
      title: "Email Expert",
      icon: Icons.alternate_email_rounded,
      objective: "Compose a professional and contextually appropriate email.",
      rules: [
        "Use right greeting",
        "State clear purpose",
        "Use formal closing",
      ],
      actionText: "Send Mail",
      tip:
          "PRO TIP: Clear subject lines and direct greetings set the professional tone.",
    ),
    GameSubtype.correctionWriting: const GameBriefing(
      title: "Deep Editor",
      icon: Icons.fact_check_rounded,
      objective:
          "Polish and rewrite the paragraph to fix all structural issues.",
      rules: [
        "Check all rules",
        "Improve logical flow",
        "Aim for 100% accuracy",
      ],
      actionText: "Final Polish",
      tip:
          "PRO TIP: Look for repetitive words and swap them for rich synonyms!",
    ),
    GameSubtype.essayDrafting: const GameBriefing(
      title: "Essay Architect",
      icon: Icons.article_rounded,
      objective:
          "Draft a structured essay with an introduction, body, and conclusion.",
      rules: [
        "Clear thesis",
        "Logical body paragraphs",
        "Strong closing summary",
      ],
      actionText: "Draft Essay",
      tip: "PRO TIP: Ensure each body paragraph has a clear topic sentence.",
    ),

    // 6. LISTENING
    GameSubtype.ambientId: const GameBriefing(
      title: "Spatial Anchor",
      icon: Icons.radar_rounded,
      objective:
          "Listen to the background audio and identify the scenario location.",
      rules: ["Listen to background", "Scan the radar", "Anchor the location"],
      actionText: "Anchor Location",
      tip: "Focus on ambient sounds like footsteps, echoes, wind, or hums!",
    ),
    GameSubtype.audioFillBlanks: const GameBriefing(
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
    GameSubtype.audioMultipleChoice: const GameBriefing(
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
    GameSubtype.audioSentenceOrder: const GameBriefing(
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
    GameSubtype.audioTrueFalse: const GameBriefing(
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
    GameSubtype.detailSpotlight: const GameBriefing(
      title: "Spotlight Search",
      icon: Icons.flashlight_on_rounded,
      objective:
          "Listen for specific names, numbers, or details within the passage.",
      rules: ["Scan details", "Listen for target keywords", "Identify match"],
      actionText: "Start Search",
      tip:
          "Note details as you listen—rushing to answer from memory can be tricky!",
    ),
    GameSubtype.emotionRecognition: const GameBriefing(
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
    GameSubtype.fastSpeechDecoder: const GameBriefing(
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
    GameSubtype.listeningInference: const GameBriefing(
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
    GameSubtype.soundImageMatch: const GameBriefing(
      title: "Thematic Linker",
      icon: Icons.category_rounded,
      objective:
          "Listen to the audio sound and match it with the correct visual image.",
      rules: ["Scan tiles", "Match sound to symbol", "Confirm thematic link"],
      actionText: "Confirm Link",
      tip:
          "Try to describe the sound in one word before selecting your choice.",
    ),

    // 7. ACCENT
    GameSubtype.minimalPairs: const GameBriefing(
      title: "Minimal Distinctions",
      icon: Icons.compare_arrows_rounded,
      objective:
          "Distinguish between words with minor sound differences (e.g., live vs leave).",
      rules: ["Listen to the vowel", "Compare lengths", "Identify the match"],
      actionText: "Match Sound",
      tip: "PRO TIP: Pay attention to mouth shape and vowel duration!",
    ),
    GameSubtype.intonationMimic: const GameBriefing(
      title: "Pitch Mimic",
      icon: Icons.waves_rounded,
      objective:
          "Repeat the sentence mimicking the rising and falling native pitch curves.",
      rules: ["Watch the waveform", "Match the peaks", "3 Hearts left"],
      actionText: "Mimic Now",
      tip: "PRO TIP: Exaggerate the rising pitch at the end of questions!",
    ),
    GameSubtype.syllableStress: const GameBriefing(
      title: "Stress Spotter",
      icon: Icons.priority_high_rounded,
      objective:
          "Pinpoint and highlight the primary stressed syllable in the word.",
      rules: ["Listen for loudness", "Check vowel clarity", "Mark the stress"],
      actionText: "Spot Stress",
      tip:
          "PRO TIP: Stressed syllables are louder, higher in pitch, and have longer vowels.",
    ),
    GameSubtype.wordLinking: const GameBriefing(
      title: "Fluid Flow",
      icon: Icons.link_rounded,
      objective:
          "Master word boundary linking to speak with native fluid rhythms.",
      rules: [
        "Listen for glides",
        "Connect consonants",
        "Avoid choppy phrases",
      ],
      actionText: "Start Glide",
      tip:
          "PRO TIP: Push end consonants directly into starting vowels of the next word.",
    ),
    GameSubtype.shadowingChallenge: const GameBriefing(
      title: "Speed Shadow",
      icon: Icons.bolt_rounded,
      objective:
          "Speak along with the native model with minimal delay to train fluency.",
      rules: ["No delay allowed", "Sync your voice", "3 Hearts left"],
      actionText: "Initiate Shadow",
      tip:
          "PRO TIP: Don't wait—begin speaking as soon as you hear the first sound!",
    ),
    GameSubtype.vowelDistinction: const GameBriefing(
      title: "Vowel Vortex",
      icon: Icons.cyclone_rounded,
      objective:
          "Isolate and master differences between subtle English vowel phonemes.",
      rules: [
        "Focus on tongue position",
        "Identify exact sound",
        "Select match",
      ],
      actionText: "Sort Vowels",
      tip:
          "PRO TIP: Drop your jaw slightly lower for vowels like /æ/ than for /ɛ/.",
    ),
    GameSubtype.consonantClarity: const GameBriefing(
      title: "Clear Consonants",
      icon: Icons.graphic_eq_rounded,
      objective:
          "Perfect pronunciation of difficult consonant clusters and friction sounds.",
      rules: ["Focus on airflow", "Check teeth position", "Record clearly"],
      actionText: "Speak Clearly",
      tip:
          "PRO TIP: Keep your tongue tip gently between your teeth for the /θ/ ('th') sound.",
    ),
    GameSubtype.pitchPatternMatch: const GameBriefing(
      title: "Musical Melody",
      icon: Icons.music_note_rounded,
      objective:
          "Replicate the musical timing and pitch contour of the full sentence.",
      rules: [
        "Listen to the melody",
        "Hum first if needed",
        "Speak with rhythm",
      ],
      actionText: "Match Melody",
      tip:
          "PRO TIP: Match the speed transitions—unstressed words are fast, stressed are slow.",
    ),
    GameSubtype.speedVariance: const GameBriefing(
      title: "Tempo Trainer",
      icon: Icons.speed_rounded,
      objective:
          "Speak the passage at fast, medium, and slow tempos with perfect clarity.",
      rules: [
        "Slow for accuracy",
        "Fast for fluency",
        "Maintain steady rhythm",
      ],
      actionText: "Train Tempo",
      tip: "PRO TIP: Keep clear boundaries between words even at high speed.",
    ),
    GameSubtype.dialectDrill: const GameBriefing(
      title: "Dialect Diver",
      icon: Icons.public_rounded,
      objective:
          "Identify and mimic pronunciation variants of major global dialects.",
      rules: ["Identify region", "Mimic vowel shifts", "3 Hearts left"],
      actionText: "Start Drill",
      tip: "PRO TIP: Pay attention to 'r' dropping and distinct vowel shifts.",
    ),
    GameSubtype.connectedSpeech: const GameBriefing(
      title: "Fusion Focus",
      icon: Icons.settings_input_composite_rounded,
      objective:
          "Master kontractions and reductions to speak with casual native speed.",
      rules: ["Identify reductions", "Speak fluently", "Sound natural"],
      actionText: "Start Fusion",
      tip:
          "PRO TIP: Reduction turns function words like 'to' or 'for' into quick sounds.",
    ),
    GameSubtype.pitchModulation: const GameBriefing(
      title: "Dynamic Range",
      icon: Icons.legend_toggle_rounded,
      objective:
          "Shift pitch ranges to express emotions like excitement or surprise.",
      rules: ["Match the emotion", "Shift your pitch", "3 Hearts left"],
      actionText: "Modulate Now",
      tip:
          "PRO TIP: Exaggerate pitch height for surprise, and lower it for calm authority.",
    ),

    // 8. ROLEPLAY
    GameSubtype.branchingDialogue: const GameBriefing(
      title: "Choice Navigator",
      icon: Icons.alt_route_rounded,
      objective:
          "Make conversational choices that lead to a successful scenario outcome.",
      rules: ["Listen to prompt", "Evaluate consequences", "Stay on mission"],
      actionText: "Choose Path",
      tip:
          "PRO TIP: Gauge the speaker's reaction and select the most empathetic reply.",
    ),
    GameSubtype.situationalResponse: const GameBriefing(
      title: "Reflex Responder",
      icon: Icons.flash_on_rounded,
      objective:
          "Choose the most appropriate and polite social response for the scenario.",
      rules: ["Match social tone", "Be polite/direct", "3 Hearts left"],
      actionText: "Respond Now",
      tip:
          "PRO TIP: Use expressions like 'I would appreciate it' or 'Would you mind'!",
    ),
    GameSubtype.jobInterview: const GameBriefing(
      title: "Career Closer",
      icon: Icons.business_center_rounded,
      objective:
          "Choose professional responses to nail your high-stakes job interview.",
      rules: ["Be professional", "Highlight core skills", "Stay confident"],
      actionText: "Start Interview",
      tip:
          "PRO TIP: Frame replies to show how your experience solves their business needs.",
    ),
    GameSubtype.medicalConsult: const GameBriefing(
      title: "Health Liaison",
      icon: Icons.medical_services_rounded,
      objective:
          "Clearly explain symptoms or follow a doctor's detailed instructions.",
      rules: ["Be accurate", "Describe physical feelings", "3 Hearts left"],
      actionText: "Start Consult",
      tip:
          "PRO TIP: Use specific descriptors like 'throbbing', 'sharp', or 'dull ache'.",
    ),
    GameSubtype.gourmetOrder: const GameBriefing(
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
    GameSubtype.travelDesk: const GameBriefing(
      title: "Global Traveler",
      icon: Icons.flight_takeoff_rounded,
      objective:
          "Manage check-ins, navigate directions, and handle hotel booking requests.",
      rules: ["Check travel tickets", "Follow directions", "Ask for support"],
      actionText: "Start Journey",
      tip:
          "PRO TIP: Confirm directions by repeating them back to check understanding.",
    ),
    GameSubtype.conflictResolver: const GameBriefing(
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
    GameSubtype.elevatorPitch: const GameBriefing(
      title: "Pitch Perfect",
      icon: Icons.rocket_launch_rounded,
      objective:
          "Deliver a compelling, high-impact business message in 30 seconds.",
      rules: ["Be concise", "High emotional impact", "3 Hearts left"],
      actionText: "Start Pitch",
      tip:
          "PRO TIP: Lead with a massive hook that frames a relatable daily problem.",
    ),
    GameSubtype.socialSpark: const GameBriefing(
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
    GameSubtype.emergencyHub: const GameBriefing(
      title: "Emergency Voice",
      icon: Icons.emergency_share_rounded,
      objective:
          "Communicate clearly and stay calm under pressure in crisis scenarios.",
      rules: ["Stay highly calm", "State location first", "Be exact & concise"],
      actionText: "Help Now",
      tip:
          "PRO TIP: Clear, slow, and specific directions save lives in critical moments.",
    ),

    // 9. SPEAKING
    GameSubtype.repeatSentence: const GameBriefing(
      title: "Echo Master",
      icon: Icons.graphic_eq_rounded,
      objective:
          "Listen carefully and repeat the sentence matching cadence and wave patterns.",
      rules: ["Hold mic to record", "Trace sound wave", "Master the cadence"],
      actionText: "Start Echo",
      tip:
          "PRO TIP: Match the stress rhythm—English flows in stressed clusters!",
    ),
    GameSubtype.pronunciationFocus: const GameBriefing(
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
    GameSubtype.dailyExpression: const GameBriefing(
      title: "Social Fluent",
      icon: Icons.chat_bubble_rounded,
      objective: "Speak daily expressions with natural, native-like emphasis.",
      rules: [
        "Listen to the model",
        "Record your expression",
        "Match social tone",
      ],
      actionText: "Speak Now",
      tip:
          "PRO TIP: Emphasize the keywords that carry the main emotional meaning.",
    ),
    GameSubtype.dialogueRoleplay: const GameBriefing(
      title: "Scene Architect",
      icon: Icons.theater_comedy_rounded,
      objective:
          "Speak your roleplay script lines with correct emotion and phrasing.",
      rules: ["Follow the script", "Speak with feeling", "Keep the flow going"],
      actionText: "Enter Scene",
      tip:
          "PRO TIP: Match your voice acting to the simulated character's mood!",
    ),
    GameSubtype.sceneDescriptionSpeaking: const GameBriefing(
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
    GameSubtype.situationSpeaking: const GameBriefing(
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
    GameSubtype.speakMissingWord: const GameBriefing(
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
    GameSubtype.speakOpposite: const GameBriefing(
      title: "Antonym Orator",
      icon: Icons.compare_arrows_rounded,
      objective: "Orally state the direct opposite/antonym of the prompt word.",
      rules: ["Analyze target", "Speak the antonym", "Maintain accuracy"],
      actionText: "Vocalize Opposite",
      tip:
          "PRO TIP: Think of contrasting poles (e.g. fast/slow, build/destroy).",
    ),
    GameSubtype.speakSynonym: const GameBriefing(
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
    GameSubtype.yesNoSpeaking: const GameBriefing(
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

import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

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

class GameInstructionService {
  static GameBriefing getBriefing(GameSubtype? type, String? fallbackTitle, {int level = 1}) {
    final baseBriefing = _getBaseBriefing(type, fallbackTitle);

    if (level == 100) {
      return GameBriefing(
        title: baseBriefing.title,
        icon: baseBriefing.icon,
        objective: baseBriefing.objective,
        rules: baseBriefing.rules,
        actionText: baseBriefing.actionText,
        tip: "🏆 MILESTONE: You've reached Level 100! This is an Elite Mastery test. Show us your best! ${baseBriefing.tip}",
      );
    }
    return baseBriefing;
  }

  static GameBriefing _getBaseBriefing(GameSubtype? type, String? fallbackTitle) {
    if (type == null) return getDefaultBriefing(fallbackTitle ?? "Quest");

    // --- 1. ELITE MASTERY (High Stakes) ---
    if (type == GameSubtype.storyBuilder) {
      return const GameBriefing(
        title: "Story Builder",
        icon: Icons.reorder_rounded,
        objective: "DRAG & REORDER: Reconstruct the logical flow of the story by dragging sentences into their correct chronological order.",
        rules: ["3 Hearts per mission", "2 Strikes (Mistakes Re-queued)", "Logic and context are key"],
        actionText: "Build Story",
        tip: "PRO TIP: Look for transition words like 'However', 'Consequently', or 'Subsequently' to link sequences!",
      );
    }
    if (type == GameSubtype.idiomMatch) {
      return const GameBriefing(
        title: "Idiom Match",
        icon: Icons.psychology_rounded,
        objective: "MATCH MEANINGS: Pair the colorful idiom with its literal meaning. Master the subtext of native conversation.",
        rules: ["Match correctly to win", "Avoid literal traps", "3 Hearts per mission"],
        actionText: "Match Idioms",
        tip: "PRO TIP: Don't take idioms literally! They usually describe a feeling or social situation using common objects.",
      );
    }
    if (type == GameSubtype.speedSpelling) {
      return const GameBriefing(
        title: "Speed Spelling",
        icon: Icons.spellcheck_rounded,
        objective: "BEAT THE CLOCK: Spell the target word accurately before time expires. Focus on common spelling traps.",
        rules: ["Spelling must be exact", "Watch the timer", "3 Hearts per mission"],
        actionText: "Start Spelling",
        tip: "PRO TIP: Trust your muscle memory! Trying to think about every letter can slow you down; let it flow.",
      );
    }
    if (type == GameSubtype.accentShadowing) {
      return const GameBriefing(
        title: "Accent Shadowing",
        icon: Icons.mic_external_on_rounded,
        objective: "RECORD & SHADOW: Speak along with the native model. Match their pitch, rhythm, and intonation perfectly.",
        rules: ["Listen first, then speak", "Match the waveform", "3 Hearts per mission"],
        actionText: "Shadow Voice",
        tip: "PRO TIP: Focus on the musicality! Accent is about the 'song' of the language—the rises and falls in pitch.",
      );
    }

    // --- 2. GRAMMAR (Technical Precision) ---
    if (type == GameSubtype.voiceSwap) {
      return const GameBriefing(
        title: "Voice Swap",
        icon: Icons.swap_horiz_rounded,
        objective: "TRANSFORM SENTENCES: Switch between Active and Passive voice without changing the core meaning.",
        rules: ["Identify the agent", "Change the verb form", "Keep the meaning intact"],
        actionText: "Swap Voice",
        tip: "PRO TIP: In Passive voice, the object becomes the star! Use 'by [someone]' only if the agent is important.",
      );
    }
    if (type == GameSubtype.directIndirectSpeech) {
      return const GameBriefing(
        title: "Speech Shift",
        icon: Icons.forum_rounded,
        objective: "CONVERT SPEECH: Change direct quotes into reported speech. Watch your tenses and pronouns!",
        rules: ["Shift tenses backward", "Update time markers", "Correct the pronouns"],
        actionText: "Report Speech",
        tip: "PRO TIP: 'Present' becomes 'Past'! If someone said 'I am here', you report that they 'were there'.",
      );
    }
    if (type == GameSubtype.tenseMastery) {
      return const GameBriefing(
        title: "Tense Mastery",
        icon: Icons.history_toggle_off_rounded,
        objective: "MAP THE TIMELINE: Place the action in its correct temporal state. Perfect your use of Past, Present, and Future.",
        rules: ["Check for time markers", "Identify frequency", "3 Hearts per mission"],
        actionText: "Master Tenses",
        tip: "PRO TIP: Look for 'Signal Words'! 'Since' often needs Perfect tense, while 'Usually' needs Simple Present.",
      );
    }

    // --- 3. READING (Comprehension & Speed) ---
    if (type == GameSubtype.skimmingScanning) {
      return const GameBriefing(
        title: "Skim & Scan",
        icon: Icons.search_rounded,
        objective: "FIND DATA FAST: Scan the text to locate specific facts or skim for the overall main idea.",
        rules: ["Speed is crucial", "Ignore filler words", "Locate specific data points"],
        actionText: "Start Scanning",
        tip: "PRO TIP: Use your eyes like a radar! Don't read every word; hunt for capital letters or numbers first.",
      );
    }
    if (type == GameSubtype.clozeTest) {
      return const GameBriefing(
        title: "Context Mastery",
        icon: Icons.format_color_text_rounded,
        objective: "FILL THE GAPS: Restore the passage by choosing the most contextually appropriate words.",
        rules: ["Read before and after", "Check for collocations", "Ensure logical flow"],
        actionText: "Fill Gaps",
        tip: "PRO TIP: Read the whole sentence first! The word after the gap often dictates what part of speech you need.",
      );
    }

    // --- 4. VOCABULARY (Lexical Expansion) ---
    if (type == GameSubtype.flashcards) {
      return const GameBriefing(
        title: "Flashcard Mastery",
        icon: Icons.style_rounded,
        objective: "Test your memory! Recall meanings and master the word list.",
        rules: [
          "Tap the card to see the meaning",
          "Swipe Right if you know it well",
          "Swipe Left to review it again"
        ],
        actionText: "Ready to Master?",
        tip: "Reviewing words you struggle with is the fastest way to learn! 🚀",
      );
    }
    if (type == GameSubtype.topicVocab) {
      return const GameBriefing(
        title: "Topic Nexus",
        icon: Icons.category_rounded,
        objective: "CATEGORIZE & SORT: Swipe words into their matching thematic bins.",
        rules: [
          "Swipe to categorize",
          "Flick words into bins",
          "Sort the whole batch"
        ],
        actionText: "Ready to Sort?",
        tip: "PRO TIP: Categorizing words helps you remember them 2x faster! 🚀",
      );
    }
    if (type == GameSubtype.prefixSuffix) {
      return const GameBriefing(
        title: "Botanical Roots",
        icon: Icons.spa_rounded,
        objective: "GRAFT & GROW: Master English morphology by attaching prefixes and suffixes to root words.",
        rules: ["Analyze the root", "Select the affix", "Grow the tree", "3 Hearts per mission"],
        actionText: "Start Grafting",
        tip: "PRO TIP: Latin and Greek roots are the DNA of English. One root unlocks dozens of words! 🌱",
      );
    }
    if (type == GameSubtype.wordFormation) {
      return const GameBriefing(
        title: "Morpheme Mixer",
        icon: Icons.science_rounded,
        objective: "SYNTHESIZE & FORM: Slide the correct suffix into the core to transform the word.",
        rules: [
          "Analyze the root word",
          "Tap or slide a suffix",
          "Form the target word"
        ],
        actionText: "Ready to Mix?",
        tip: "PRO TIP: Suffixes instantly change words from verbs to nouns or adjectives! 🧪🚀",
      );
    }
    if (type == GameSubtype.synonymSearch) {
      return const GameBriefing(
        title: "Neural Lens",
        icon: Icons.center_focus_strong_rounded,
        objective: "SCAN & SYNC: Find the semantic twin using the high-frequency Neural Lens.",
        rules: ["Focus the Lens", "Find the match", "Filter the noise", "3 Hearts per mission"],
        actionText: "Initialize Scan",
        tip: "PRO TIP: Use the lens to focus on core meanings while filtering out distractions. 🔍",
      );
    }
    if (type == GameSubtype.antonymSearch) {
      return const GameBriefing(
        title: "Bipolar Mirror",
        icon: Icons.exposure_rounded,
        objective: "REFLECT & INVERT: Peer through the Bipolar Mirror and identify the exact linguistic opposite.",
        rules: ["Analyze reflection", "Pick inverse signal", "Spot false matches", "3 Hearts per mission"],
        actionText: "Enter Mirror Chamber",
        tip: "PRO TIP: True opposites are like mirror images—perfectly symmetrical but completely inverted! 🪞",
      );
    }

    if (type == GameSubtype.academicWord) {
      return const GameBriefing(
        title: "Academic Radar",
        icon: Icons.radar_rounded,
        objective: "SCAN & LOCATE: Use the Academic Radar to highlight and isolate scholarly terminology within the passage.",
        rules: ["Analyze the text", "Isolate the word", "3 Hearts per mission"],
        actionText: "Start Radar Scan",
        tip: "PRO TIP: Scholarly words are often precise and formal. Look for complex Latin or Greek roots! 🛰️",
      );
    }
    if (type == GameSubtype.contextClues) {
      return const GameBriefing(
        title: "Ink Analysis",
        icon: Icons.brush_rounded,
        objective: "RUB & REVEAL: Use the digital brush to rub away the masking ink and reveal hidden contextual clues.",
        rules: ["Rub to reveal", "Analyze surrounding words", "3 Hearts per mission"],
        actionText: "Begin Analysis",
        tip: "PRO TIP: Don't rub everything! Reveal just enough to understand the context and save your energy. 🖌️",
      );
    }
    if (type == GameSubtype.collocations) {
      return const GameBriefing(
        title: "Chain Linker",
        icon: Icons.link_rounded,
        objective: "LINK & SYNC: Create semantic chains by connecting anchor words to their natural linguistic partners.",
        rules: ["Find the partner", "Secure the link", "3 Hearts per mission"],
        actionText: "Secure Links",
        tip: "PRO TIP: Collocations are words that 'just sound right' together. Trust your ear! 🔗",
      );
    }
    if (type == GameSubtype.phrasalVerbs) {
      return const GameBriefing(
        title: "Verb Magnet",
        icon: Icons.flash_on_rounded,
        objective: "ATTRACT & BIND: Use the Verb Magnet to attract floating particles and synthesize complete phrasal verbs.",
        rules: ["Select the particle", "Complete the verb", "3 Hearts per mission"],
        actionText: "Activate Magnet",
        tip: "PRO TIP: Small changes in the particle (up vs. down) completely change the verb's meaning! 🧲",
      );
    }
    if (type == GameSubtype.idioms) {
      return const GameBriefing(
        title: "Idiom Echo",
        icon: Icons.record_voice_over_rounded,
        objective: "DECODE & ECHO: Analyze the visual emoji clues and echo back the true figurative meaning of the idiom.",
        rules: ["Decode the visual", "Avoid literal traps", "3 Hearts per mission"],
        actionText: "Echo Meaning",
        tip: "PRO TIP: Idioms are the 'code' of English. Master them to sound exactly like a native! 🗣️",
      );
    }
    if (type == GameSubtype.contextualUsage) {
      return const GameBriefing(
        title: "Usage Expert",
        icon: Icons.fact_check_rounded,
        objective: "SLOT & VALIDATE: Evaluate four different scenarios and slot the target word into the only grammatically correct sentence.",
        rules: ["Analyze all slots", "Identify errors", "3 Hearts per mission"],
        actionText: "Validate Usage",
        tip: "PRO TIP: Check the part of speech! A word might be a noun in one sentence and an incorrect verb in another. 📋",
      );
    }

    // --- CATEGORY FALLBACKS ---
    final category = type.category;
    switch (category) {
      case QuestType.speaking:
        return const GameBriefing(
          title: "Voice Mastery",
          icon: Icons.record_voice_over_rounded,
          objective: "TAP MIC & SPEAK: Express the phrase clearly. Your buddy is listening for perfect pitch and rhythm!",
          rules: ["Find a quiet place", "Speak at a natural pace", "Match the example"],
          actionText: "Record Now",
          tip: "PRO TIP: Record yourself! Comparing your pitch to the model helps master the natural rhythm.",
        );
      case QuestType.listening:
        return const GameBriefing(
          title: "Audio Analysis",
          icon: Icons.headphones_rounded,
          objective: "LISTEN & CHOOSE: Analyze the audio feed and identify the hidden linguistic patterns.",
          rules: ["Use headphones", "Focus on intonation", "Identify keywords"],
          actionText: "Initialize Feed",
          tip: "PRO TIP: Close your eyes! Focusing on pure sound helps catch subtle phoneme changes.",
        );
      case QuestType.reading:
        return const GameBriefing(
          title: "Text Comprehension",
          icon: Icons.menu_book_rounded,
          objective: "READ & EXTRACT: Analyze the passage. Comprehension and detail-gathering are your goals.",
          rules: ["Read the whole text", "Identify main ideas", "Check details carefully"],
          actionText: "Analyze Text",
          tip: "PRO TIP: Scan for keywords first! Don't get stuck on one word; focus on the overall message.",
        );
      case QuestType.writing:
        return const GameBriefing(
          title: "Sentence Construction",
          icon: Icons.edit_note_rounded,
          objective: "DRAG & BUILD: Organize the fragments into a syntactically perfect sentence.",
          rules: ["Check your spelling", "Check punctuation", "Structure logically"],
          actionText: "Build Sentence",
          tip: "PRO TIP: Start with the verb! Finding the action helps the rest of the sentence fall into place.",
        );
      case QuestType.grammar:
        return const GameBriefing(
          title: "Structural Logic",
          icon: Icons.architecture_rounded,
          objective: "RESOLVE PATTERNS: Fix the underlying structural errors to create a perfect linguistic system.",
          rules: ["Identify errors", "Choose the correction", "Master the rules"],
          actionText: "Fix Structure",
          tip: "PRO TIP: Read the sentence out loud in your head! Often, you can 'hear' if a rule is being broken.",
        );
      case QuestType.vocabulary:
        return const GameBriefing(
          title: "Word Power",
          icon: Icons.auto_awesome_rounded,
          objective: "IDENTIFY & LEARN: Expand your lexicon by matching words to their contextual definitions.",
          rules: ["Memorize the meanings", "Understand context", "Build word bank"],
          actionText: "Acquire Lexicon",
          tip: "PRO TIP: Visual associations help! Try to link the word to a picture in your mind.",
        );
      case QuestType.accent:
        return const GameBriefing(
          title: "Phonetic Drill",
          icon: Icons.music_note_rounded,
          objective: "MIMIC & MATCH: Focus on the rhythm and pitch. Sound exactly like a native speaker.",
          rules: ["Listen to intonation", "Mimic the rhythm", "Repeat until perfect"],
          actionText: "Start Drill",
          tip: "PRO TIP: Over-enunciate! Emphasizing the vowels helps clear up minimal pair confusion.",
        );
      case QuestType.roleplay:
        return const GameBriefing(
          title: "Social Simulation",
          icon: Icons.groups_rounded,
          objective: "CHOOSE WISELY: Navigate social scenarios by selecting the most appropriate responses.",
          rules: ["Stay in character", "Think of the goal", "React naturally"],
          actionText: "Enter Scenario",
          tip: "PRO TIP: Be expressive! The tone is just as important as the words in social interactions.",
        );
      default:
        return getDefaultBriefing(fallbackTitle ?? "Quest");
    }
  }

  static GameBriefing getDefaultBriefing(String title) {
    return GameBriefing(
      title: title,
      icon: Icons.extension_rounded,
      objective: "Complete the challenge to earn rewards and master your skills!",
      rules: ["3 Hearts per mission", "2 Strikes (Mistakes Re-queued)", "Achieve 100% Mastery"],
      actionText: "Start Quest",
      tip: "PRO TIP: Stay focused and listen to your buddy! They have the answers you need.",
    );
  }
}

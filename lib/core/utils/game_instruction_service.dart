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
    if (type == GameSubtype.findWordMeaning) {
      return const GameBriefing(
        title: "Lexical Linker",
        icon: Icons.menu_book_rounded,
        objective: "Locate and match word definitions within the context of the text.",
        rules: ["Analyze the context", "Match word to meaning", "Build vocabulary"],
        actionText: "Link Words",
        tip: "Context is your best friend! The surrounding words often reveal the hidden meaning. 📚",
      );
    }
    if (type == GameSubtype.guessTitle) {
      return const GameBriefing(
        title: "Title Tactician",
        icon: Icons.title_rounded,
        objective: "Deduce the most appropriate title for the given passage.",
        rules: ["Identify main theme", "Check all options", "Summarize the core"],
        actionText: "Deduce Title",
        tip: "A great title captures the 'big picture'. Look for the most repeated themes! 🏷️",
      );
    }
    if (type == GameSubtype.paragraphSummary) {
      return const GameBriefing(
        title: "Summary Sieve",
        icon: Icons.short_text_rounded,
        objective: "Select the sentence that best captures the essence of the paragraph.",
        rules: ["Filter out details", "Find the main point", "Stay objective"],
        actionText: "Summarize Now",
        tip: "Avoid sentences that only mention one small detail; look for the overarching idea! 📋",
      );
    }
    if (type == GameSubtype.readAndAnswer) {
      return const GameBriefing(
        title: "Insight Analyst",
        icon: Icons.fact_check_rounded,
        objective: "Answer specific comprehension questions about the text.",
        rules: ["Refer back to text", "Verify every detail", "Think critically"],
        actionText: "Analyze Text",
        tip: "Don't guess! The answer is ALWAYS in the text—you just have to find it. 🕵️",
      );
    }
    if (type == GameSubtype.readAndMatch) {
      return const GameBriefing(
        title: "Semantic Bridge",
        icon: Icons.bolt_rounded,
        objective: "Connect related concepts and facts from the reading passage.",
        rules: ["Bridge the gaps", "Use lasers to link", "Confirm relationships"],
        actionText: "Bridge Gaps",
        tip: "Think about how concepts relate—is it cause and effect, or part and whole? 🌉",
      );
    }
    if (type == GameSubtype.readingConclusion) {
      return const GameBriefing(
        title: "Logical Finisher",
        icon: Icons.last_page_rounded,
        objective: "Predict the logical conclusion or next step based on the text.",
        rules: ["Follow the logic", "Predict outcome", "Verify with evidence"],
        actionText: "Predict Final",
        tip: "Follow the clues the author left! Where does the logic naturally lead? 🏁",
      );
    }
    if (type == GameSubtype.readingInference) {
      return const GameBriefing(
        title: "Subtext Sleuth",
        icon: Icons.biotech_rounded,
        objective: "Identify what is implied but not explicitly stated.",
        rules: ["Read between lines", "Detect subtext", "Infer correctly"],
        actionText: "Deduce Subtext",
        tip: "The author's tone and choice of words often hide a deeper meaning. 🔍",
      );
    }
    if (type == GameSubtype.readingSpeedCheck) {
      return const GameBriefing(
        title: "Velocity Reader",
        icon: Icons.speed_rounded,
        objective: "Test your comprehension while reading at high velocity.",
        rules: ["Read fast", "Maintain accuracy", "Beat the timer"],
        actionText: "Race Timer",
        tip: "Don't subvocalize (read out loud in your head)! Let your eyes glide over the text. ⚡",
      );
    }
    if (type == GameSubtype.sentenceOrderReading) {
      return const GameBriefing(
        title: "Structure Architect",
        icon: Icons.architecture_rounded,
        objective: "Reorganize scrambled sentences to restore logical flow.",
        rules: ["Find the logic", "Check transitions", "Rebuild the system"],
        actionText: "Rebuild Flow",
        tip: "Look for transition words like 'however', 'moreover', and 'finally'. 🏗️",
      );
    }
    if (type == GameSubtype.trueFalseReading) {
      return const GameBriefing(
        title: "Truth Verifier",
        icon: Icons.verified_user_rounded,
        objective: "Determine the factual accuracy of statements against the text.",
        rules: ["Locate the evidence", "Check for nuances", "Validate truth"],
        actionText: "Verify Truth",
        tip: "Be careful of 'absolute' words like 'always', 'never', or 'only'! ⚖️",
      );
    }

    // --- 4. VOCABULARY (Lexical Expansion) ---
    if (type == GameSubtype.flashcards) {
      return const GameBriefing(
        title: "Flashcards",
        icon: Icons.style_rounded,
        objective: "Master words by swiping through the deck.",
        rules: ["Tap to flip", "Swipe Right = Known", "Swipe Left = Review"],
        actionText: "Master Now",
        tip: "Speed isn't the goal—mastery is! 🚀",
      );
    }
    if (type == GameSubtype.topicVocab) {
      return const GameBriefing(
        title: "Topic Nexus",
        icon: Icons.category_rounded,
        objective: "Sort words into their thematic bins.",
        rules: ["Analyze the word", "Swipe into matching bin", "Clear the queue"],
        actionText: "Start Sorting",
        tip: "Sorting by topic builds semantic memory 2x faster! 🧠",
      );
    }
    if (type == GameSubtype.prefixSuffix) {
      return const GameBriefing(
        title: "Word Roots",
        icon: Icons.spa_rounded,
        objective: "Build words by attaching affixes to roots.",
        rules: ["Analyze root", "Attach correct affix", "3 Hearts"],
        actionText: "Build Words",
        tip: "Roots are the DNA of English! 🌱",
      );
    }
    if (type == GameSubtype.wordFormation) {
      return const GameBriefing(
        title: "Morpheme Mixer",
        icon: Icons.science_rounded,
        objective: "Slide the correct suffix into the core to transform the word.",
        rules: ["Analyze root", "Slide suffix", "Form word"],
        actionText: "Ready to Mix?",
        tip: "Suffixes change words from verbs to nouns or adjectives! 🧪🚀",
      );
    }
    if (type == GameSubtype.synonymSearch) {
      return const GameBriefing(
        title: "Word Warp",
        icon: Icons.cyclone,
        objective: "Warp the synonym into the central gate.",
        rules: ["Find the twin", "Drag into the Warp Gate", "Avoid distractions"],
        actionText: "Start Warp",
        tip: "Focus on the core meaning, filter the noise! 🌀",
      );
    }
    if (type == GameSubtype.antonymSearch) {
      return const GameBriefing(
        title: "Polarity Pull",
        icon: Icons.electrical_services_rounded,
        objective: "Drag the antonym into the opposite pole.",
        rules: ["Find the Antonym", "Opposites Attract", "3 Hearts left"],
        actionText: "Start Pull",
        tip: "Opposite meaning = Opposite pole! ⚡🧲",
      );
    }

    if (type == GameSubtype.academicWord) {
      return const GameBriefing(
        title: "Thesis Thrust",
        icon: Icons.auto_stories_rounded,
        objective: "Identify academic words and thrust them into the thesis.",
        rules: ["Analyze context", "Thrust the correct shard", "3 Hearts"],
        actionText: "Initiate Thrust",
        tip: "Academic words are precise—look at the logic! 📜✒️",
      );
    }
    if (type == GameSubtype.contextClues) {
      return const GameBriefing(
        title: "Detective Lens",
        icon: Icons.search_rounded,
        objective: "Use the Lens to reveal hidden clues and identify the word.",
        rules: ["Drag to reveal clues", "Analyze context", "3 Hearts"],
        actionText: "Start Scan",
        tip: "Clues often hide right next to the redacted word! 🔍",
      );
    }
    if (type == GameSubtype.collocations) {
      return const GameBriefing(
        title: "Pair Pop",
        icon: Icons.bubble_chart_rounded,
        objective: "Find the word that naturally pairs with the top anchor.",
        rules: ["Analyze anchor", "Select partner bubble", "Fuse the pair"],
        actionText: "Initiate Fusion",
        tip: "Collocations are words that naturally go together! 🫧⚡",
      );
    }
    if (type == GameSubtype.phrasalVerbs) {
      return const GameBriefing(
        title: "Verb Vault",
        icon: Icons.vpn_key_rounded,
        objective: "Match the correct particle to the verb to unlock the vault.",
        rules: ["Read Definition", "Select Particle", "Crack Vault"],
        actionText: "Start Hack",
        tip: "Particles change everything! 'Turn UP' is not 'Turn DOWN'. ⚙️",
      );
    }
    if (type == GameSubtype.idioms) {
      return const GameBriefing(
        title: "Emojify",
        icon: Icons.forum_rounded,
        objective: "Decode emoji transmissions into idioms.",
        rules: ["Interpret emojis", "Select matching idiom", "3 Hearts"],
        actionText: "Send Message",
        tip: "Idioms are secret codes for culture! 💬",
      );
    }
    if (type == GameSubtype.contextualUsage) {
      return const GameBriefing(
        title: "Usage Unfold",
        icon: Icons.auto_stories_rounded,
        objective: "Analyze context and unfold the perfect word.",
        rules: ["Evaluate context", "Unfold the correct fit", "3 Hearts"],
        actionText: "Unfold Truth",
        tip: "Nuance is key! Choose the word that belongs. 📖✨",
      );
    }

    // --- 5. LISTENING (Auditory Precision) ---
    if (type == GameSubtype.ambientId) {
      return const GameBriefing(
        title: "Spatial Anchor",
        icon: Icons.radar_rounded,
        objective: "Identify the environment by analyzing spatial audio cues.",
        rules: ["Listen to the background", "Scan the radar", "Anchor the location"],
        actionText: "Anchor Location",
        tip: "Focus on the 'texture' of the sound—echoes and hums tell a story! 📻",
      );
    }
    if (type == GameSubtype.audioFillBlanks) {
      return const GameBriefing(
        title: "Ink Decoder",
        icon: Icons.water_drop_rounded,
        objective: "Transcribe missing words from the audio feed.",
        rules: ["Smear the ink to see", "Listen for the gap", "Type exactly what you hear"],
        actionText: "Start Decoding",
        tip: "Typing what you hear builds a strong brain-ear connection! ✍️👂",
      );
    }
    if (type == GameSubtype.audioMultipleChoice) {
      return const GameBriefing(
        title: "Sonic Satellites",
        icon: Icons.track_changes_rounded,
        objective: "Filter the audio signal and select the correct interpretation.",
        rules: ["Spin satellites to lock", "Listen to the central core", "Choose the data match"],
        actionText: "Lock Signal",
        tip: "Filter out the noise—focus only on the speaker's core message! 🛰️",
      );
    }
    if (type == GameSubtype.audioSentenceOrder) {
      return const GameBriefing(
        title: "Timeline Scrubber",
        icon: Icons.waves_rounded,
        objective: "Reconstruct the sequence of spoken segments.",
        rules: ["Listen to the full stream", "Snap segments to timeline", "Calibrate the signal"],
        actionText: "Calibrate Signal",
        tip: "Logical flow is everything! Look for connectors like 'then' or 'so'. 🌊",
      );
    }
    if (type == GameSubtype.audioTrueFalse) {
      return const GameBriefing(
        title: "Signal Validator",
        icon: Icons.verified_user_rounded,
        objective: "Verify the accuracy of a statement based on the audio feed.",
        rules: ["Analyze the claim", "Compare to audio data", "Validate or Nullify"],
        actionText: "Begin Validation",
        tip: "Don't be fooled by similar words—the meaning must match exactly! ✅",
      );
    }
    if (type == GameSubtype.detailSpotlight) {
      return const GameBriefing(
        title: "Spotlight Search",
        icon: Icons.flashlight_on_rounded,
        objective: "Locate specific details hidden within a complex audio passage.",
        rules: ["Scan the shadows", "Listen for specific evidence", "Locate the target"],
        actionText: "Start Search",
        tip: "Details are like gold—listen for numbers, names, and dates! 🔦",
      );
    }
    if (type == GameSubtype.emotionRecognition) {
      return const GameBriefing(
        title: "Sentiment Prober",
        icon: Icons.psychology_rounded,
        objective: "Decode the speaker's emotional state through tone and pitch.",
        rules: ["Navigate the neural core", "Analyze pitch & rhythm", "Match the sentiment"],
        actionText: "Probe Sentiment",
        tip: "It's not what they say, it's how they say it! Listen for the 'song'. 🎭",
      );
    }
    if (type == GameSubtype.fastSpeechDecoder) {
      return const GameBriefing(
        title: "Nuance Calibrator",
        icon: Icons.settings_input_composite_rounded,
        objective: "Decode rapid-fire speech by calibrating playback speed.",
        rules: ["Rotate gears to change speed", "Listen for clarity", "Unfold the meaning"],
        actionText: "Calibrate Gears",
        tip: "Slow it down first, then try at full speed once you've got it! ⚙️",
      );
    }
    if (type == GameSubtype.listeningInference) {
      return const GameBriefing(
        title: "Inference Lens",
        icon: Icons.biotech_rounded,
        objective: "Understand what was implied, not just what was said.",
        rules: ["Read between the waves", "Deduce the subtext", "Choose logical conclusion"],
        actionText: "Focus Lens",
        tip: "The speaker often hides their true meaning behind their tone. 🔍",
      );
    }
    if (type == GameSubtype.soundImageMatch) {
      return const GameBriefing(
        title: "Thematic Linker",
        icon: Icons.category_rounded,
        objective: "Link auditory data to its visual/categorical equivalent.",
        rules: ["Scan encrypted tiles", "Match sound to symbol", "Confirm the thematic link"],
        actionText: "Confirm Link",
        tip: "Visualizing the sound helps solidify it in your long-term memory! 🖼️",
      );
    }

    // --- 2. SPEAKING (Oral Proficiency) ---
    if (type == GameSubtype.repeatSentence) {
      return const GameBriefing(
        title: "Echo Master",
        icon: Icons.graphic_eq_rounded,
        objective: "Accurately repeat the given sentence while maintaining rhythm.",
        rules: ["Hold the mic to record", "Trace the sound wave", "Master the cadence"],
        actionText: "Start Echo",
        tip: "Rhythm is as important as pronunciation! Try to match the 'beat' of the speaker. 🥁",
      );
    }
    if (type == GameSubtype.pronunciationFocus) {
      return const GameBriefing(
        title: "Phonetic Precision",
        icon: Icons.record_voice_over_rounded,
        objective: "Perfect your pronunciation of challenging phonemes and clusters.",
        rules: ["Focus on mouth position", "Repeat the target sound", "Analyze your waves"],
        actionText: "Practice Sound",
        tip: "Watch the mouth position in your mind! Small changes in tongue placement make a huge difference. 👄",
      );
    }
    if (type == GameSubtype.dailyExpression) {
      return const GameBriefing(
        title: "Social Fluent",
        icon: Icons.chat_bubble_rounded,
        objective: "Master common daily phrases by matching native intonation.",
        rules: ["Listen to the model", "Record your voice", "Match the social tone"],
        actionText: "Speak Now",
        tip: "Imagine you're talking to a friend! Social context changes how we stress certain words. 🤝",
      );
    }
    if (type == GameSubtype.dialogueRoleplay) {
      return const GameBriefing(
        title: "Scene Architect",
        icon: Icons.theater_comedy_rounded,
        objective: "Participate in a simulated conversation by speaking your lines.",
        rules: ["Follow the script", "Speak with emotion", "Keep the flow going"],
        actionText: "Enter Scene",
        tip: "Don't just read—ACT! Expressive speaking helps with long-term memory. 🎭",
      );
    }
    if (type == GameSubtype.sceneDescriptionSpeaking) {
      return const GameBriefing(
        title: "Visual Narrator",
        icon: Icons.image_search_rounded,
        objective: "Describe the visual scene using appropriate vocabulary and structure.",
        rules: ["Analyze the image", "Speak descriptive details", "Build a narrative"],
        actionText: "Describe Scene",
        tip: "Start with the biggest objects and then focus on the small details! 🖼️",
      );
    }
    if (type == GameSubtype.situationSpeaking) {
      return const GameBriefing(
        title: "Crisis Communicator",
        icon: Icons.emergency_rounded,
        objective: "Respond to a specific real-world situation using spoken English.",
        rules: ["Understand the context", "Speak your solution", "Be clear and direct"],
        actionText: "Resolve Now",
        tip: "In real situations, clarity is key! Focus on getting your main point across quickly. 🆘",
      );
    }
    if (type == GameSubtype.speakMissingWord) {
      return const GameBriefing(
        title: "Vocal Decoder",
        icon: Icons.find_in_page_rounded,
        objective: "Complete the sentence orally by speaking the missing term.",
        rules: ["Identify the gap", "Speak the word clearly", "Verify the context"],
        actionText: "Speak Word",
        tip: "Say the whole sentence in your head first to find the missing piece. 🧩",
      );
    }
    if (type == GameSubtype.speakOpposite) {
      return const GameBriefing(
        title: "Antonym Orator",
        icon: Icons.compare_arrows_rounded,
        objective: "Orally state the opposite of the given word or phrase.",
        rules: ["Analyze the target", "Speak the antonym", "Maintain accuracy"],
        actionText: "Vocalize Opposite",
        tip: "Think of the 'flip side'! If it's hot, the antonym is cold. 🔄",
      );
    }
    if (type == GameSubtype.speakSynonym) {
      return const GameBriefing(
        title: "Lexical Speaker",
        icon: Icons.library_books_rounded,
        objective: "Provide a spoken synonym for the target word.",
        rules: ["Find similar meaning", "Speak the synonym", "Expand your voice"],
        actionText: "Vocalize Synonym",
        tip: "There's always more than one way to say something! Expand your word bank. 📖",
      );
    }
    if (type == GameSubtype.yesNoSpeaking) {
      return const GameBriefing(
        title: "Voice Validator",
        icon: Icons.fact_check_rounded,
        objective: "Answer factual questions with a spoken 'Yes' or 'No'.",
        rules: ["Listen to the question", "Speak your confirmation", "Be quick and clear"],
        actionText: "Validate Voice",
        tip: "Confidence is key! Speak your answer firmly. ⚖️",
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

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
    if (type == null) {
      if (fallbackTitle != null) {
        final kidsBriefing = _getKidsBriefing(fallbackTitle);
        if (kidsBriefing != null) return kidsBriefing;
      }
      return getDefaultBriefing(fallbackTitle ?? "Quest");
    }

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
    if (type == GameSubtype.grammarQuest) {
      return const GameBriefing(
        title: "Grammar Core",
        icon: Icons.gavel_rounded,
        objective: "RESOLVE PATTERNS: Fix the underlying structural errors to create a perfect linguistic system.",
        rules: ["Identify errors", "Choose the correction", "Master the rules"],
        actionText: "Fix Structure",
        tip: "PRO TIP: Read the sentence out loud in your head! Often, you can 'hear' if a rule is being broken.",
      );
    }
    if (type == GameSubtype.sentenceCorrection) {
      return const GameBriefing(
        title: "Error Auditor",
        icon: Icons.spellcheck_rounded,
        objective: "AUDIT SENTENCES: Scan the text for grammatical anomalies and replace them with correct forms.",
        rules: ["Find the glitch", "Apply the fix", "Verify the meaning"],
        actionText: "Audit Text",
        tip: "PRO TIP: Focus on subject-verb agreement first—it's the most common source of errors!",
      );
    }
    if (type == GameSubtype.wordReorder) {
      return const GameBriefing(
        title: "Syntax Reorder",
        icon: Icons.reorder_rounded,
        objective: "REORDER WORDS: Arrange scrambled segments into a grammatically sound sequence.",
        rules: ["Identify the subject", "Find the main verb", "Arrange complements"],
        actionText: "Align Syntax",
        tip: "PRO TIP: Adjectives usually come before nouns, and adverbs often follow verbs. Follow the logic!",
      );
    }
    if (type == GameSubtype.partsOfSpeech) {
      return const GameBriefing(
        title: "Lexical Anatomy",
        icon: Icons.category_rounded,
        objective: "IDENTIFY FUNCTIONS: Label words based on their role in the sentence (Noun, Verb, Adjective, etc.).",
        rules: ["Analyze word function", "Categorize correctly", "Build structure"],
        actionText: "Identify Role",
        tip: "PRO TIP: If it's an action, it's a verb. If it's a person/place/thing, it's a noun. Simple!",
      );
    }
    if (type == GameSubtype.subjectVerbAgreement) {
      return const GameBriefing(
        title: "Agreement Sync",
        icon: Icons.sync_rounded,
        objective: "SYNC SUBJECTS: Ensure the verb matches the subject in number and person.",
        rules: ["Identify the subject", "Check singular vs plural", "Match the verb form"],
        actionText: "Sync Agreement",
        tip: "PRO TIP: Watch out for 'distractors'—prepositional phrases that sit between the subject and the verb!",
      );
    }
    if (type == GameSubtype.clauseConnector) {
      return const GameBriefing(
        title: "Clause Linker",
        icon: Icons.link_rounded,
        objective: "CONNECT IDEAS: Use appropriate conjunctions to link independent and dependent clauses.",
        rules: ["Analyze relationship", "Choose the connector", "Ensure logical flow"],
        actionText: "Link Clauses",
        tip: "PRO TIP: Use 'Because' for reasons, 'Although' for contrast, and 'While' for simultaneous actions.",
      );
    }
    if (type == GameSubtype.questionFormatter) {
      return const GameBriefing(
        title: "Inquiry Logic",
        icon: Icons.help_outline_rounded,
        objective: "FORMAT QUESTIONS: Transform statements into accurate interrogative forms.",
        rules: ["Invert subject/verb", "Add auxiliary verbs", "Match the tense"],
        actionText: "Format Inquiry",
        tip: "PRO TIP: Remember the 'Qu-A-S-V' rule: Question word, Auxiliary, Subject, Verb!",
      );
    }
    if (type == GameSubtype.articleInsertion) {
      return const GameBriefing(
        title: "Article Anchor",
        icon: Icons.anchor_rounded,
        objective: "ANCHOR NOUNS: Insert the correct articles (a, an, the) or determine if none is needed.",
        rules: ["Check for specificity", "Identify first sounds", "Countable vs Uncountable"],
        actionText: "Insert Articles",
        tip: "PRO TIP: Use 'The' for specific things we both know about, and 'A/An' for anything general.",
      );
    }
    if (type == GameSubtype.modifierPlacement) {
      return const GameBriefing(
        title: "Modifier Map",
        icon: Icons.location_on_rounded,
        objective: "PLACE MODIFIERS: Ensure adjectives and adverbs are placed correctly to avoid ambiguity.",
        rules: ["Avoid dangling modifiers", "Link to target word", "Clear the meaning"],
        actionText: "Map Modifiers",
        tip: "PRO TIP: Place the modifier as close as possible to the word it's describing!",
      );
    }
    if (type == GameSubtype.modalsSelection) {
      return const GameBriefing(
        title: "Modal Matrix",
        icon: Icons.grid_view_rounded,
        objective: "CHOOSE MODALS: Select the auxiliary verb that expresses the right degree of possibility or necessity.",
        rules: ["Analyze the mood", "Check for permission/duty", "Match the strength"],
        actionText: "Select Modal",
        tip: "PRO TIP: 'Must' is for strong obligation, while 'Should' is for friendly advice.",
      );
    }
    if (type == GameSubtype.prepositionChoice) {
      return const GameBriefing(
        title: "Position Pro",
        icon: Icons.directions_rounded,
        objective: "PICK PREPOSITIONS: Master the small words that define time, space, and relationship.",
        rules: ["Analyze spatial data", "Check time markers", "Verify collocations"],
        actionText: "Choose Position",
        tip: "PRO TIP: Use 'In' for large spaces, 'On' for surfaces, and 'At' for specific points.",
      );
    }
    if (type == GameSubtype.pronounResolution) {
      return const GameBriefing(
        title: "Pronoun Pivot",
        icon: Icons.people_rounded,
        objective: "RESOLVE PRONOUNS: Ensure every pronoun has a clear and logical antecedent.",
        rules: ["Find the antecedent", "Match gender & number", "Avoid ambiguity"],
        actionText: "Resolve Pivot",
        tip: "PRO TIP: If there are two people, 'he' can be confusing. Use their names or clear markers!",
      );
    }
    if (type == GameSubtype.punctuationMastery) {
      return const GameBriefing(
        title: "Symbol Scribe",
        icon: Icons.short_text_rounded,
        objective: "MASTER SYMBOLS: Place commas, semi-colons, and periods to structure the text perfectly.",
        rules: ["Separate list items", "Connect related ideas", "Define boundaries"],
        actionText: "Scribe Symbols",
        tip: "PRO TIP: Use a comma before 'and' only in long lists or between independent clauses!",
      );
    }
    if (type == GameSubtype.relativeClauses) {
      return const GameBriefing(
        title: "Relative Rail",
        icon: Icons.linear_scale_rounded,
        objective: "EXTEND MEANING: Use relative pronouns (who, which, that) to add essential details to nouns.",
        rules: ["Identify the noun", "Choose the pronoun", "Link the detail"],
        actionText: "Link Relative",
        tip: "PRO TIP: Use 'Who' for people and 'Which' or 'That' for things and animals.",
      );
    }
    if (type == GameSubtype.conditionals) {
      return const GameBriefing(
        title: "If-Logic",
        icon: Icons.alt_route_rounded,
        objective: "HYPOTHESIZE: Master 'If' statements across zero, first, second, and third conditionals.",
        rules: ["Identify the condition", "Match the tense sequence", "Predict the result"],
        actionText: "Solve Logic",
        tip: "PRO TIP: In 'Second Conditional' (imaginary), use 'If I WERE' even for singular subjects!",
      );
    }
    if (type == GameSubtype.conjunctions) {
      return const GameBriefing(
        title: "Logic Junction",
        icon: Icons.join_inner_rounded,
        objective: "JOIN IDEAS: Use FANBOYS and subordinating conjunctions to build complex thoughts.",
        rules: ["Compare/Contrast ideas", "Identify cause/effect", "Connect the flow"],
        actionText: "Join Junction",
        tip: "PRO TIP: Remember 'FANBOYS': For, And, Nor, But, Or, Yet, So!",
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

    // --- WRITING (Composition & Flow) ---
    if (type == GameSubtype.sentenceBuilder) {
      return const GameBriefing(
        title: "Sentence Architect",
        icon: Icons.architecture_rounded,
        objective: "CONSTRUCT SYNTAX: Build a grammatically sound sentence from isolated fragments.",
        rules: ["Start with the Subject", "Identify the Verb", "Check the ending"],
        actionText: "Build Sentence",
        tip: "PRO TIP: Start with the 'Who' or 'What', then find the 'Action'!",
      );
    }
    if (type == GameSubtype.completeSentence) {
      return const GameBriefing(
        title: "Fragment Fixer",
        icon: Icons.healing_rounded,
        objective: "HEAL FRAGMENTS: Add the missing components to turn a fragment into a complete thought.",
        rules: ["Identify the missing part", "Maintain the tone", "Verify the logic"],
        actionText: "Fix Fragment",
        tip: "PRO TIP: A complete sentence needs a Subject and a Verb at the very least!",
      );
    }
    if (type == GameSubtype.describeSituationWriting) {
      return const GameBriefing(
        title: "Context Scribe",
        icon: Icons.description_rounded,
        objective: "DESCRIBE SCENES: Write a detailed description of the given situation or image.",
        rules: ["Use vivid adjectives", "Be specific & clear", "Show, don't just tell"],
        actionText: "Scribe Scene",
        tip: "PRO TIP: Use your senses! What would you see, hear, or feel in this situation?",
      );
    }
    if (type == GameSubtype.fixTheSentence) {
      return const GameBriefing(
        title: "Clarity Editor",
        icon: Icons.edit_rounded,
        objective: "REVISE TEXT: Identify and fix errors in grammar, punctuation, or style.",
        rules: ["Find the flaw", "Rewrite for clarity", "3 Hearts left"],
        actionText: "Apply Edit",
        tip: "PRO TIP: Read it out loud! If it sounds clumsy, it probably needs a revision.",
      );
    }
    if (type == GameSubtype.shortAnswerWriting) {
      return const GameBriefing(
        title: "Briefing Pro",
        icon: Icons.short_text_rounded,
        objective: "CONCISE REPLIES: Provide a direct and clear answer to the prompt in few words.",
        rules: ["Be direct", "Stay on topic", "Mind your grammar"],
        actionText: "Submit Answer",
        tip: "PRO TIP: Get straight to the point! You don't need long introductions for short answers.",
      );
    }
    if (type == GameSubtype.opinionWriting) {
      return const GameBriefing(
        title: "Vocal Pen",
        icon: Icons.rate_review_rounded,
        objective: "EXPRESS VIEWS: Write a short paragraph expressing your stance on a given topic.",
        rules: ["State your opinion", "Provide one reason", "Use persuasive words"],
        actionText: "Express View",
        tip: "PRO TIP: Use words like 'I believe', 'In my view', or 'Furthermore' to strengthen your case.",
      );
    }
    if (type == GameSubtype.dailyJournal) {
      return const GameBriefing(
        title: "Daily Chronicler",
        icon: Icons.auto_stories_rounded,
        objective: "LOG PROGRESS: Write a short entry about your day or a specific reflection.",
        rules: ["Be honest", "Use past tense", "Focus on reflections"],
        actionText: "Log Entry",
        tip: "PRO TIP: Use time markers like 'This morning', 'Later on', and 'Finally' to organize your day.",
      );
    }
    if (type == GameSubtype.summarizeStoryWriting) {
      return const GameBriefing(
        title: "Essence Extractor",
        icon: Icons.compress_rounded,
        objective: "SUMMARIZE: Condense a long story into its most important core points.",
        rules: ["Remove fluff", "Highlight key events", "Stay objective"],
        actionText: "Summarize Now",
        tip: "PRO TIP: Focus on the 'Who', 'What', 'Where', and 'Why' of the story.",
      );
    }
    if (type == GameSubtype.writingEmail) {
      return const GameBriefing(
        title: "Email Expert",
        icon: Icons.alternate_email_rounded,
        objective: "PROFESSIONAL MAIL: Compose an appropriate email based on the scenario.",
        rules: ["Use right greeting", "State the purpose", "Use formal closing"],
        actionText: "Send Mail",
        tip: "PRO TIP: Start with 'I am writing to...' to immediately clarify your purpose.",
      );
    }
    if (type == GameSubtype.correctionWriting) {
      return const GameBriefing(
        title: "Deep Editor",
        icon: Icons.fact_check_rounded,
        objective: "FINAL POLISH: Rewrite the entire paragraph to fix all underlying issues.",
        rules: ["Check all rules", "Improve flow", "Achieve 100% accuracy"],
        actionText: "Final Polish",
        tip: "PRO TIP: Look for repetitive words and replace them with synonyms to make it sound better!",
      );
    }
    if (type == GameSubtype.essayDrafting) {
      return const GameBriefing(
        title: "Essay Architect",
        icon: Icons.article_rounded,
        objective: "DRAFT STRUCTURE: Organize your thoughts into an introduction, body, and conclusion.",
        rules: ["Clear thesis", "Logical body", "Strong conclusion"],
        actionText: "Draft Essay",
        tip: "PRO TIP: Your conclusion should remind the reader of your main point without just repeating it.",
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

    // --- ACCENT (Native Resonance) ---
    if (type == GameSubtype.minimalPairs) {
      return const GameBriefing(
        title: "Minimal Distinctions",
        icon: Icons.compare_arrows_rounded,
        objective: "IDENTIFY SOUNDS: Distinguish between words that differ by only one sound (e.g., Ship vs Sheep).",
        rules: ["Listen to the vowel", "Compare lengths", "Identify the match"],
        actionText: "Match Sound",
        tip: "PRO TIP: Focus on the duration of the sound! Long vowels and short vowels change everything.",
      );
    }
    if (type == GameSubtype.intonationMimic) {
      return const GameBriefing(
        title: "Pitch Mimic",
        icon: Icons.waves_rounded,
        objective: "MIMIC PITCH: Match the rising and falling tones of the native speaker.",
        rules: ["Watch the waveform", "Match the peaks", "3 Hearts left"],
        actionText: "Mimic Now",
        tip: "PRO TIP: Questions usually end with a rising pitch, while statements fall. Follow the wave!",
      );
    }
    if (type == GameSubtype.syllableStress) {
      return const GameBriefing(
        title: "Stress Spotter",
        icon: Icons.priority_high_rounded,
        objective: "IDENTIFY STRESS: Pinpoint the emphasized syllable in a multi-syllabic word.",
        rules: ["Listen for loudness", "Check vowel clarity", "Mark the stress"],
        actionText: "Spot Stress",
        tip: "PRO TIP: Stressed syllables are louder, longer, and higher in pitch than others!",
      );
    }
    if (type == GameSubtype.wordLinking) {
      return const GameBriefing(
        title: "Fluid Flow",
        icon: Icons.link_rounded,
        objective: "LINK WORDS: Master how native speakers join words together (e.g., 'Not at all' sounds like 'Notatall').",
        rules: ["Listen for gliding", "Connect consonants", "Avoid choppy speech"],
        actionText: "Start Glide",
        tip: "PRO TIP: When a word ends in a consonant and the next starts with a vowel, push them together!",
      );
    }
    if (type == GameSubtype.shadowingChallenge) {
      return const GameBriefing(
        title: "Speed Shadow",
        icon: Icons.bolt_rounded,
        objective: "SHADOW NOW: Speak along with the audio with minimal delay. Perfect your timing.",
        rules: ["No delay allowed", "Sync your voice", "3 Hearts"],
        actionText: "Initiate Shadow",
        tip: "PRO TIP: Don't wait for the audio to finish—start speaking as soon as you hear the first syllable!",
      );
    }
    if (type == GameSubtype.vowelDistinction) {
      return const GameBriefing(
        title: "Vowel Vortex",
        icon: Icons.cyclone_rounded,
        objective: "ISOLATE VOWELS: Master the nuances between complex vowel sounds like /æ/, /ɛ/, and /ɪ/.",
        rules: ["Focus on tongue position", "Identify the sound", "Select the match"],
        actionText: "Sort Vowels",
        tip: "PRO TIP: For /æ/ (like 'cat'), open your mouth wider than for /ɛ/ (like 'met')!",
      );
    }
    if (type == GameSubtype.consonantClarity) {
      return const GameBriefing(
        title: "Clear Consonants",
        icon: Icons.graphic_eq_rounded,
        objective: "MASTER CLARITY: Perfect difficult consonant sounds and clusters (e.g., /th/, /r/, /l/).",
        rules: ["Focus on airflow", "Check teeth position", "Record clearly"],
        actionText: "Speak Clearly",
        tip: "PRO TIP: For the 'TH' sound, place the tip of your tongue gently between your front teeth!",
      );
    }
    if (type == GameSubtype.pitchPatternMatch) {
      return const GameBriefing(
        title: "Musical Melody",
        icon: Icons.music_note_rounded,
        objective: "MATCH MELODY: Replicate the 'musical' pattern of a full sentence.",
        rules: ["Listen to the melody", "Hum first if needed", "Speak with rhythm"],
        actionText: "Match Melody",
        tip: "PRO TIP: English is a stress-timed language—some words are fast, some are slow. Match the tempo!",
      );
    }
    if (type == GameSubtype.speedVariance) {
      return const GameBriefing(
        title: "Tempo Trainer",
        icon: Icons.speed_rounded,
        objective: "MANAGE SPEED: Practice speaking at different speeds while maintaining perfect clarity.",
        rules: ["Slow for accuracy", "Fast for fluency", "Maintain rhythm"],
        actionText: "Train Tempo",
        tip: "PRO TIP: Even when speaking fast, don't sacrifice the ending sounds of your words!",
      );
    }
    if (type == GameSubtype.dialectDrill) {
      return const GameBriefing(
        title: "Dialect Diver",
        icon: Icons.public_rounded,
        objective: "ADAPT ACCENTS: Identify and mimic characteristics of different English dialects.",
        rules: ["Identify region", "Mimic vowel shifts", "3 Hearts"],
        actionText: "Start Drill",
        tip: "PRO TIP: Accents are about specific vowel shifts! Pay attention to how 'O' or 'A' sounds change.",
      );
    }
    if (type == GameSubtype.connectedSpeech) {
      return const GameBriefing(
        title: "Fusion Focus",
        icon: Icons.settings_input_composite_rounded,
        objective: "REDUCE SOUNDS: Master contractions and reduced sounds (e.g., 'going to' -> 'gonna').",
        rules: ["Identify reductions", "Speak fluently", "Sound natural"],
        actionText: "Start Fusion",
        tip: "PRO TIP: Reducing function words helps you sound more like a native speaker in casual talk!",
      );
    }
    if (type == GameSubtype.pitchModulation) {
      return const GameBriefing(
        title: "Dynamic Range",
        icon: Icons.legend_toggle_rounded,
        objective: "EMOTIONAL RANGE: Use pitch to express different emotions (surprise, anger, joy).",
        rules: ["Match the emotion", "Shift your pitch", "3 Hearts left"],
        actionText: "Modulate Now",
        tip: "PRO TIP: Higher pitch often signals excitement or surprise, while lower pitch is more serious.",
      );
    }

    // --- ROLEPLAY (Social Intelligence) ---
    if (type == GameSubtype.branchingDialogue) {
      return const GameBriefing(
        title: "Choice Navigator",
        icon: Icons.alt_route_rounded,
        objective: "NAVIGATE PATHS: Choose the response that leads to the most successful outcome.",
        rules: ["Listen to the prompt", "Evaluate consequences", "Stay on mission"],
        actionText: "Choose Path",
        tip: "PRO TIP: Think about the other person's feelings before you choose your response!",
      );
    }
    if (type == GameSubtype.situationalResponse) {
      return const GameBriefing(
        title: "Reflex Responder",
        icon: Icons.flash_on_rounded,
        objective: "RESPOND FAST: Pick the most appropriate social response for the given situation.",
        rules: ["Match the social tone", "Be polite/direct", "3 Hearts"],
        actionText: "Respond Now",
        tip: "PRO TIP: Politeness markers like 'Could you' or 'Would you mind' go a long way!",
      );
    }
    if (type == GameSubtype.jobInterview) {
      return const GameBriefing(
        title: "Career Closer",
        icon: Icons.business_center_rounded,
        objective: "INTERVIEW PRO: Navigate a high-stakes job interview by choosing professional answers.",
        rules: ["Be professional", "Highlight skills", "Stay confident"],
        actionText: "Start Interview",
        tip: "PRO TIP: Always link your answers back to how you can help the company succeed!",
      );
    }
    if (type == GameSubtype.medicalConsult) {
      return const GameBriefing(
        title: "Health Liaison",
        icon: Icons.medical_services_rounded,
        objective: "EXPLAIN SYMPTOMS: Describe medical issues or understand doctor's advice clearly.",
        rules: ["Be accurate", "Describe feelings", "3 Hearts"],
        actionText: "Start Consult",
        tip: "PRO TIP: Use specific words like 'Aching', 'Sharp', or 'Dull' to describe pain.",
      );
    }
    if (type == GameSubtype.gourmetOrder) {
      return const GameBriefing(
        title: "Order Master",
        icon: Icons.restaurant_rounded,
        objective: "DINE OUT: Order food, ask for recommendations, and handle bill issues.",
        rules: ["Be polite", "Check the menu", "Clear communication"],
        actionText: "Place Order",
        tip: "PRO TIP: Using 'I'd like' is more polite than 'I want' when ordering food!",
      );
    }
    if (type == GameSubtype.travelDesk) {
      return const GameBriefing(
        title: "Global Traveler",
        icon: Icons.flight_takeoff_rounded,
        objective: "NAVIGATE TRAVEL: Handle check-ins, directions, and hotel bookings in English.",
        rules: ["Check your tickets", "Follow directions", "Ask for help"],
        actionText: "Start Journey",
        tip: "PRO TIP: Always confirm directions by repeating them back to the person!",
      );
    }
    if (type == GameSubtype.conflictResolver) {
      return const GameBriefing(
        title: "Peace Maker",
        icon: Icons.handshake_rounded,
        objective: "DE-ESCALATE: Resolve social conflicts or misunderstandings with tact and diplomacy.",
        rules: ["Use 'I' statements", "Acknowledge feelings", "Find a middle ground"],
        actionText: "Resolve Conflict",
        tip: "PRO TIP: Say 'I understand' even if you disagree—it helps calm the other person down.",
      );
    }
    if (type == GameSubtype.elevatorPitch) {
      return const GameBriefing(
        title: "Pitch Perfect",
        icon: Icons.rocket_launch_rounded,
        objective: "PITCH IDEAS: Deliver a compelling and concise message in a short time frame.",
        rules: ["Be brief", "High impact", "3 Hearts left"],
        actionText: "Start Pitch",
        tip: "PRO TIP: Start with a hook! Grab their attention in the first 5 seconds.",
      );
    }
    if (type == GameSubtype.socialSpark) {
      return const GameBriefing(
        title: "Charisma Core",
        icon: Icons.celebration_rounded,
        objective: "SMALL TALK: Master the art of starting and maintaining casual conversations.",
        rules: ["Ask open questions", "Show interest", "Keep it light"],
        actionText: "Spark Talk",
        tip: "PRO TIP: Ask 'Why' or 'How' instead of 'Yes/No' questions to keep the talk going!",
      );
    }
    if (type == GameSubtype.emergencyHub) {
      return const GameBriefing(
        title: "Emergency Voice",
        icon: Icons.emergency_share_rounded,
        objective: "CRISIS CALL: Communicate effectively during high-pressure emergency situations.",
        rules: ["Stay calm", "Give location first", "Be precise"],
        actionText: "Help Now",
        tip: "PRO TIP: Your location is the most important data—give it as soon as possible!",
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

  static GameBriefing? _getKidsBriefing(String category) {
    switch (category.toLowerCase()) {
      case 'alphabet':
        return const GameBriefing(
          title: "Alphabet Adventure",
          icon: Icons.abc_rounded,
          objective: "LEARN LETTERS: Match the letters to their sounds and shapes!",
          rules: ["Follow the ABCs", "Find the matching pair", "Listen to the letter"],
          actionText: "Play ABCs",
          tip: "Sing the ABC song to help you remember the order! 🎵",
        );
      case 'animals':
        return const GameBriefing(
          title: "Animal Safari",
          icon: Icons.pets_rounded,
          objective: "EXPLORE NATURE: Learn the names and sounds of your favorite animals!",
          rules: ["Watch the animals", "Listen to their sounds", "Match the names"],
          actionText: "Go Safari",
          tip: "Try making the animal sound yourself to remember it better! 🦁",
        );
      case 'numbers':
        return const GameBriefing(
          title: "Number Fun",
          icon: Icons.numbers_rounded,
          objective: "COUNTING TIME: Learn to count and recognize numbers 1 to 100!",
          rules: ["Count the objects", "Pick the right number", "Say it out loud"],
          actionText: "Start Counting",
          tip: "Use your fingers to count along with the game! 🖐️",
        );
      case 'colors':
        return const GameBriefing(
          title: "Rainbow World",
          icon: Icons.palette_rounded,
          objective: "COLOR MIXER: Identify and name all the colors of the rainbow!",
          rules: ["Look at the colors", "Match the word", "Paint the world"],
          actionText: "Paint Colors",
          tip: "Look around your room—how many colors from the game can you see? 🌈",
        );
      case 'fruits':
        return const GameBriefing(
          title: "Fruit Garden",
          icon: Icons.shopping_basket_rounded,
          objective: "TASTY LEARNING: Discover delicious fruits and their healthy names!",
          rules: ["Pick the fruit", "Match the shape", "Learn the name"],
          actionText: "Pick Fruits",
          tip: "Fruits are super healthy and give you energy to play! 🍎",
        );
      case 'shapes':
        return const GameBriefing(
          title: "Shape Explorer",
          icon: Icons.category_rounded,
          objective: "GEOMETRY FUN: Learn about circles, squares, triangles, and more!",
          rules: ["Find the shape", "Match the edges", "Learn the name"],
          actionText: "Explore Shapes",
          tip: "Shapes are everywhere! A clock is a circle and a door is a rectangle. 📐",
        );
      case 'body_parts':
        return const GameBriefing(
          title: "My Body",
          icon: Icons.accessibility_new_rounded,
          objective: "SELF DISCOVERY: Learn the names of different parts of your body!",
          rules: ["Touch your nose", "Find the eyes", "Name the parts"],
          actionText: "Start Learning",
          tip: "Can you point to the body part as you hear its name? 🧍",
        );
      case 'family':
        return const GameBriefing(
          title: "Family Tree",
          icon: Icons.family_restroom_rounded,
          objective: "KINDRED SPIRITS: Learn about family members like Mom, Dad, and more!",
          rules: ["Meet the family", "Match the names", "Listen to the roles"],
          actionText: "Meet Family",
          tip: "Family is all about love and helping each other! ❤️",
        );
      case 'food_kids':
        return const GameBriefing(
          title: "Yummy Food",
          icon: Icons.restaurant_rounded,
          objective: "CHEF'S KITCHEN: Learn the names of yummy foods we eat every day!",
          rules: ["See the food", "Match the taste", "Name the meal"],
          actionText: "Eat Up",
          tip: "Eating a variety of foods helps you grow big and strong! 🥛",
        );
      case 'clothing':
        return const GameBriefing(
          title: "Dress Up",
          icon: Icons.checkroom_rounded,
          objective: "FASHION FUN: Learn the names of clothes like shirts, hats, and shoes!",
          rules: ["Pick the outfit", "Dress the buddy", "Name the clothes"],
          actionText: "Get Dressed",
          tip: "What are you wearing today? Try to name it in English! 👕",
        );
      case 'nature':
        return const GameBriefing(
          title: "Nature Walk",
          icon: Icons.forest_rounded,
          objective: "OUTDOOR FUN: Explore trees, flowers, the sun, and the moon!",
          rules: ["See the plants", "Look at the sky", "Name nature"],
          actionText: "Start Walk",
          tip: "Nature is beautiful! Always remember to be kind to the Earth. 🌳",
        );
      case 'transport':
        return const GameBriefing(
          title: "Zoom Zoom!",
          icon: Icons.directions_car_rounded,
          objective: "FAST TRAVEL: Learn about cars, planes, trains, and boats!",
          rules: ["Watch them go", "Listen to engines", "Match the vehicle"],
          actionText: "Start Engine",
          tip: "Which way do you like to travel? Beep beep! 🚗",
        );
      case 'emotions':
        return const GameBriefing(
          title: "Feeling Happy",
          icon: Icons.mood_rounded,
          objective: "EMOTION CHECK: Understand feelings like happy, sad, and surprised!",
          rules: ["Look at the faces", "Match the feeling", "Be kind"],
          actionText: "Share Feelings",
          tip: "It's okay to feel different things! Talk to a buddy about it. 😊",
        );
      case 'school':
        return const GameBriefing(
          title: "School Days",
          icon: Icons.school_rounded,
          objective: "CLASSROOM FUN: Learn about pencils, books, and your teacher!",
          rules: ["Pack your bag", "Find the tools", "Learn and play"],
          actionText: "Go to School",
          tip: "School is a place to make friends and learn new things! 🎒",
        );
      case 'home_kids':
        return const GameBriefing(
          title: "My Sweet Home",
          icon: Icons.home_rounded,
          objective: "HOUSE TOUR: Discover rooms and things found in your house!",
          rules: ["Visit the rooms", "Find the items", "Name the furniture"],
          actionText: "Enter House",
          tip: "There's no place like home! What's your favorite room? 🏠",
        );
      case 'opposites':
        return const GameBriefing(
          title: "Big and Small",
          icon: Icons.compare_rounded,
          objective: "DIFFERENCE DETECTOR: Learn about opposites like hot/cold and up/down!",
          rules: ["See the difference", "Match the pair", "Find the opposite"],
          actionText: "Match Pairs",
          tip: "Opposites are everywhere! Like the sun is 'hot' and ice is 'cold'. 🧊",
        );
      case 'verbs':
        return const GameBriefing(
          title: "Action Time!",
          icon: Icons.directions_run_rounded,
          objective: "ACTIVE LEARNING: Learn action words like run, jump, and sleep!",
          rules: ["Do the action", "Watch the buddy", "Match the verb"],
          actionText: "Get Active",
          tip: "Can you jump as you hear the word 'jump'? Give it a try! 🏃",
        );
      case 'prepositions':
        return const GameBriefing(
          title: "Where is it?",
          icon: Icons.location_on_rounded,
          objective: "POSITION FINDER: Learn words like in, on, under, and next to!",
          rules: ["Find the object", "Check the spot", "Learn the position"],
          actionText: "Find It",
          tip: "The cat is 'on' the mat! Can you find something 'under' your chair? 📦",
        );
      case 'routine':
        return const GameBriefing(
          title: "My Daily Day",
          icon: Icons.today_rounded,
          objective: "DAILY HABITS: Learn about brushing teeth, eating, and sleeping!",
          rules: ["Follow the day", "Sequence the habits", "Learn the names"],
          actionText: "Start Day",
          tip: "Having a good routine helps you stay healthy and happy! 🪥",
        );
      case 'phonics':
        return const GameBriefing(
          title: "Sound Master",
          icon: Icons.record_voice_over_rounded,
          objective: "PHONICS POWER: Master the sounds of different letters and blends!",
          rules: ["Listen to sound", "Say it clearly", "Match the blend"],
          actionText: "Make Sounds",
          tip: "Phonics is the secret key to reading! Keep practicing your sounds. 🗣️",
        );
      case 'time':
        return const GameBriefing(
          title: "Tick Tock!",
          icon: Icons.access_time_rounded,
          objective: "TIME TELLER: Learn about morning, afternoon, and the clock!",
          rules: ["Check the clock", "Follow the sun", "Name the time"],
          actionText: "Check Time",
          tip: "What time is it? The clock tells us when to play and when to eat! ⏰",
        );
      case 'day_night':
        return const GameBriefing(
          title: "Sun and Moon",
          icon: Icons.brightness_6_rounded,
          objective: "DAY & NIGHT: Learn about the differences between day and night!",
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
      objective: "Complete the challenge to earn rewards and master your skills!",
      rules: ["3 Hearts per mission", "2 Strikes (Mistakes Re-queued)", "Achieve 100% Mastery"],
      actionText: "Start Quest",
      tip: "PRO TIP: Stay focused and listen to your buddy! They have the answers you need.",
    );
  }
}

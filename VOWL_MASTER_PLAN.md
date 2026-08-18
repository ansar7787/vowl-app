# VOWL — 100 Adult Games: Master Plan & Task Tracker

> **Generated**: 2026-08-18 | **Games**: 100 | **Categories**: 9 | **Levels/Game**: 200 | **Total Levels**: 20,000

---

## ✅ CODE VERIFICATION RESULTS (Confirmed from actual source code)

### All 100 Games Have Dedicated Screens
Verified in `app_router_game_resolvers.dart` (806 lines): Every single `GameSubtype` maps to a **unique, dedicated screen widget** — no two games share the same screen. Each game has its own folder with its own screen file.

### Free-of-Cost Stack (Verified from `pubspec.yaml`)
| Service | Package | Cost | Proof |
|---------|---------|------|-------|
| Speech Recognition | `speech_to_text: ^7.1.0` | **$0** (on-device) | Line 37 |
| Text-to-Speech | `flutter_tts: ^4.2.5` | **$0** (on-device) | Line 36 |
| Ad Revenue | `google_mobile_ads: ^9.1.0` | **$0** (earns money) | Line 29 |
| Auth | `firebase_auth: ^6.4.0` | **$0** (free 10K/month) | Line 17 |
| Database | `cloud_firestore: ^6.3.0` | **$0** (free 1GB) | Line 18 |
| Analytics | `firebase_analytics: ^12.3.0` | **$0** | Line 35 |
| Crash Reports | `firebase_crashlytics: ^5.2.0` | **$0** | Line 51 |
| Translation | `google_mlkit_translation` | **$0** (on-device ML) | Line 64 |
| Text Recognition | `google_mlkit_text_recognition` | **$0** (on-device ML) | Line 67 |
| Handwriting | `google_mlkit_digital_ink_recognition` | **$0** (on-device ML) | Line 68 |
| **TOTAL RUNNING COST** | | **$0/month** | |

---

## 🎯 PEDAGOGICAL GUARANTEE: "No Skill, No Pass"

> **RULE**: If the user doesn't ACTUALLY USE the skill, the game is BROKEN.

| Category | User MUST Do This | If They Don't → Game is Useless |
|----------|------------------|---------------------------------|
| **Speaking** | 🎤 Speak into mic, speech recognized | Just tapping buttons = NO speaking learned |
| **Listening** | 🔊 Listen to TTS audio, then answer | Just reading text = NO listening learned |
| **Reading** | 📖 Read full passage, comprehend | Just guessing from options = NO reading learned |
| **Writing** | ✍️ Type/write actual sentences | Just tapping choices = NO writing learned |
| **Grammar** | 🧠 Apply grammar rules to transform sentences | Just memorizing = NO grammar learned |
| **Vocabulary** | 💡 Recall meaning, use in context | Just seeing words = NO vocabulary learned |
| **Accent** | 🗣️ Mimic sounds, record & compare | Just listening = NO accent learned |
| **Roleplay** | 🎭 Make real conversation choices | Just reading scripts = NO roleplay learned |
| **Elite Mastery** | 🏆 Combine all skills creatively | Just one skill = NO mastery |

---

## PHASE 1: 100 ADULT GAMES — FULL TRACKER

### CAT-1: 🎤 SPEAKING (10 games) — User MUST speak into microphone

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 1 | Repeat Sentence | Hears sentence → speaks it exactly | Pronunciation + fluency via shadowing | ✅ | ✅ `RepeatSentenceScreen` | ✅ | ✅ |
| 2 | Speak Missing Word | Sees sentence with blank → says the word | Active recall + context prediction | ✅ | ✅ `SpeakMissingWordScreen` | ✅ | ✅ |
| 3 | Situation Speaking | Given real situation → speaks response | Spontaneous speech under pressure | ✅ | ✅ `SituationSpeakingScreen` | ✅ | ✅ |
| 4 | Scene Description | Sees scene prompt → describes verbally | Descriptive vocabulary + fluency | ✅ | ✅ `SceneDescriptionScreen` | ✅ | ✅ |
| 5 | Yes/No Speaking | Hears question → says yes/no + reason | Quick response + justification skills | ✅ | ✅ `YesNoSpeakingScreen` | ✅ | ✅ |
| 6 | Speak Synonym | Sees word → says a synonym out loud | Vocabulary breadth via active production | ✅ | ✅ `SpeakSynonymScreen` | ✅ | ✅ |
| 7 | Dialogue Roleplay | Takes turns in conversation → speaks | Conversational flow + turn-taking | ✅ | ✅ `DialogueRoleplayScreen` | ✅ | ✅ |
| 8 | Pronunciation Focus | Targets specific sound → records & compares | Phoneme-level accuracy | ✅ | ✅ `PronunciationFocusScreen` | ✅ | ✅ |
| 9 | Speak Opposite | Hears word → says antonym out loud | Vocabulary + speed of recall | ✅ | ✅ `SpeakOppositeScreen` | ✅ | ✅ |
| 10 | Daily Expression | Learns expression → practices saying it | Real-world phrases for daily use | ✅ | ✅ `DailyExpressionScreen` | ✅ | ✅ |

### CAT-2: 🔊 LISTENING (10 games) — User MUST listen to audio first

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 11 | Audio Fill Blanks | Listens → fills missing words from audio | Detail-focused listening | ✅ | ✅ `AudioFillBlanksScreen` | ✅ | ✅ |
| 12 | Audio MCQ | Listens to clip → answers comprehension Q | Gist + detail comprehension | ✅ | ✅ `AudioMultipleChoiceScreen` | ✅ | ✅ |
| 13 | Audio Sentence Order | Listens → arranges sentences in order | Sequence tracking in speech | ✅ | ✅ `AudioSentenceOrderScreen` | ✅ | ✅ |
| 14 | Audio True/False | Listens → judges if statement matches audio | Critical listening accuracy | ✅ | ✅ `AudioTrueFalseScreen` | ✅ | ✅ |
| 15 | Sound Image Match | Hears sound/word → matches to image | Vocabulary + auditory association | ✅ | ✅ `SoundImageMatchScreen` | ✅ | ✅ |
| 16 | Fast Speech Decoder | Listens to fast speech → decodes meaning | Real-world speed comprehension | ✅ | ✅ `FastSpeechDecoderScreen` | ✅ | ✅ |
| 17 | Emotion Recognition | Listens to tone → identifies emotion | Pragmatic/emotional intelligence | ✅ | ✅ `EmotionRecognitionScreen` | ✅ | ✅ |
| 18 | Detail Spotlight | Listens → spots specific details | Selective attention training | ✅ | ✅ `DetailSpotlightScreen` | ✅ | ✅ |
| 19 | Listening Inference | Listens → infers what speaker means | Beyond-literal comprehension | ✅ | ✅ `ListeningInferenceScreen` | ✅ | ✅ |
| 20 | Ambient ID | Listens to ambient sounds → identifies | Environmental English context | ✅ | ✅ `AmbientIdScreen` | ✅ | ✅ |

### CAT-3: 📖 READING (12 games) — User MUST read full passage

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 | Custom Widget |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|---------------|
| 21 | Read & Answer | Reads passage → answers comprehension Qs | Core reading comprehension | ✅ | ✅ `ReadAndAnswerScreen` | ✅ | ✅ | ✅ |
| 22 | Find Word Meaning | Reads passage → finds word meaning in context | Context-based vocabulary | ✅ | ✅ `FindWordMeaningScreen` | ✅ | ✅ | ✅ |
| 23 | True/False Reading | Reads → judges statements true/false | Critical reading accuracy | ✅ | ✅ `TrueFalseReadingScreen` | ✅ | ✅ | ✅ |
| 24 | Sentence Order | Reads jumbled sentences → orders them | Text structure understanding | ✅ | ✅ `SentenceOrderReadingScreen` | ✅ | ✅ | ✅ |
| 25 | Reading Speed Check | Reads under timer → answers questions | Speed + comprehension balance | ✅ | ✅ `ReadingSpeedCheckScreen` | ✅ | ✅ | ✅ |
| 26 | Guess Title | Reads passage → guesses best title | Main idea extraction | ✅ | ✅ `GuessTitleScreen` | ✅ | ✅ | ✅ |
| 27 | Read & Match | Reads → matches statements to paragraphs | Paragraph-level comprehension | ✅ | ✅ `ReadAndMatchScreen` | ✅ | ✅ | ✅ |
| 28 | Paragraph Summary | Reads → selects best summary | Summarization skill | ✅ | ✅ `ParagraphSummaryScreen` | ✅ | ✅ | ✅ |
| 29 | Reading Inference | Reads → infers unstated meaning | Higher-order thinking | ✅ | ✅ `ReadingInferenceScreen` | ✅ | ✅ | ✅ |
| 30 | Reading Conclusion | Reads → draws logical conclusion | Analytical reading | ✅ | ✅ `ReadingConclusionScreen` | ✅ | ✅ | ✅ |
| 31 | Cloze Test | Reads passage with blanks → fills them | Grammar + vocabulary in context | ✅ | ✅ `ClozeTestScreen` | ✅ | ✅ | ✅ |
| 32 | Skimming & Scanning | Reads quickly → finds specific info | Speed reading technique | ✅ | ✅ `SkimmingScanningScreen` | ✅ | ✅ | ✅ |

### CAT-4: ✍️ WRITING (11 games) — User MUST type/write actual text

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 33 | Sentence Builder | Drags words → builds correct sentence | Word order + grammar structure | ✅ | ✅ `SentenceBuilderScreen` | ✅ | ✅ |
| 34 | Complete Sentence | Types missing words into sentence | Grammar + vocabulary production | ✅ | ✅ `CompleteSentenceScreen` | ✅ | ✅ |
| 35 | Describe Situation | Reads situation → writes description | Descriptive writing skills | ✅ | ✅ `DescribeSituationScreen` | ✅ | ✅ |
| 36 | Fix The Sentence | Finds & types corrections | Error detection + correction | ✅ | ✅ `FixTheSentenceScreen` | ✅ | ✅ |
| 37 | Short Answer | Reads question → writes short answer | Concise response writing | ✅ | ✅ `ShortAnswerScreen` | ✅ | ✅ |
| 38 | Opinion Writing | Writes opinion paragraph with reasons | Argumentative writing | ✅ | ✅ `OpinionWritingScreen` | ✅ | ✅ |
| 39 | Daily Journal | Writes daily journal entry | Personal narrative writing | ✅ | ✅ `DailyJournalScreen` | ✅ | ✅ |
| 40 | Summarize Story | Reads story → writes summary | Summary/synthesis skills | ✅ | ✅ `SummarizeStoryWritingScreen` | ✅ | ✅ |
| 41 | Writing Email | Writes professional email | Formal writing skills | ✅ | ✅ `WritingEmailScreen` | ✅ | ✅ |
| 42 | Correction Writing | Identifies errors → writes corrections | Proofreading skills | ✅ | ✅ `CorrectionWritingScreen` | ✅ | ✅ |
| 43 | Essay Drafting | Writes structured essay draft | Academic writing skills | ✅ | ✅ `EssayDraftingScreen` | ✅ | ✅ |

### CAT-5: 🧠 GRAMMAR (19 games) — User MUST apply grammar rules

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 44 | Grammar Quest | Applies grammar rule → selects answer | General grammar awareness | ✅ | ✅ `GrammarQuestScreen` | ✅ | ✅ |
| 45 | Sentence Correction | Spots error → selects correction | Error detection skills | ✅ | ✅ `SentenceCorrectionScreen` | ✅ | ⬜ |
| 46 | Word Reorder | Drags words into correct order | Syntax structure mastery | ✅ | ✅ `WordReorderScreen` | ✅ | ⬜ |
| 47 | Tense Mastery | Selects correct tense form | Verb tense system | ✅ | ✅ `TenseMasteryScreen` | ✅ | ⬜ |
| 48 | Parts of Speech | Sorts words by grammatical category | Word class awareness | ✅ | ✅ `PartsOfSpeechScreen` | ✅ | ⬜ |
| 49 | Subject-Verb Agreement | Fixes agreement errors | Core grammar accuracy | ✅ | ✅ `SubjectVerbAgreementScreen` | ✅ | ⬜ |
| 50 | Clause Connector | Connects clauses with right conjunction | Complex sentence building | ✅ | ✅ `ClauseConnectorScreen` | ✅ | ⬜ |
| 51 | Voice Swap | Converts active↔passive | Voice transformation | ✅ | ✅ `VoiceSwapScreen` | ✅ | ⬜ |
| 52 | Question Formatter | Reorders words into question form | Interrogative structures | ✅ | ✅ `QuestionFormatterScreen` | ✅ | ⬜ |
| 53 | Article Insertion | Inserts a/an/the correctly | Article system mastery | ✅ | ✅ `ArticleInsertionScreen` | ✅ | ⬜ |
| 54 | Modifier Placement | Places adjective/adverb correctly | Modifier positioning | ✅ | ✅ `ModifierPlacementScreen` | ✅ | ⬜ |
| 55 | Modals Selection | Chooses correct modal verb | Modal verb nuance | ✅ | ✅ `ModalsSelectionScreen` | ✅ | ⬜ |
| 56 | Preposition Choice | Selects correct preposition | Prepositional accuracy | ✅ | ✅ `PrepositionChoiceScreen` | ✅ | ⬜ |
| 57 | Pronoun Resolution | Resolves pronoun references | Reference clarity | ✅ | ✅ `PronounResolutionScreen` | ✅ | ⬜ |
| 58 | Punctuation Mastery | Fixes punctuation errors | Punctuation rules | ✅ | ✅ `PunctuationMasteryScreen` | ✅ | ⬜ |
| 59 | Relative Clauses | Completes with who/which/that | Relative clause usage | ✅ | ✅ `RelativeClausesScreen` | ✅ | ⬜ |
| 60 | Conditionals | Masters if/then structures | Conditional logic | ✅ | ✅ `ConditionalsScreen` | ✅ | ⬜ |
| 61 | Conjunctions | Uses and/but/or/because correctly | Sentence joining | ✅ | ✅ `ConjunctionsScreen` | ✅ | ⬜ |
| 62 | Direct/Indirect Speech | Converts speech types | Reported speech mastery | ✅ | ✅ `DirectIndirectSpeechScreen` | ✅ | ⬜ |

### CAT-6: 💡 VOCABULARY (12 games) — User MUST recall & use words

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 63 | Flashcards | Flips card → recalls meaning | Spaced recognition + recall | ✅ | ✅ `FlashcardsScreen` | ✅ | ⬜ |
| 64 | Synonym Search | Finds synonym from options | Vocabulary breadth | ✅ | ✅ `SynonymSearchScreen` | ✅ | ⬜ |
| 65 | Antonym Search | Finds antonym from options | Opposite word pairs | ✅ | ✅ `AntonymSearchScreen` | ✅ | ⬜ |
| 66 | Context Clues | Guesses word meaning from passage | Context inference skill | ✅ | ✅ `ContextCluesScreen` | ✅ | ⬜ |
| 67 | Phrasal Verbs | Slots correct phrasal verb in | Multi-word verb mastery | ✅ | ✅ `PhrasalVerbsScreen` | ✅ | ⬜ |
| 68 | Idioms | Learns idiom → matches meaning | Figurative language | ✅ | ✅ `IdiomsScreen` | ✅ | ⬜ |
| 69 | Academic Word | Masters academic vocabulary | Formal register words | ✅ | ✅ `AcademicWordScreen` | ✅ | ⬜ |
| 70 | Topic Vocabulary | Sorts words into topic buckets | Categorical vocabulary | ✅ | ✅ `TopicVocabScreen` | ✅ | ⬜ |
| 71 | Word Formation | Builds words from roots/parts | Morphological awareness | ✅ | ✅ `WordFormationScreen` | ✅ | ⬜ |
| 72 | Prefix/Suffix | Chains prefix+root+suffix | Word building system | ✅ | ✅ `PrefixSuffixScreen` | ✅ | ⬜ |
| 73 | Collocations | Matches words that go together | Natural word pairing | ✅ | ✅ `CollocationsScreen` | ✅ | ⬜ |
| 74 | Contextual Usage | Uses word correctly in context | Applied vocabulary | ✅ | ✅ `ContextualUsageScreen` | ✅ | ⬜ |

### CAT-7: 🗣️ ACCENT (12 games) — User MUST listen & reproduce sounds

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 75 | Minimal Pairs | Distinguishes ship/sheep, bat/bet | Phoneme discrimination | ✅ | ✅ `MinimalPairsScreen` | ✅ | ⬜ |
| 76 | Intonation Mimic | Copies rising/falling patterns | Intonation awareness | ✅ | ✅ `IntonationMimicScreen` | ✅ | ⬜ |
| 77 | Syllable Stress | Marks stressed syllable | Word stress patterns | ✅ | ✅ `SyllableStressScreen` | ✅ | ⬜ |
| 78 | Word Linking | Practices linking words together | Connected speech fluency | ✅ | ✅ `WordLinkingScreen` | ✅ | ⬜ |
| 79 | Shadowing Challenge | Shadows native speaker recording | Natural rhythm + pacing | ✅ | ✅ `ShadowingChallengeScreen` | ✅ | ⬜ |
| 80 | Vowel Distinction | Distinguishes similar vowels | Vowel clarity | ✅ | ✅ `VowelDistinctionScreen` | ✅ | ⬜ |
| 81 | Consonant Clarity | Practices difficult consonants | Consonant precision | ✅ | ✅ `ConsonantClarityScreen` | ✅ | ⬜ |
| 82 | Pitch Pattern Match | Matches pitch contour patterns | Prosody awareness | ✅ | ✅ `PitchPatternMatchScreen` | ✅ | ⬜ |
| 83 | Speed Variance | Adapts to slow/fast speech | Speed adaptability | ✅ | ✅ `SpeedVarianceScreen` | ✅ | ⬜ |
| 84 | Dialect Drill | Practices different English dialects | Dialect comprehension | ✅ | ✅ `DialectDrillScreen` | ✅ | ⬜ |
| 85 | Connected Speech | Masters elision/assimilation | Natural speech flow | ✅ | ✅ `ConnectedSpeechScreen` | ✅ | ⬜ |
| 86 | Pitch Modulation | Modulates pitch for meaning changes | Expressive speech | ✅ | ✅ `PitchModulationScreen` | ✅ | ⬜ |

### CAT-8: 🎭 ROLEPLAY (10 games) — User MUST make real conversation choices

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 87 | Branching Dialogue | Chooses dialogue paths → sees consequences | Decision-based conversation | ✅ | ✅ `BranchingDialogueScreen` | ✅ | ⬜ |
| 88 | Situational Response | Responds to real-life situations | Pragmatic competence | ✅ | ✅ `SituationalResponseScreen` | ✅ | ⬜ |
| 89 | Job Interview | Practices interview Q&A | Professional communication | ✅ | ✅ `JobInterviewScreen` | ✅ | ⬜ |
| 90 | Medical Consult | Practices doctor visit dialogue | Medical English | ✅ | ✅ `MedicalConsultScreen` | ✅ | ⬜ |
| 91 | Gourmet Order | Orders food in restaurant | Restaurant English | ✅ | ✅ `GourmetOrderScreen` | ✅ | ⬜ |
| 92 | Travel Desk | Handles travel scenarios | Travel English | ✅ | ✅ `TravelDeskScreen` | ✅ | ⬜ |
| 93 | Conflict Resolver | Resolves conflicts politely | Diplomatic language | ✅ | ✅ `ConflictResolverScreen` | ✅ | ⬜ |
| 94 | Elevator Pitch | Gives quick self-introduction | Concise persuasion | ✅ | ✅ `ElevatorPitchScreen` | ✅ | ⬜ |
| 95 | Social Spark | Starts conversations with strangers | Social English | ✅ | ✅ `SocialSparkScreen` | ✅ | ⬜ |
| 96 | Emergency Hub | Handles emergency situations | Emergency English | ✅ | ✅ `EmergencyHubScreen` | ✅ | ⬜ |

### CAT-9: 🏆 ELITE MASTERY (4 games) — User MUST combine multiple skills

| # | Game | What User Does | How User Learns | JSON (20 files) | Screen | Pedagogy | UI Phase 2 |
|---|------|---------------|-----------------|-----------------|--------|----------|----------|
| 97 | Story Builder | Writes creative story from prompts | Creative writing + grammar + vocab | ✅ | ✅ `StoryBuilderScreen` | ✅ | ⬜ |
| 98 | Idiom Match | Matches idioms to real meanings | Advanced figurative language | ✅ | ✅ `IdiomMatchScreen` | ✅ | ⬜ |
| 99 | Speed Spelling | Spells words under time pressure | Spelling accuracy + speed | ✅ | ✅ `SpeedSpellingScreen` | ✅ | ⬜ |
| 100 | Accent Shadowing | Shadows accent patterns precisely | Native-like pronunciation | ✅ | ✅ `AccentShadowingScreen` | ✅ | ⬜ |

---

## PHASE 2: SECOND-PHASE FEATURES

| # | Feature | Skill Trained | User Action | Free? | Status |
|---|---------|--------------|-------------|-------|--------|
| A1 | Daily Words | Vocabulary | Learn 5 new words daily, hear pronunciation | ✅ $0 | ⬜ |
| A2 | Photo Vocabulary | Vocabulary | Point camera → AI labels objects in English | ✅ $0 (ML Kit) | ⬜ |
| A3 | Scan & Learn | Reading | Scan text → AI explains meaning | ✅ $0 (ML Kit) | ⬜ |
| A4 | Translation | Multi-skill | Type/speak → get translation | ✅ $0 (ML Kit) | ⬜ |
| A5 | Kids Zone (25 topics) | All basics | Age-appropriate learning games | ✅ $0 | ⬜ |
| A6 | Self-Evolution Speaking | Speaking | AI evaluates pronunciation accuracy | ✅ $0 (on-device STT) | ⬜ |
| A7 | Self-Evolution Reading | Reading | Tracks reading speed + comprehension | ✅ $0 | ⬜ |
| A8 | Jigsaw Puzzle | Vocabulary | Assemble word pieces into meaning | ✅ $0 | ⬜ |
| A9 | Anagram Challenge | Spelling | Unscramble letters into words | ✅ $0 | ⬜ |

---

## 8-POINT VALIDATION CHECKLIST (Per Game)

```
□ 1. JSON EXISTS      — All 20 batch files (gameType_1_10 → gameType_191_200)
□ 2. JSON SCHEMA      — id, interactionType, instruction, hint, explanation, correctAnswer
□ 3. JSON QUALITY     — Warm human tone, no robotic placeholders, unique per level
□ 4. ENUM MATCH       — GameSubtype enum ↔ JSON gameType field match exactly
□ 5. RESOLVER MATCH   — AppRouterGameResolvers switch case exists for this subtype
□ 6. SCREEN EXISTS    — Dedicated widget in lib/features/{category}/{game}/
□ 7. SKILL ENFORCED   — Speaking games USE mic, Writing games USE keyboard, etc.
□ 8. USER TRULY LEARNS — After 200 levels, user genuinely improved at this skill
```

---

## DRY ARCHITECTURE (Shared Code = Write Once)

| Shared File | What It Does | Used By |
|------------|-------------|---------|
| `GameQuest` entity | Data model for all quests | 100 games |
| `CurriculumService` | Loads JSON from assets | 100 games |
| `GameRoutes` + `AppRouterGameResolvers` | Routes URL → correct screen | 100 games |
| `ModernCategoryMap` | Level selector UI | 100 games |
| `StoryService` (86KB) | Narrative scripts per game | 100 games |
| `GameInstructionService` (82KB) | Instruction cards per game | 100 games |
| `SpeechService` | Mic recording + STT | 22 games (Speaking+Accent) |
| `TtsService` | Text-to-speech playback | 50+ games |
| `SoundService` | Correct/wrong SFX | 100 games |
| `SpeakingBloc/ReadingBloc/etc.` | State management per category | 100 games (9 BLoCs) |

**Per-game unique code**: Only 1 screen + 1 interaction widget. Target < 300 lines each.

---

## 12-WEEK SPRINT PLAN

| Week | Games | Category | Deliverable |
|------|-------|----------|-------------|
| W1 | #1–10 | 🎤 Speaking | 10 games: JSON validated, mic tested, speech recognition working |
| W2 | #11–20 | 🔊 Listening | 10 games: JSON validated, TTS audio playing, comprehension flow |
| W3 | #21–32 | 📖 Reading | 12 games: JSON validated, passage display, highlightable text |
| W4 | #33–43 | ✍️ Writing | 11 games: JSON validated, keyboard input, text evaluation |
| W5 | #44–53 | 🧠 Grammar P1 | 10 games: JSON validated, rule application, drag/reorder |
| W6 | #54–62 | 🧠 Grammar P2 | 9 games: remaining grammar games hardened |
| W7 | #63–74 | 💡 Vocabulary | 12 games: JSON validated, flashcard/sort/match mechanics |
| W8 | #75–86 | 🗣️ Accent | 12 games: JSON validated, audio playback, pitch comparison |
| W9 | #87–96 | 🎭 Roleplay | 10 games: JSON validated, dialogue branching, scenario flow |
| W10 | #97–100 | 🏆 Elite Mastery | 4 games: JSON validated, multi-skill integration |
| W11 | A1–A9 | Phase 2 | Second-phase features: Daily Words, Scan, Photo, Jigsaw, Anagram |
| W12 | ALL | 🚀 Launch | Full regression, App Store submission, production release |

---

## SUMMARY STATS

| Metric | Count |
|--------|-------|
| Total adult games | **100** |
| Total categories | **9** |
| Levels per game | **200** |
| Total playable levels | **20,000** |
| JSON curriculum files | **2,000** (100 games × 20 batches) |
| Dedicated screen widgets | **100** (verified ✅) |
| Monthly server cost | **$0** (verified ✅) |
| Kids Zone topics | **25** |
| Phase 2 features | **9** |
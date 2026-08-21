# VOWL — MASTER PLAN & TASK TRACKER (100 Games → 10/10)

> **Updated**: 2026-08-21 | **100 Games** | **9 Categories** | **$0/month** | **20,000 Levels**

---

## STEP-BY-STEP EXECUTION ORDER

> ✅ = Done | 🔲 = To Do | 🔨 = In Progress | Do steps in order!

### PHASE A: FOUNDATION (Already Done ✅)

| Step | Task | Status | Impact |
|------|------|--------|--------|
| A1 | GameQuest entity model | ✅ | All 100 games |
| A2 | CurriculumService JSON loader | ✅ | All 100 games |
| A3 | 9 Category BLoCs | ✅ | All 100 games |
| A4 | GameRoutes + AppRouterGameResolvers | ✅ | All 100 games |
| A5 | 100 dedicated screen widgets | ✅ | All 100 games |
| A6 | 2000 JSON curriculum files | ✅ | All 100 games |
| A7 | SpeechService (STT on-device) | ✅ | 22 games |
| A8 | TtsService (TTS on-device) | ✅ | 50+ games |
| A9 | SoundService (SFX) | ✅ | All 100 games |
| A10 | ModernCategoryMap (level selector) | ✅ | All 100 games |
| A11 | StoryService + GameInstructionService | ✅ | All 100 games |
| A12 | Firebase Auth + Firestore | ✅ | All users |
| A13 | Google Mobile Ads | ✅ | Revenue |

### PHASE B: EXISTING 8 MECHANICS (Audited & Fixed ✅)

| Step | Mechanic | File | Status | Games Using | Fixes Applied |
|------|----------|------|--------|-------------|---------------|
| B1 | DynamicAnagramWrapper | `game_mechanics/` | ✅ Fixed | 10 games | Clear All button added |
| B2 | DynamicJigsawWrapper | `game_mechanics/` | ✅ Fixed | 14 games | Auto-submit + coin award + word count badge |
| B3 | SpeakToConfirmOverlay | `game_mechanics/` | ✅ Perfect | 20 games | No changes needed |
| B4 | TypeToConfirmOverlay | `game_mechanics/` | ✅ Solid | 10 games | No changes needed |
| B5 | SpeakingSelfEvaluationControls | `game_mechanics/` | ✅ Perfect | 11 games | No changes needed |
| B6 | BlindDictationWrapper | `game_mechanics/` | ✅ Fixed | 0 (ready) | isPositioned + attempt counter + coins |
| B7 | AdaptiveSmartMixWidget | `game_mechanics/` | ✅ Perfect | All categories | No changes needed |
| B8 | ReadingSelfEvaluationCard | `game_mechanics/` | ✅ Fixed | 4 games | Moved from features → core, +isPositioned, +bonusCoins, +didUpdateWidget, +double-tap guard, Expanded buttons |

### PHASE C: 5 NEW MECHANICS (Built ✅)

| Step | Mechanic | What Built | Cost | Games Affected | Status |
|------|----------|-----------|------|----------------|--------|
| C1 | **ErrorJournalCollector** | Firestore wrong-answer logger + fetch/dismiss/clearAll API | $0 | ALL 100 | ✅ |
| C2 | **SpeedChallengeTimer** | AnimationController countdown bar + green→yellow→red gradient + speed bonus | $0 | 30+ games | ✅ |
| C3 | **EvidenceHighlightWrapper** | Tappable text spans + evidence progress counter + completion animation | $0 | 15+ games | ✅ |
| C4 | **ShadowPlaybackCompare** | Dual waveform visualization + record/compare/self-evaluate flow | $0 | 22 games | ✅ |
| C5 | **ContextSentenceBuilder** | Keyword chip + TextField + word counter + gibberish validation + coin award | $0 | 12 games | ✅ |

### PHASE D: UPGRADE ALL 100 GAMES (Per-Game Tasks 🔲)

#### D1: 🎤 SPEAKING (10 games) — Current 8.2 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 1 | repeatSentence | 9→10 | Add `pronunciationTips` with IPA | Waveform visual: user vs model | ShadowPlaybackCompare | ✅ |
| 2 | speakMissingWord | 8→10 | Add `contextClue` field | Animated blank pulse effect | Anagram fallback | ✅ |
| 3 | situationSpeaking | 9→10 | Add `sampleResponse` field | Timer bar + retry button | SpeedChallengeTimer | ✅ |
| 4 | sceneDescription | 8→10 | Add `keyVocabulary` array (5 words) | Highlight words user said (green/grey) | SpeakingSelfEval | ✅ |
| 5 | yesNoSpeaking | 7→10 | Add `followUpQuestion` field | 2nd screen: explain WHY (3+ words) | TypeToConfirm | ✅ |
| 6 | speakSynonym | 8→10 | Add `acceptedSynonyms` array (3-5) | Show all accepted + pronunciation | ShadowPlaybackCompare | ✅ |
| 7 | dialogueRoleplay | 9→10 | Add `emotionTag` per turn | Emotion indicator for tone | SpeakingSelfEval | ✅ |
| 8 | pronunciationFocus | 8→10 | Add `commonMistakes` per phoneme | Mouth position diagram | ShadowPlaybackCompare | ✅ |
| 9 | speakOpposite | 8→10 | Add `bonusAntonyms` array | Speed mode: 10 words in 30 sec | SpeedChallengeTimer | ✅ |
| 10 | dailyExpression | 8→10 | Add `situationExample` field | Mini-roleplay: use in dialogue | SpeakToConfirm | ✅ |

#### D2: 🔊 LISTENING (10 games) — Current 7.8 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 11 | audioFillBlanks | 8→10 | Add `distractorWords` (similar sounds) | Limit replays to 3 | BlindDictation at high levels | ✅ |
| 12 | audioMultipleChoice | 7→10 | Add `audioTranscript` (shown AFTER) | Max 2 replays + evidence step | EvidenceHighlightWrapper | ✅ |
| 13 | audioSentenceOrder | 8→10 | Add `pauseMarkers` for TTS | Drag-handle sentence cards | Jigsaw wrapper | ✅ |
| 14 | audioTrueFalse | 7→10 | Add `evidenceQuote` field | User TYPE the evidence heard | EvidenceHighlight + TypeToConfirm | ✅ |
| 15 | soundImageMatch | 7→10 | Add `description` per image | 6 images at high levels + timer | SpeedChallengeTimer | ✅ |
| 16 | fastSpeechDecoder | 9→10 | Add `slowVersion` field | Toggle "hear it slow" button | SpeakToConfirm repeat | ✅ |
| 17 | emotionRecognition | 8→10 | Add `emotionScale` (intensity 1-5) | Emotion wheel visual | SpeakToConfirm same emotion | ✅ |
| 18 | detailSpotlight | 8→10 | Add `detailCategory` (name/number/date) | Focus hint BEFORE listening | TypeToConfirm type detail | ✅ |
| 19 | listeningInference | 9→10 | Add `literalMeaning` vs `impliedMeaning` | Show both meanings comparison | ErrorJournalCollector | ✅ |
| 20 | ambientId | 7→10 | Add `locationContext` + `vocabularyWords` | Describe scene in 1 sentence | SpeakToConfirm describe | ✅ |

#### D3: 📖 READING (12 games) — Current 8.2 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 21 | readAndAnswer | 9→10 | Add `passageWordCount` | Read time estimate + highlight | EvidenceHighlightWrapper | ✅ |
| 22 | findWordMeaning | 8→10 | Add `wordInContext` extra example | Type word in own sentence | ContextSentenceBuilder | ✅ |
| 23 | trueFalseReading | 7→10 | Add `evidenceLine` (exact proof) | TAP the line that proves answer | EvidenceHighlightWrapper | ✅ |
| 24 | sentenceOrderReading | 8→10 | Add `transitionWords` highlights | Color-code: First/Then/Finally | Jigsaw (already ✅) | ✅ |
| 25 | readingSpeedCheck | 8→10 | Add `wpm_target` per level | Live WPM counter + personal best | SpeedChallengeTimer | ✅ |
| 26 | guessTitle | 8→10 | Add `whyThisTitle` explanation | Highlight topic sentence after | TypeToConfirm write better title | ✅ |
| 27 | readAndMatch | 8→10 | Add `paragraphTopic` per paragraph | Color-code matches | Jigsaw for matching | ✅ |
| 28 | paragraphSummary | 9→10 | Add `keyPoints` array (3 points) | Checklist: 3 points covered? | TypeToConfirm own summary | ✅ |
| 29 | readingInference | 9→10 | Add `clueWords` array | Highlight clues AFTER answer | EvidenceHighlightWrapper | ✅ |
| 30 | readingConclusion | 9→10 | Add `logicChain` (evidence→conclusion) | Logic flowchart visual | TypeToConfirm explain reasoning | ✅ |
| 31 | clozeTest | 8→10 | Add `wordCategory` (noun/verb/adj) | Part-of-speech hint per blank | Anagram spell the word | ✅ |
| 32 | skimmingScanning | 7→10 | Add `targetInfo` field | Strict 30-sec timer | SpeedChallengeTimer | ✅ |

#### D4: ✍️ WRITING (11 games) — Current 8.5 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 33 | sentenceBuilder | 8→10 | Add `sentenceType` (statement/question) | TYPE sentence from memory after drag | TypeToConfirm | ✅ |
| 34 | completeSentence | 8→10 | Add `grammarFocus` field | Show grammar rule card after | Anagram spell word | ✅ |
| 35 | describeSituation | 9→10 | Add `modelAnswer` (200 words) | Word count minimum indicator | SpeakToConfirm read aloud | ✅ |
| 36 | fixTheSentence | 8→10 | Add `errorType` (spell/grammar/punct) | Highlight error zone | TypeToConfirm full correction | ✅ |
| 37 | shortAnswerWriting | 8→10 | Add `keywordsExpected` array | Keyword checker | ContextSentenceBuilder | ✅ |
| 38 | opinionWriting | 9→10 | Add `structureGuide` | Paragraph structure template | SpeakToConfirm present opinion | ✅ |
| 39 | dailyJournal | 8→10 | Add `promptQuestions` (3 guiding Qs) | Mood selector + word count | SpeakToConfirm summarize | ✅ |
| 40 | summarizeStory | 9→10 | Add `storyKeyEvents` (5 events) | Key events checklist | SpeedChallengeTimer | ✅ |
| 41 | writingEmail | 9→10 | Add `formalityLevel` field | Email template overlay | SpeakToConfirm read aloud | ✅ |
| 42 | correctionWriting | 8→10 | Add `errorCount` field | "X errors remaining" counter | EvidenceHighlightWrapper | ✅ |
| 43 | essayDrafting | 9→10 | Add `thesisStatement` model | Outline mode before writing | TypeToConfirm | ✅ |

#### D5: 🧠 GRAMMAR (19 games) — Current 8.0 → Target 10/10

> **Universal fix**: ALL grammar games get TypeToConfirm (type full sentence after MCQ)

| # | Game | Rating | JSON Fix | Screen Fix | Status |
|---|------|--------|----------|------------|--------|
| 44 | **Grammar Quest** | grammarQuest | ✅ | TypeToConfirm (Lock in rule) | Add `grammarRule` + `ruleExplanation` display |
| 45 | **Sentence Correction** | sentenceCorrection | ✅ | TypeToConfirm (Verbal eval fallback) | Add `errorHighlight` visual underlining |
| 46 | **Word Reorder** | wordReorder | ✅ | TypeToConfirm (Finalize syntax) | Add `structureType` target guide visual |
| 47 | **Tense Mastery** | tenseMastery | ✅ | TypeToConfirm (Timeline lock) | Visual timeline with `timelinePosition` |
| 48 | partsOfSpeech | 10/10 | Add `transformations` | Word family tree visual | ✅ |
| 49 | subjectVerbAgreement | 10/10 | Add `subjectType` | Grammar rule card | ✅ |
| 50 | clauseConnector | 10/10 | Add `connectorCategory` | Syntax highlighting | ✅ |
| 51 | voiceSwap | 10/10 | Add `activeVoice`/`passiveVoice` | Conversion animation | ✅ |
| 52 | questionFormatter | 10/10 | Add `questionType` | Question formula: Aux+S+V+? | ✅ |
| 53 | articleInsertion | 10/10 | Add `articleRule` | Decision tree: countable→a/the/∅ | ✅ |
| 54 | modifierPlacement | 10/10 | Add `modifierType` | Word order slot diagram | ✅ |
| 55 | modalsSelection | 10/10 | Add `modalMeaning` | Modal scale: might→must | ✅ |
| 56 | prepositionChoice | 10/10 | Add `prepositionCategory` | Preposition diagram: in/on/at | ✅ |
| 57 | pronounResolution | 10/10 | Add `referentHighlight` | Arrow: pronoun → referent noun | ✅ |
| 58 | punctuationMastery | 10/10 | Add `punctuationRule` | Meaning visual: comma=pause etc | ✅ |
| 59 | relativeClauses | 10/10 | Add `clauseType` (defining/non) | With/without commas comparison | ✅ |
| 60 | conditionals | 10/10 | Add `conditionalType` (0/1/2/3) | Probability meter visual | ✅ |
| 61 | conjunctions | 10/10 | Add `conjunctionPurpose` | FANBOYS chart | ✅ |
| 62 | directIndirectSpeech | 10/10 | Add `changesList` | Side-by-side: changes highlighted | ✅ |

#### D6: 💡 VOCABULARY (12 games) — Current 8.1 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 63 | flashcards | 10/10 | Add `usageExample` 2nd example | After flip: spell it + say it | Anagram + SpeakToConfirm | ✅ |
| 64 | synonymSearch | 8→10 | Add `nuanceDifference` | Nuance scale visual | ContextSentenceBuilder | ✅ |
| 65 | antonymSearch | 8→10 | Add `gradientScale` | Word intensity slider | SpeakToConfirm both words | ✅ |
| 66 | contextClues | 9→10 | Add `clueType` | Highlight context clue words | EvidenceHighlightWrapper | ✅ |
| 67 | phrasalVerbs | 8→10 | Add `literalVsFigurative` | Literal vs phrasal side-by-side | ContextSentenceBuilder | ✅ |
| 68 | idioms | 8→10 | Add `origin` story | Origin card after answer | SpeakToConfirm in sentence | ✅ |
| 69 | academicWord | 8→10 | Add `academicField` + `collocations` | Academic paragraph context | TypeToConfirm write sentence | ✅ |
| 70 | topicVocab | 8→10 | Add `relatedWords` network | Word web mind map | Anagram spell words | ✅ |
| 71 | wordFormation | 8→10 | Add `familyTree` (act→action→active) | Full word family tree | TypeToConfirm each form | ✅ |
| 72 | prefixSuffix | 8→10 | Add `meaningBreakdown` | Color-coded prefix/root/suffix | Anagram build word | ✅ |
| 73 | collocations | 8→10 | Add `wrongCollocations` | Show common WRONG pairs | ContextSentenceBuilder | ✅ |
| 74 | contextualUsage | 9→10 | Add `registerLevel` | Formality meter | SpeakToConfirm | ✅ |

#### D7: 🗣️ ACCENT (12 games) — Current 8.1 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 75 | minimalPairs | 8→10 | ✅ Added `mouthPosition` | ✅ Mouth/tongue diagram | ✅ ShadowPlaybackCompare | ✅ |
| 76 | intonationMimic | 8→10 | ✅ Added `emotionContext` | ✅ `IntonationCurve` visualizer | ✅ SpeakToConfirm | ✅ |
| 77 | syllableStress | 8→10 | ✅ Added `stressIndex` | ✅ `SyllableBlock` visualizer | ✅ SpeakToConfirm | ✅ |
| 78 | wordLinking | 8→10 | ✅ Added `linkingType` | ✅ Linking arrows between words | ✅ ShadowPlaybackCompare | ✅ |
| 79 | shadowingChallenge | 9→10 | Add `speedLevel` (0.75x-1.25x) | Speed slider progression | ShadowPlaybackCompare | 🔲 |
| 80 | vowelDistinction | 8→10 | Add `vowelChart` position | Vowel trapezoid chart | SpeakToConfirm | 🔲 |
| 81 | consonantClarity | 8→10 | Add `voicing` + `airflow` | Throat vibration indicator | ShadowPlaybackCompare | 🔲 |
| 82 | pitchPatternMatch | 8→10 | Add `emotionContext` | Same words + different pitch demo | SpeakToConfirm | 🔲 |
| 83 | speedVariance | 8→10 | Add `naturalSpeed` vs `clearSpeed` | Toggle natural/clear | SpeedChallengeTimer | 🔲 |
| 84 | dialectDrill | 8→10 | Add `dialectRegion` | Map of dialect region | ShadowPlaybackCompare | 🔲 |
| 85 | connectedSpeech | 8→10 | Add `phenomenonType` | Written vs spoken side-by-side | ShadowPlaybackCompare | 🔲 |
| 86 | pitchModulation | 8→10 | Add `meaningShift` | 2 meanings same sentence | SpeakToConfirm both | 🔲 |

#### D8: 🎭 ROLEPLAY (10 games) — Current 8.1 → Target 10/10

> **Universal fix**: ALL roleplay games get SpeakToConfirm (SAY your response)

| # | Game | Rating | JSON Fix | Screen Fix | Status |
|---|------|--------|----------|------------|--------|
| 87 | branchingDialogue | 9→10 | Add `consequencePreview` | Relationship meter (polite↔rude) | 🔲 |
| 88 | situationalResponse | 8→10 | Add `culturalNote` | Formality gauge | 🔲 |
| 89 | jobInterview | 9→10 | Add `interviewerReaction` | Face expression change | 🔲 |
| 90 | medicalConsult | 8→10 | Add `medicalVocab` array | Body diagram for symptoms | 🔲 |
| 91 | gourmetOrder | 8→10 | Add `menuItems` with prices | Restaurant menu UI | 🔲 |
| 92 | travelDesk | 8→10 | Add `travelDocuments` context | Airport/hotel counter visual | 🔲 |
| 93 | conflictResolver | 8→10 | Add `escalationLevel` | Tension meter visual | 🔲 |
| 94 | elevatorPitch | 8→10 | Add `timeLimit` (30/60/90s) | Countdown + word counter | 🔲 |
| 95 | socialSpark | 8→10 | Add `socialContext` | Scene illustration | 🔲 |
| 96 | emergencyHub | 7→10 | Add `urgencyLevel` + richer content | Emergency level indicator | 🔲 |

#### D9: 🏆 ELITE MASTERY (4 games) — Current 8.3 → Target 10/10

| # | Game | Rating | JSON Fix | Screen Fix | Mechanic To Add | Status |
|---|------|--------|----------|------------|----------------|--------|
| 97 | storyBuilder | 9→10 | Add `plotStructure` guide | Story arc diagram | SpeakToConfirm narrate | 🔲 |
| 98 | idiomMatch | 8→10 | Add `idiomOrigin` + `visualMetaphor` | Literal vs figurative visual | ContextSentenceBuilder | 🔲 |
| 99 | speedSpelling | 8→10 | Add `difficultyTier` (common→rare) | Letter slots + streak bonus | SpeedChallengeTimer + Anagram | 🔲 |
| 100 | accentShadowing | 8→10 | Add `targetAccent` (RP/GA) | Waveform comparison visual | ShadowPlaybackCompare | 🔲 |

### PHASE E: V1 LAUNCH (Final Steps 🔲)

| Step | Task | Status |
|------|------|--------|
| E1 | Full regression test — no crash on any screen | 🔲 |
| E2 | Play Store listing (title, description, keywords) | 🔲 |
| E3 | 8 screenshots created | 🔲 |
| E4 | Privacy policy URL | 🔲 |
| E5 | Release APK/AAB built | 🔲 |
| E6 | Submit to Play Store | 🔲 |

---

## FREE-OF-COST VERIFICATION ✅

| Service | Package | Cost |
|---------|---------|------|
| Speech Recognition | `speech_to_text` (on-device) | $0 |
| Text-to-Speech | `flutter_tts` (on-device) | $0 |
| Translation | `google_mlkit_translation` | $0 |
| Text Recognition | `google_mlkit_text_recognition` | $0 |
| Handwriting | `google_mlkit_digital_ink_recognition` | $0 |
| Auth | `firebase_auth` | $0 (10K free) |
| Database | `cloud_firestore` | $0 (1GB free) |
| Ads | `google_mobile_ads` | $0 (EARNS money) |
| Analytics | `firebase_analytics` | $0 |
| Crash Reports | `firebase_crashlytics` | $0 |
| **ALL 14 MECHANICS** | Flutter widgets (on-device) | **$0** |
| **TOTAL** | | **$0/month** |

---

## GAME-BY-MECHANIC MAP (Which mechanic each game uses)

> **Legend**: ✅ = Currently using | 🔲 = To add in Phase D | — = Not applicable

### 🎤 SPEAKING (10 games)

| # | Game | SpeakingSelfEval | ShadowPlayback | SpeedTimer | ErrorJournal | ContextBuilder |
|---|------|:---:|:---:|:---:|:---:|:---:|
| 1 | repeatSentence | ✅ | 🔲 | — | 🔲 | — |
| 2 | speakMissingWord | ✅ | — | — | 🔲 | — |
| 3 | situationSpeaking | ✅ | — | 🔲 | 🔲 | — |
| 4 | sceneDescriptionSpeaking | ✅ | — | — | 🔲 | — |
| 5 | yesNoSpeaking | ✅ | — | — | 🔲 | — |
| 6 | speakSynonym | ✅ | 🔲 | — | 🔲 | — |
| 7 | dialogueRoleplay | ✅ | — | — | 🔲 | — |
| 8 | pronunciationFocus | ✅ | 🔲 | — | 🔲 | — |
| 9 | speakOpposite | ✅ | — | 🔲 | 🔲 | — |
| 10 | dailyExpression | ✅ | — | — | 🔲 | — |

### 👂 LISTENING (10 games)

| # | Game | SpeakToConfirm | EvidenceHighlight | SpeedTimer | BlindDictation | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|:---:|
| 11 | audioFillBlanks | ✅ | 🔲 | 🔲 | ✅ | ✅ |
| 12 | audioMultipleChoice | 🔲 | ✅ | 🔲 | 🔲 | ✅ |
| 13 | audioSentenceOrder | 🔲 | 🔲 | 🔲 | 🔲 | ✅ |
| 14 | audioTrueFalse | ✅ | ✅ | 🔲 | 🔲 | ✅ |
| 15 | soundImageMatch | ✅ | 🔲 | ✅ | 🔲 | ✅ |
| 16 | fastSpeechDecoder | ✅ | — | 🔲 | — | ✅ |
| 17 | emotionRecognition | ✅ | — | — | — | ✅ |
| 18 | detailSpotlight | — | — | — | — | ✅ |
| 19 | listeningInference | — | — | — | — | ✅ |
| 20 | ambientId | ✅ | — | — | — | ✅ |

### 📖 READING (12 games)

| # | Game | ReadingSelfEval | SpeakToConfirm | TypeToConfirm | EvidenceHighlight | SpeedTimer | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|:---:|:---:|
| 21 | readAndAnswer | — | — | — | 🔲 | — | 🔲 |
| 22 | findWordMeaning | — | — | — | — | — | 🔲 |
| 23 | trueFalseReading | — | ✅ | — | 🔲 | — | 🔲 |
| 24 | sentenceOrderReading | — | — | — | — | — | 🔲 |
| 25 | readingSpeedCheck | ✅ | — | — | — | 🔲 | 🔲 |
| 26 | guessTitle | — | — | — | — | — | 🔲 |
| 27 | readAndMatch | — | ✅ | — | — | — | 🔲 |
| 28 | paragraphSummary | ✅ | — | — | — | — | 🔲 |
| 29 | readingInference | ✅ | — | — | 🔲 | — | 🔲 |
| 30 | readingConclusion | ✅ | — | — | — | — | 🔲 |
| 31 | clozeTest | — | — | ✅ | — | — | 🔲 |
| 32 | skimmingScanning | — | — | — | — | 🔲 | 🔲 |

### ✍️ WRITING (11 games)

| # | Game | TypeToConfirm | ContextBuilder | BlindDictation | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|
| 33 | sentenceBuilder | — | — | — | 🔲 |
| 34 | completeSentence | — | — | — | 🔲 |
| 35 | describeSituationWriting | — | — | — | 🔲 |
| 36 | fixTheSentence | ✅ | — | — | 🔲 |
| 37 | shortAnswerWriting | — | 🔲 | — | 🔲 |
| 38 | opinionWriting | ✅ | — | — | 🔲 |
| 39 | dailyJournal | — | — | — | 🔲 |
| 40 | summarizeStoryWriting | ✅ | — | — | 🔲 |
| 41 | writingEmail | — | — | — | 🔲 |
| 42 | correctionWriting | — | — | — | 🔲 |
| 43 | essayDrafting | ✅ | — | — | 🔲 |

### 📐 GRAMMAR (19 games)

| # | Game | Jigsaw | Anagram | TypeToConfirm | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|
| 44 | grammarQuest | ✅ | — | — | 🔲 |
| 45 | sentenceCorrection | — | — | ✅ | 🔲 |
| 46 | wordReorder | — | — | — | 🔲 |
| 47 | tenseMastery | — | ✅ | — | 🔲 |
| 48 | partsOfSpeech | ✅ | — | — | 🔲 |
| 49 | subjectVerbAgreement | ✅ | — | — | 🔲 |
| 50 | clauseConnector | ✅ | — | — | 🔲 |
| 51 | voiceSwap | — | — | ✅ | 🔲 |
| 52 | questionFormatter | ✅ | — | — | 🔲 |
| 53 | articleInsertion | ✅ | — | — | 🔲 |
| 54 | modifierPlacement | ✅ | — | — | 🔲 |
| 55 | modalsSelection | ✅ | — | — | 🔲 |
| 56 | prepositionChoice | ✅ | — | — | 🔲 |
| 57 | pronounResolution | ✅ | — | — | 🔲 |
| 58 | punctuationMastery | — | — | ✅ | 🔲 |
| 59 | relativeClauses | ✅ | — | — | 🔲 |
| 60 | conditionals | — | — | ✅ | 🔲 |
| 61 | conjunctions | ✅ | — | — | 🔲 |
| 62 | directIndirectSpeech | — | — | ✅ | 🔲 |

### 📚 VOCABULARY (12 games)

| # | Game | Anagram | ContextBuilder | SpeedTimer | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|
| 63 | flashcards | — | — | — | 🔲 |
| 64 | synonymSearch | ✅ | 🔲 | — | 🔲 |
| 65 | antonymSearch | ✅ | — | — | 🔲 |
| 66 | contextClues | ✅ | — | — | 🔲 |
| 67 | phrasalVerbs | ✅ | 🔲 | — | 🔲 |
| 68 | idioms | ✅ | — | — | 🔲 |
| 69 | academicWord | ✅ | — | — | 🔲 |
| 70 | topicVocab | — | — | — | 🔲 |
| 71 | wordFormation | — | — | — | 🔲 |
| 72 | prefixSuffix | — | — | — | 🔲 |
| 73 | collocations | ✅ | 🔲 | — | 🔲 |
| 74 | contextualUsage | ✅ | — | — | 🔲 |

### 🗣️ ACCENT (12 games)

| # | Game | AccentSelfEval | ShadowPlayback | SpeedTimer | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|
| 75 | minimalPairs | ✅ | 🔲 | — | 🔲 |
| 76 | intonationMimic | ✅ | 🔲 | — | 🔲 |
| 77 | syllableStress | ✅ | — | — | 🔲 |
| 78 | wordLinking | ✅ | 🔲 | — | 🔲 |
| 79 | shadowingChallenge | ✅ | 🔲 | — | 🔲 |
| 80 | vowelDistinction | ✅ | — | — | 🔲 |
| 81 | consonantClarity | ✅ | 🔲 | — | 🔲 |
| 82 | pitchPatternMatch | ✅ | — | — | 🔲 |
| 83 | speedVariance | ✅ | — | 🔲 | 🔲 |
| 84 | dialectDrill | ✅ | 🔲 | — | 🔲 |
| 85 | connectedSpeech | ✅ | 🔲 | — | 🔲 |
| 86 | pitchModulation | ✅ | — | — | 🔲 |

### 🎭 ROLEPLAY (10 games)

| # | Game | SpeakToConfirm | SpeedTimer | ErrorJournal |
|---|------|:---:|:---:|:---:|
| 87 | branchingDialogue | ✅ | — | 🔲 |
| 88 | situationalResponse | ✅ | — | 🔲 |
| 89 | jobInterview | ✅ | — | 🔲 |
| 90 | medicalConsult | ✅ | — | 🔲 |
| 91 | gourmetOrder | ✅ | — | 🔲 |
| 92 | travelDesk | ✅ | — | 🔲 |
| 93 | conflictResolver | ✅ | — | 🔲 |
| 94 | elevatorPitch | ✅ | — | 🔲 |
| 95 | socialSpark | ✅ | — | 🔲 |
| 96 | emergencyHub | ✅ | — | 🔲 |

### 🏆 ELITE MASTERY (4 games)

| # | Game | SpeakToConfirm | Anagram | ContextBuilder | SpeedTimer | ErrorJournal |
|---|------|:---:|:---:|:---:|:---:|:---:|
| 97 | storyBuilder | — | — | — | — | 🔲 |
| 98 | idiomMatch | ✅ | — | 🔲 | — | 🔲 |
| 99 | speedSpelling | — | — | — | 🔲 | 🔲 |
| 100 | accentShadowing | ✅ | — | — | — | 🔲 |

### 📊 DAILY CHALLENGES (2 mini-games)

| # | Game | Anagram | Jigsaw | ErrorJournal |
|---|------|:---:|:---:|:---:|
| — | wordMixer | ✅ | — | 🔲 |
| — | wordSnap | — | ✅ | 🔲 |

### MECHANIC USAGE SUMMARY

| Mechanic | Currently In | To Add (Phase D) | Total After |
|----------|:---:|:---:|:---:|
| ErrorJournalCollector (C1) | 0 | **100** | 100 |
| SpeakingSelfEvaluationControls (B5) | 11 | 0 | 11 |
| SpeakToConfirmOverlay (B3) | 20 | 0 | 20 |
| DynamicJigsawWrapper (B2) | 14 | 0 | 14 |
| DynamicAnagramWrapper (B1) | 10 | 0 | 10 |
| TypeToConfirmOverlay (B4) | 10 | 0 | 10 |
| AccentSelfEvalPanel (wrapper→B5) | 11 | 0 | 11 |
| ReadingSelfEvaluationCard (B8) | 4 | 0 | 4 |
| ShadowPlaybackCompare (C4) | 0 | **11** | 11 |
| SpeedChallengeTimer (C2) | 0 | **8** | 8 |
| EvidenceHighlightWrapper (C3) | 0 | **7** | 7 |
| ContextSentenceBuilder (C5) | 0 | **6** | 6 |
| BlindDictationWrapper (B6) | 0 | **2** | 2 |
| AdaptiveSmartMixWidget (B7) | 1 | 0 | 1 |

---

## PROGRESS SUMMARY

| Phase | Tasks | Done | Remaining |
|-------|-------|------|-----------|
| A: Foundation | 13 | ✅ 13 | 0 |
| B: Existing Mechanics | 8 | ✅ 8 (4 fixed) | 0 |
| C: New Mechanics | 5 | ✅ 5 | 0 |
| D: Upgrade 100 Games | 100 | 🔲 15 | 85 |
| E: Launch | 6 | 🔲 0 | 6 |
| **TOTAL** | **132** | **41 done** | **91 remaining** |

**Current Rating: 8.1/10 → After all phases: 10/10**
# Vowl Game Optimization Tracker

Track the progress of UI and learning optimizations across all 122 game modules.

## Speaking (10)
- [ ] Repeat Sentence (`repeatSentence`)
- [ ] Speak Missing Word (`speakMissingWord`)
- [ ] Situation Speaking (`situationSpeaking`)
- [ ] Scene Description (`sceneDescriptionSpeaking`)
- [ ] Yes/No Speaking (`yesNoSpeaking`)
- [ ] Speak Synonym (`speakSynonym`)
- [ ] Dialogue Roleplay (`dialogueRoleplay`)
- [ ] Pronunciation Focus (`pronunciationFocus`)
- [ ] Speak Opposite (`speakOpposite`)
- [x] ✅ Daily Expression (`dailyExpression`)

## Listening (10)
- [ ] Audio Fill Blanks (`audioFillBlanks`)
- [ ] Audio Multiple Choice (`audioMultipleChoice`)
- [ ] Audio Sentence Order (`audioSentenceOrder`)
- [ ] Audio True/False (`audioTrueFalse`)
- [ ] Sound Image Match (`soundImageMatch`)
- [ ] Fast Speech Decoder (`fastSpeechDecoder`)
- [ ] Emotion Recognition (`emotionRecognition`)
- [ ] Detail Spotlight (`detailSpotlight`)
- [ ] Listening Inference (`listeningInference`)
- [x] ✅ Ambient ID (`ambientId`)

## Reading (12)
- [ ] Read and Answer (`readAndAnswer`)
- [ ] Find Word Meaning (`findWordMeaning`)
- [ ] True/False Reading (`trueFalseReading`)
- [ ] Sentence Order Reading (`sentenceOrderReading`)
- [ ] Reading Speed Check (`readingSpeedCheck`)
- [ ] Guess Title (`guessTitle`)
- [ ] Read and Match (`readAndMatch`)
- [ ] Paragraph Summary (`paragraphSummary`)
- [ ] Reading Inference (`readingInference`)
- [ ] Reading Conclusion (`readingConclusion`)
- [x] ✅ Cloze Test (`clozeTest`)
- [ ] Skimming/Scanning (`skimmingScanning`)

## Writing (11)
- [x] ✅ Sentence Builder (`sentenceBuilder`)
- [x] ✅ Complete Sentence (`completeSentence`)
- [x] ✅ Describe Situation (`describeSituationWriting`)
- [x] ✅ Fix The Sentence (`fixTheSentence`)
- [x] ✅ Short Answer (`shortAnswerWriting`)
- [x] ✅ Opinion Writing (`opinionWriting`)
- [x] ✅ Daily Journal (`dailyJournal`)
- [x] ✅ Summarize Story (`summarizeStoryWriting`)
- [x] ✅ Writing Email (`writingEmail`)
- [x] ✅ Correction Writing (`correctionWriting`)
- [x] ✅ Essay Drafting (`essayDrafting`)

## Grammar (19)
- [ ] Grammar Quest (`grammarQuest`)
- [ ] Sentence Correction (`sentenceCorrection`)
- [ ] Word Reorder (`wordReorder`)
- [ ] Tense Mastery (`tenseMastery`)
- [ ] Parts of Speech (`partsOfSpeech`)
- [ ] Subject-Verb Agreement (`subjectVerbAgreement`)
- [ ] Clause Connector (`clauseConnector`)
- [ ] Voice Swap (`voiceSwap`)
- [ ] Question Formatter (`questionFormatter`)
- [x] ✅ Article Insertion (`articleInsertion`)
- [ ] Modifier Placement (`modifierPlacement`)
- [ ] Modals Selection (`modalsSelection`)
- [ ] Preposition Choice (`prepositionChoice`)
- [ ] Pronoun Resolution (`pronounResolution`)
- [ ] Punctuation Mastery (`punctuationMastery`)
- [ ] Relative Clauses (`relativeClauses`)
- [ ] Conditionals (`conditionals`)
- [ ] Conjunctions (`conjunctions`)
- [ ] Direct/Indirect Speech (`directIndirectSpeech`)

## Vocabulary (12)
- [ ] Flashcards (`flashcards`)
- [ ] Synonym Search (`synonymSearch`)
- [ ] Antonym Search (`antonymSearch`)
- [ ] Context Clues (`contextClues`)
- [ ] Phrasal Verbs (`phrasalVerbs`)
- [ ] Idioms (`idioms`)
- [x] ✅ Academic Word (`academicWord`)
- [ ] Topic Vocab (`topicVocab`)
- [ ] Word Formation (`wordFormation`)
- [ ] Prefix/Suffix (`prefixSuffix`)
- [ ] Collocations (`collocations`)
- [ ] Contextual Usage (`contextualUsage`)

## Accent (12)
- [x] ✅ Minimal Pairs (`minimalPairs`)
- [x] ✅ Intonation Mimic (`intonationMimic`)
- [x] ✅ Syllable Stress (`syllableStress`)
- [x] ✅ Word Linking (`wordLinking`)
- [x] ✅ Shadowing Challenge (`shadowingChallenge`)
- [x] ✅ Vowel Distinction (`vowelDistinction`)
- [x] ✅ Consonant Clarity (`consonantClarity`)
- [x] ✅ Pitch Pattern Match (`pitchPatternMatch`)
- [x] ✅ Speed Variance (`speedVariance`)
- [x] ✅ Dialect Drill (`dialectDrill`)
- [x] ✅ Connected Speech (`connectedSpeech`)
- [x] ✅ Pitch Modulation (`pitchModulation`)

## Roleplay (10)
- [x] ✅ Branching Dialogue (`branchingDialogue`)
- [x] ✅ Situational Response (`situationalResponse`)
- [x] ✅ Job Interview (`jobInterview`)
- [ ] Medical Consult (`medicalConsult`)
- [ ] Gourmet Order (`gourmetOrder`)
- [ ] Travel Desk (`travelDesk`)
- [ ] Conflict Resolver (`conflictResolver`)
- [ ] Elevator Pitch (`elevatorPitch`)
- [ ] Social Spark (`socialSpark`)
- [ ] Emergency Hub (`emergencyHub`)

## Elite Mastery (4)
- [x] ✅ Story Builder (`storyBuilder`)
- [x] ✅ Idiom Match (`idiomMatch`)
- [x] ✅ Speed Spelling (`speedSpelling`)
- [x] ✅ Accent Shadowing (`accentShadowing`)

## Kids Curriculum (22)
- [ ] Alphabet
- [ ] Animals
- [ ] Numbers
- [ ] Colors
- [ ] Fruits
- [ ] Shapes
- [ ] Body Parts
- [ ] Family
- [ ] Food
- [ ] Clothing
- [ ] Nature
- [ ] Transport
- [ ] Emotions
- [ ] School
- [ ] Home
- [ ] Opposites
- [ ] Verbs
- [ ] Prepositions
- [ ] Seasons
- [ ] Weather
- [ ] Jobs
- [ ] Time

## Accent Category: Progression & UX Strategy (Implemented)
*Status: Complete*

**Objective:** Prevent choice paralysis across the 12 Accent games and provide structured phonetic progression.

- [x] ✅ **Implement "Daily Accent Mix" (Core Loop):** Vowl auto-selects 3 games daily (e.g., 1 Foundation, 1 Rhythm, 1 Flow) instead of forcing users to choose from a 12-game list. *Upgraded to Adaptive Smart Engine that picks weakest games.*
- [x] ✅ **Design "Skill Radar" (Progress Tracker):** Create a 4-point Radar Chart (Pronunciation, Rhythm, Intonation, Flow) to visually track mastery across all 12 games.
- [x] ✅ **Categorize Games into Tiers (Backend/UI Mapping):**
  - **Tier 1 (Foundations):** Vowel Distinction, Consonant Clarity, Minimal Pairs
  - **Tier 2 (Rhythm):** Syllable Stress, Pitch Modulation, Speed Variance
  - **Tier 3 (Flow):** Word Linking, Connected Speech, Intonation Mimic, Pitch Pattern Match
  - **Tier 4 (Elite):** Shadowing Challenge, Dialect Drill
- [x] ✅ **Build "Practice Library":** Moved the raw list of 12 games into a secondary list below the dashboard for users who want targeted practice.


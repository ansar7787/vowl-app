# VOWL Game-by-Game Interaction Tracker (125 Games) - DYNAMIC UI EDITION

**Purpose:** This is the master checklist for upgrading every single game using the **Dynamic UI Strategy** (Jigsaw, Anagrams, Dictation). 
**Rule:** We DO NOT change the JSON data. We dynamically split the correct answer string on the UI side to create new mechanics.

### ⚠️ DEEP CHECK: EDGE CASES TO REMEMBER
While building the Dynamic UI wrappers, apply these safety rules to prevent bugs:
1. **The "Space" Rule (Anagrams):** If a Vocabulary answer contains a space (e.g., "give up"), DO NOT use Dynamic Anagram (splitting by letter). Sorting a blank space tile is bad UX. **Fallback:** Use Dynamic Jigsaw (split by word) instead.
2. **The "Long Paragraph" Rule (Dictation):** If a Listening answer is a massive paragraph, DO NOT use Blind Dictation (users hate typing long paragraphs on phones). **Fallback:** Use Dynamic Jigsaw to let them order the sentences, or keep it MCQ.
3. **Punctuation Stripping:** When doing Dynamic Jigsaw, strip out trailing commas/periods from the JSON strings so they don't look weird on the draggable tiles.

### 🚨 LOOPHOLE CHECKS (ANTI-CHEAT)
Users will try to cheat to get coins faster. Close these loopholes in your UI wrappers:
1. **The Capitalization Exploit (Jigsaw):** If you split a sentence, users instantly know the word with a Capital Letter goes first. **Fix:** `.toLowerCase()` all tiles on the screen so they have to actually read the grammar to know the first word.
2. **The Spam-Guessing Exploit (Anagram):** Users might just rapidly tap all letter tiles randomly until the word builds itself. **Fix:** Do not auto-assemble on tap. Force them to hit a "Submit" button to check the whole word, or deduct points/hearts for every wrong tile tap.
3. **The Gibberish Exploit (Dictation):** Users might type random keyboard mashing instead of listening to the audio. **Fix:** Route all Blind Dictation text fields through your existing `GibberishDetectorService`.
4. **The STT Frustration Loophole (SpeakToConfirm):** If Voice Recognition fails to hear them 3 times, they get stuck and uninstall the app. **Fix:** Always provide a "Manual Self-Evaluation" bypass (Nailed It / Needs Work) if STT fails 3 times in a row.

---

## 1. VOCABULARY (12 Games)
*Goal: Use Dynamic Anagrams so users scramble letters to spell words, instead of typing on a keyboard.*
- [x] 1. Flashcards (Action: Verify Flip/Swipe is working)
- [x] 2. Synonym Search (Action: Implement **Dynamic Anagram** - scramble synonym letters)
- [x] 3. Antonym Search (Action: Implement **Dynamic Anagram** - scramble antonym letters)
- [x] 4. Context Clues (Action: Implement **Dynamic Anagram** for the missing word)
- [x] 5. Phrasal Verbs (Action: Implement **Dynamic Jigsaw** - reorder the verb + preposition)
- [x] 6. Idioms (Action: Implement **Dynamic Jigsaw** - reorder the idiom words)
- [x] 7. Academic Word (Action: Implement **Dynamic Anagram** - scramble the academic word)
- [x] 8. Topic Vocab (Action: Verify Drag is working)
- [x] 9. Word Formation (Action: Verify Morph is working)
- [x] 10. Prefix Suffix (Action: Verify Gesture is working)
- [x] 11. Collocations (Action: Implement **Dynamic Jigsaw** - reorder the paired words)
- [x] 12. Contextual Usage (Action: Implement **Dynamic Jigsaw** - reorder the context sentence)

## 2. LISTENING (10 Games)
*Goal: Use Blind Dictation (hide MCQ options) to force true listening comprehension.*
- [x] 1. Audio Fill Blanks (Action: Verify Typing is working)
- [x] 2. Audio Multiple Choice (Action: Implement **Blind Dictation** - hide options, force user to type answer)
- [x] 3. Audio Sentence Order (Action: Verify Reorder is working)
- [x] 4. Audio True/False (Action: Implement `SpeakToConfirmOverlay` - read statement aloud)
- [x] 5. Sound Image Match (Action: Implement `SpeakToConfirmOverlay` - say image name)
- [x] 6. Fast Speech Decoder (Action: Keep as fast MCQ for speed round)
- [x] 7. Emotion Recognition (Action: Keep as MCQ for nuance/context)
- [x] 8. Detail Spotlight (Action: Implement **Blind Dictation** - hide options, force user to type detail)
- [x] 9. Listening Inference (Action: Implement **Blind Dictation** - hide options, type conclusion)
- [x] 10. Ambient ID (Action: Keep as MCQ for speed)

## 3. READING (12 Games)
*Goal: Use Dynamic Jigsaw for sentences, and SpeakToConfirm for long paragraphs.*
- [x] 1. Read and Answer (Action: Implement `SpeakToConfirmOverlay`)
- [x] 2. Find Word Meaning (Action: Implement **Dynamic Anagram** - spell the meaning word)
- [x] 3. True/False Reading (Action: Implement `SpeakToConfirmOverlay`)
- [x] 4. Sentence Order (Action: Verify Reorder is working)
- [x] 5. Reading Speed Check (Action: Verify Timed scroll)
- [x] 6. Guess Title (Action: Implement **Dynamic Jigsaw** - rebuild the title)
- [x] 7. Read and Match (Action: Implement `SpeakToConfirmOverlay`)
- [x] 8. Paragraph Summary (Action: Verify Condenser is working)
- [x] 9. Reading Inference (Action: Implement `SpeakToConfirmOverlay`)
- [x] 10. Reading Conclusion (Action: Implement `SpeakToConfirmOverlay`)
- [x] 11. Cloze Test (Action: Verify Typing is working)
- [x] 12. Skimming Scanning (Action: Verify Search/Scroll)

## 4. WRITING (11 Games)
*Goal: Ensure anti-gibberish checks are active. No overlays needed.*
- [x] 1. Sentence Builder (Action: Verify Drag/Jigsaw)
- [x] 2. Complete Sentence (Action: Verify Typing + Drag)
- [x] 3. Describe Situation (Action: Verify Free writing + Gibberish Check)
- [x] 4. Fix the Sentence (Action: Verify Typing)
- [x] 5. Short Answer (Action: Verify Typing + Gibberish Check)
- [x] 6. Opinion Writing (Action: Verify Free writing)
- [x] 7. Daily Journal (Action: Verify Free writing + Gibberish Check)
- [x] 8. Summarize Story (Action: Verify Free writing)
- [x] 9. Writing Email (Action: Verify Typing)
- [x] 10. Essay Outline (Action: Verify Free writing)
- [x] 11. Writing Inference (Action: Verify Typing)

## 5. GRAMMAR (19 Games)
*Goal: Use Dynamic Jigsaw heavily. Dragging words forces users to internalize grammar rules.*
- [x] 1. Grammar Quest (Action: Implement **Dynamic Jigsaw** - rebuild the full sentence)
- [x] 2. Sentence Correction (Action: Verify Type-to-confirm is active)
- [x] 3. Word Reorder (Action: Verify Reorder is active)
- [x] 4. Tense Mastery (Action: Implement **Dynamic Anagram** - spell the verb tense)
- [x] 5. Parts of Speech (Action: Implement **Dynamic Jigsaw**)
- [x] 6. Subject-Verb Agreement (Action: Implement **Dynamic Jigsaw**)
- [x] 7. Clause Connector (Action: Implement **Dynamic Jigsaw** - place the connector)
- [x] 8. Voice Swap (Action: Verify Type-to-confirm is active)
- [x] 9. Question Formatter (Action: Implement **Dynamic Jigsaw**)
- [x] 10. Article Insertion (Action: Implement **Dynamic Jigsaw**)
- [x] 11. Modifier Placement (Action: Implement **Dynamic Jigsaw**)
- [x] 12. Modals Selection (Action: Implement **Dynamic Jigsaw**)
- [x] 13. Preposition Choice (Action: Implement **Dynamic Jigsaw**)
- [x] 14. Pronoun Resolution (Action: Implement **Dynamic Jigsaw**)
- [x] 15. Punctuation Mastery (Action: Implement `TypeToConfirmOverlay` - punctuation requires typing)
- [x] 16. Relative Clauses (Action: Implement **Dynamic Jigsaw**)
- [x] 17. Conditionals (Action: Verify Type-to-confirm is active)
- [x] 18. Conjunctions (Action: Implement **Dynamic Jigsaw**)
- [x] 19. Direct/Indirect Speech (Action: Verify Type-to-confirm is active)

## 6. SPEAKING (10 Games)
*Goal: Ensure manual self-evaluation is active for robust UX.*
- [x] 1. Repeat Sentence (Action: Verify Voice + Self-eval)
- [x] 2. Speak Missing Word (Action: Verify Voice + Magnet)
- [x] 3. Situation Speaking (Action: Verify Voice + Fog scrub)
- [x] 4. Scene Description (Action: Verify Voice + Radar)
- [x] 5. Yes/No Speaking (Action: Verify Voice + Tilt)
- [x] 6. Speak Synonym (Action: Verify Voice + Watering)
- [x] 7. Dialogue Roleplay (Action: Verify Voice)
- [x] 8. Pronunciation Focus (Action: Verify Voice + Highlight)
- [x] 9. Speak Opposite (Action: Verify Voice + EM trigger)
- [x] 10. Daily Expression (Action: Verify Voice + Scratch)

## 7. ACCENT (12 Games)
*Goal: Ensure audio recording and playback is flawless.*
- [x] 1. Minimal Pairs (Action: Verify Voice + Listen)
- [x] 2. Intonation Mimic (Action: Verify Voice)
- [x] 3. Syllable Stress (Action: Verify Tap + Listen)
- [x] 4. Word Linking (Action: Verify Gesture + Link)
- [x] 5. Shadowing Challenge (Action: Verify Voice)
- [x] 6. Vowel Distinction (Action: Verify Voice + Listen)
- [x] 7. Consonant Clarity (Action: Verify Voice + Listen)
- [x] 8. Pitch Pattern Match (Action: Verify Listen + Match)
- [x] 9. Speed Variance (Action: Verify Listen + Adjust)
- [x] 10. Dialect Drill (Action: Verify Listen + Choose)
- [x] 11. Connected Speech (Action: Verify Voice + Listen)
- [x] 12. Pitch Modulation (Action: Verify Voice)

## 8. ROLEPLAY (10 Games)
*Goal: KEEP SpeakToConfirm. Real-world conversations must be spoken.*
- [x] 1. Branching Dialogue (Action: Implement `SpeakToConfirmOverlay`)
- [x] 2. Situational Response (Action: Implement `SpeakToConfirmOverlay`)
- [x] 3. Job Interview (Action: Implement `SpeakToConfirmOverlay`)
- [x] 4. Medical Consult (Action: Implement `SpeakToConfirmOverlay`)
- [x] 5. Gourmet Order (Action: Implement `SpeakToConfirmOverlay`)
- [x] 6. Travel Desk (Action: Implement `SpeakToConfirmOverlay`)
- [x] 7. Conflict Resolver (Action: Implement `SpeakToConfirmOverlay`)
- [x] 8. Elevator Pitch (Action: Verify Speaking)
- [x] 9. Social Spark (Action: Implement `SpeakToConfirmOverlay`)
- [x] 10. Emergency Hub (Action: Verify Typing + Terminal)

## 9. ELITE MASTERY (4 Games)
*Goal: Verify elite difficulty mechanics are intact.*
- [x] 1. Story Builder (Action: Verify Reorder + Drag)
- [x] 2. Idiom Match (Action: Implement `SpeakToConfirmOverlay`)
- [x] 3. Speed Spelling (Action: Verify Typing + Timer)
- [x] 4. Accent Shadowing (Action: Verify Voice)

## 10. KIDS ZONE (25 Games)
*Goal: NO typing or STT for kids. Implement Tap + Auto TTS Playback.*
- [ ] 1. Alphabet (Action: Implement Tap + Auto TTS Playback)
- [ ] 2. Numbers (Action: Implement Tap + Auto TTS Playback)
- [ ] 3. Colors (Action: Implement Tap + Auto TTS Playback)
- [ ] 4. Shapes (Action: Implement Tap + Auto TTS Playback)
- [ ] 5. Animals (Action: Implement Tap + Auto TTS Playback)
- [ ] 6. Fruits (Action: Implement Tap + Auto TTS Playback)
- [ ] 7. Family (Action: Implement Tap + Auto TTS Playback)
- [ ] 8. School (Action: Implement Tap + Auto TTS Playback)
- [ ] 9. Verbs (Action: Implement Tap + Auto TTS Playback)
- [ ] 10. Routine (Action: Implement Tap + Auto TTS Playback)
- [ ] 11. Emotions (Action: Implement Tap + Auto TTS Playback)
- [ ] 12. Prepositions (Action: Implement Tap + Auto TTS Playback)
- [ ] 13. Phonics (Action: Implement Tap + Auto TTS Playback)
- [ ] 14. Time (Action: Implement Tap + Auto TTS Playback)
- [ ] 15. Opposites (Action: Implement Tap + Auto TTS Playback)
- [ ] 16. Day/Night (Action: Implement Tap + Auto TTS Playback)
- [ ] 17. Nature (Action: Implement Tap + Auto TTS Playback)
- [ ] 18. Home (Action: Implement Tap + Auto TTS Playback)
- [ ] 19. Food (Action: Implement Tap + Auto TTS Playback)
- [ ] 20. Transport (Action: Implement Tap + Auto TTS Playback)
- [ ] 21. Body Parts (Action: Implement Tap + Auto TTS Playback)
- [ ] 22. Clothing (Action: Implement Tap + Auto TTS Playback)
- [ ] 23. Handwriting (Action: Verify Canvas-based drawing)
- [ ] 24. Weather (Action: Implement Tap + Auto TTS Playback)
- [ ] 25. Professions (Action: Implement Tap + Auto TTS Playback)

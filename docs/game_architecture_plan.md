# VOWL 100 Main Games - Diamond Standard Architecture Plan

## 1. Core Architecture (Continuous Scroll Reveal)
Instead of a jarring screen swap, we are using the **Continuous Scroll Reveal** pattern for games that require a second stage (pedagogical confirmation).
*   **Stage 1 (Game Mechanism):** User interacts with the puzzle. Upon success, the UI locks (touch disabled) so the answer cannot be changed.
*   **Stage 2 (Pedagogical Reveal):** The screen smoothly auto-scrolls down to reveal the deep pedagogical data and the final confirmation overlay. The user can manually scroll back up to review their locked answer.

## 2. State Management (Zero setState)
To achieve butter-smooth 60fps performance and completely eliminate `setState` lag, we strictly use a hybrid Listenable approach:
*   **Macro-Level (Top of Screen):** Use `ListenableBuilder` combined with `Listenable.merge([notifier1, notifier2, ...])` to listen to 5-6 global game states at once without nesting.
*   **Micro-Level (Inside Widgets):** Use `ValueListenableBuilder<T>` deep inside child widgets (e.g., draggable shards) so that high-frequency animations (like 60hz drag updates) only rebuild a tiny 10-pixel box instead of the whole screen.

> **CRITICAL REMINDER FOR ALL MODULES**: Never limit the `setState` audit to just the main `*_screen.dart` files. You **must** also thoroughly audit all custom widgets inside `presentation/widgets/` (such as `ReactionCore`, `TopicDraggable`, etc.) for hidden `setState` logic.

## 3. The 6-Pillar Checklist
Every single one of the 100 games must pass these 6 checks:
1. **[Dual-Stage Scroll UX]**: Does it use the continuous scroll reveal? (Mark as `[N/A]` if the game doesn't need a second stage).
2. **[Sliver Performance Layout]**: Does it use `CustomScrollView` and `Slivers` to prevent render overflow and ensure 60fps?
3. **[Zero setState (ValueNotifier)]**: Are all `setState` calls completely eliminated in favor of `ValueNotifier` and `ListenableBuilder`?
4. **[Feedback Card Logic]**: Does it correctly hide pedagogical fields if Stage 2 is used, showing only the explanation?
5. **[10/10 UX Confirmation (No Patchwork)]**: Checked deeply to ensure it's a real-world, premium, flawless UX.
6. **[Git Commit & Push]**: Committed and pushed to GitHub for safety.

---

## Master Task Tracker (100 Games)

### 🟢 Vocabulary (12 Games)
**1. Academic Word**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**2. Antonym Search**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**3. Collocations**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**4. Context Clues**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**5. Contextual Usage**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**6. Flashcards**
- [N/A] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [N/A] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**7. Idioms**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**8. Phrasal Verbs**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**9. Prefix/Suffix**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**10. Synonym Search**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**11. Topic Vocab**
- [N/A] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [N/A] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**12. Word Formation**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

---

### 🔵 Grammar (19 Games)
*(Will fill checkboxes individually as we process them)*
1. **Article Insertion**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Clause Connector**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
3. **Conditionals**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
4. **Conjunctions**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
5. **Direct/Indirect Speech**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
6. **Grammar Quest**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
7. **Modals Selection**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
8. **Modifier Placement**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
9. **Parts of Speech**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
10. **Preposition Choice**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
11. **Pronoun Resolution**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
12. **Punctuation Mastery**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
13. **Question Formatter**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
14. **Relative Clauses**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
15. **Sentence Correction**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
16. **Subject-Verb Agreement**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
17. **Tense Mastery**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
18. **Voice Swap**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
19. **Word Reorder**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

---

### 🟣 Reading (12 Games)
1. **Cloze Test**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Find Word Meaning**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
3. **Guess Title**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
4. **Paragraph Summary**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
5. **Read and Answer**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
6. **Read and Match**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
7. **Reading Conclusion**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
8. **Reading Inference**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
9. **Reading Speed Check**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
10. **Sentence Order Reading**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
11. Skimming/Scanning
12. True/False Reading

---

### 🟠 Listening (10 Games)
1. Ambient ID
2. Audio Fill Blanks
3. Audio Multiple Choice
4. Audio Sentence Order
5. Audio True/False
6. Detail Spotlight
7. Emotion Recognition
8. Fast Speech Decoder
9. Listening Inference
10. Sound Image Match

---

### 🟡 Speaking (10 Games)
1. Daily Expression
2. Dialogue Roleplay
3. Pronunciation Focus
4. Repeat Sentence
5. Scene Description
6. Situation Speaking
7. Speak Missing Word
8. Speak Opposite
9. Speak Synonym
10. Yes/No Speaking

---

### 🟤 Writing (11 Games)
1. Complete Sentence
2. Correction Writing
3. Daily Journal
4. Describe Situation
5. Essay Drafting
6. Fix The Sentence
7. Opinion Writing
8. Sentence Builder
9. Short Answer
10. Summarize Story
11. Writing Email

---

### 🔴 Accent (12 Games)
1. Connected Speech
2. Consonant Clarity
3. Dialect Drill
4. Intonation Mimic
5. Minimal Pairs
6. Pitch Modulation
7. Pitch Pattern Match
8. Shadowing Challenge
9. Speed Variance
10. Syllable Stress
11. Vowel Distinction
12. Word Linking

---

### 🎭 Roleplay (10 Games)
1. Branching Dialogue
2. Conflict Resolver
3. Elevator Pitch
4. Emergency Hub
5. Gourmet Order
6. Job Interview
7. Medical Consult
8. Situational Response
9. Social Spark
10. Travel Desk

---

### 👑 Elite Mastery (4 Games)
1. Accent Shadowing
2. Idiom Match
3. Speed Spelling
4. Story Builder

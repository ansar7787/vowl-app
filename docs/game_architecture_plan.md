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

## 3. The 9-Pillar Checklist
Every single one of the 100 games must pass these 9 checks:
1. **[Dual-Stage Scroll UX]**: Does it use the continuous scroll reveal? (Mark as `[N/A]` if the game doesn't need a second stage).
2. **[Sliver Performance Layout]**: Does it use `CustomScrollView` and `Slivers` to prevent render overflow and ensure 60fps?
3. **[Zero setState (ValueNotifier)]**: Are all `setState` calls completely eliminated in favor of `ValueNotifier` and `ListenableBuilder`?
4. **[Feedback Card Logic]**: Does it correctly hide pedagogical fields if Stage 2 is used, showing only the explanation?
5. **[Edge-to-Edge Scrollbar]**: Does it wrap CustomScrollView in RawScrollbar so the user knows they can scroll?
6. **[Keyboard Scroll Stability]**: Does it use `Scrollable.ensureVisible` for text input components to prevent keyboard layout overlap?
7. **[Docked Input Padding]**: For text-based Stage 2 mechanics, is there bottom scroll padding matching the docked overlay height?
8. **[10/10 UX Confirmation (No Patchwork)]**: Checked deeply to ensure it's a real-world, premium, flawless UX.
9. **[Git Commit & Push]**: Committed and pushed to GitHub for safety.

---

## Stage 2 & Pedagogical Hardening Tracker
- [x] Standardize `ContextSentenceBuilder` as dual-mode (overlay vs embedded).
- [x] Implement conditional `isPositioned` logic to prevent nested scrolling in 2-stage games.
- [x] Update `GameFeedbackCard` with `isTwoStageGame` to conditionally hide redundant pedagogical rules.
- [x] Integrate `hasStage2` propagation from `VocabularyBaseLayout` & `ReadingBaseLayout` down to the feedback card.
- [x] Wrap `CustomScrollView` in 2-stage screens (`ContextualUsageScreen`, `SynonymSearchScreen`, `PhrasalVerbsScreen`) with `RawScrollbar` pinned to edge.
- [x] Optimize vertical layout spacing (replaced 420.h with 40.h).
- [x] Integrate `Scrollable.ensureVisible` in `ContextSentenceBuilder` to ensure keyboard stability.

---

## Master Task Tracker (100 Games)

### 🟢 Vocabulary (12 Games)
**1. Academic Word**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `AcademicField & Collocations Widget`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
**2. Antonym Search**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `GradientScale Widget`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [N/A] Keyboard Scroll Stability (FocusNode visibility)
- [N/A] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**3. Collocations**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `wrongCollocations` & `ContextSentenceBuilder`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**4. Context Clues**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ClueType & EvidenceWords Widget`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [N/A] Keyboard Scroll Stability (FocusNode visibility)
- [N/A] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**5. Contextual Usage**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `Formality Meter (registerLevel)`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [N/A] Keyboard Scroll Stability (FocusNode visibility)
- [N/A] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**6. Flashcards**
- [N/A] Dual-Stage Scroll UX
- [N/A] Sliver Performance Layout (Stack-based)
- [x] Zero setState (ValueNotifier & Controller)
- [N/A] Feedback Card Logic
- [N/A] Pedagogical Component: (Single stage interaction)
- [N/A] Edge-to-Edge Scrollbar (RawScrollbar)
- [N/A] Keyboard Scroll Stability (FocusNode visibility)
- [N/A] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**7. Idioms**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `Origin / Etymology Widget`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [N/A] Keyboard Scroll Stability (FocusNode visibility)
- [N/A] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**8. Phrasal Verbs**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `PhrasalVerbsLiteralComparison` & `ContextSentenceBuilder`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**9. Prefix/Suffix**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `TypeToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**10. Synonym Search**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `NuanceScale Widget` & `ContextSentenceBuilder`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**11. Topic Vocab**
- [N/A] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [N/A] Feedback Card Logic
- [N/A] Pedagogical Component: (Drag & drop bucket interaction)
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [N/A] Keyboard Scroll Stability (FocusNode visibility)
- [N/A] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

**12. Word Formation**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ReactionCore` & `TypeToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Under-Scroll Padding
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
- [x] Pedagogical Component: `ArticleFloatingOrb` & `ArticleOptionGrid`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Clause Connector**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ClausePuzzleView` & `ConnectorOptionGrid`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
3. **Conditionals**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ConditionalsChainPainter`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
4. **Conjunctions**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ConjunctionsBrickSheet`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
5. **Direct/Indirect Speech**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `DirectIndirectSpeechMirror`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
6. **Grammar Quest**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `GrammarQuestCompass` & `DynamicJigsawWrapper`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
7. **Modals Selection**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ModalsRotaryDial`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
8. **Modifier Placement**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ModifierMagneticArena`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
9. **Parts of Speech**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SpeechVortex` & `SpeechDraggableWord`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
10. **Preposition Choice**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `PrepositionPathPainter`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
11. **Pronoun Resolution**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `PronounResolutionGravityPainter`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
12. **Punctuation Mastery**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `PunctuationStickerSheet`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
13. **Question Formatter**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `QuestionFormatterCrank`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
14. **Relative Clauses**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `RelativeClausesQuantumPainter`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
15. **Sentence Correction**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SentenceCorrectionDiagnosticWord`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
16. **Subject-Verb Agreement**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SubjectVerbAgreementScale`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
17. **Tense Mastery**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `TenseMasteryTimelineSlider`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
18. **Voice Swap**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `VoiceSwapToggle` & `VoiceSwapResult`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
19. **Word Reorder**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `WordReorderFloatingTile` & `AssemblyCard`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

---

### 🟣 Reading (12 Games)
1. **Cloze Test**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ClozeTestPneumaticPort` & `ClozeTestFuelCells`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Find Word Meaning**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `FindWordMeaningInteractivePassage` & `MagnifierField`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
3. **Guess Title**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `GuessTitleCargoCrate` & `GuessTitleLabelRack`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
4. **Paragraph Summary**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ParagraphSummaryTube` & `OptionRack`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
5. **Read and Answer**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ReadAndAnswerFloatingPassage` & `BuoyOption`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
6. **Read and Match**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ReadAndMatchTerminal` & `LaserBridgePainter`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
7. **Reading Conclusion**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ReadingConclusionBridgePainter` & `Terminals`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
8. **Reading Inference**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ReadingInferenceFoggyMirror`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
9. **Reading Speed Check**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ReadingSpeedPulseZone`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
10. **Sentence Order Reading**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SentenceOrderReadingStoneSlab`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
11. **Skimming/Scanning**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SkimmingScanningTerminal` & `TargetBadge`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
12. **True/False Reading**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `TrueFalseReadingCoinZone`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
---

### 🟠 Listening (10 Games)
1. **Ambient ID**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SpeakToConfirmOverlay` & `AmbientIdSonarField`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Audio Fill Blanks**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `AudioFillBlanksInput` & `BlindDictationWrapper`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
3. **Audio Multiple Choice**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `AudioMultipleChoiceSpinner` & `EvidenceHighlightWrapper`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
4. **Audio Sentence Order**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `AudioSentenceOrderOscilloscope` & `DynamicJigsawWrapper`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
5. **Audio True/False**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `AudioTrueFalsePolarizedFilters` & `TypeToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
6. **Detail Spotlight**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `DetailSpotlightDarkField` & `TypeToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
7. **Emotion Recognition**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `EmotionRecognitionNeuralField` & `SpeakToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
8. **Fast Speech Decoder**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `FastSpeechDecoderCore` & `FastSpeechDecoderSteamVents` & `SpeakToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
9. **Listening Inference**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `ListeningInferenceRadarCore` & `ListeningInferenceGrid`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
10. **Sound Image Match**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SoundImageMatchScannerField` & `SpeakToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

---

### 🟡 Speaking (10 Games)
1. **Daily Expression**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `DailyExpressionScratchPanel` & `SpeakToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Dialogue Roleplay**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `DialogueRoleplayExchangeStage` & `SpeakingSelfEvaluationControls`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
3. **Pronunciation Focus**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `PronunciationFocusPhonemeCrucible` & `ShadowPlaybackCompare`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
4. **Repeat Sentence**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `RepeatSentenceAuditionCard` & `ShadowPlaybackCompare`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
5. **Scene Description**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SceneDescriptionScenicRadarMap` & `SceneDescriptionActivePromptCard` & `SpeakingSelfEvaluationControls`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
6. **Situation Speaking**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SituationSpeakingFogScrubberPanel` & `SpeedChallengeTimer` & `SpeakingSelfEvaluationControls`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
7. **Speak Missing Word**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SpeakMissingWordVortexSentence` & `SpeakMissingWordMagnetArena` & `SpeakingSelfEvaluationControls`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
8. **Speak Opposite**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SpeakOppositePositivePolePanel` & `SpeakOppositePlasmaConduitPanel` & `SpeakOppositeNegativePolePanel` & `SpeedChallengeTimer` & `SpeakingSelfEvaluationControls`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
9. **Speak Synonym**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `SpeakSynonymGardenPanel` & `ShadowPlaybackCompare`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
10. **Yes/No Speaking**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `YesNoSpeakingTiltArena` & `TypeToConfirmOverlay`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push

---

### 🟤 Writing (11 Games)
1. **Complete Sentence**
- [x] Dual-Stage Scroll UX
- [x] Sliver Performance Layout
- [x] Zero setState (ValueNotifier)
- [x] Feedback Card Logic
- [x] Pedagogical Component: `CompleteSentenceTargetWall` & `CompleteSentenceBallistaAmmo` & `DynamicAnagramWrapper`
- [x] Edge-to-Edge Scrollbar (RawScrollbar)
- [x] Keyboard Scroll Stability (FocusNode visibility)
- [x] Docked Input Padding (Keyboard Games Only)
- [x] 10/10 UX Confirmation (No Patchwork)
- [x] Git Commit & Push
2. **Correction Writing**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
3. **Daily Journal**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
4. **Describe Situation**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
5. **Essay Drafting**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
6. **Fix The Sentence**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
7. **Opinion Writing**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
8. **Sentence Builder**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
9. **Short Answer**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
10. **Summarize Story**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
11. **Writing Email**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push

---

### 🔴 Accent (12 Games)
1. **Connected Speech**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
2. **Consonant Clarity**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
3. **Dialect Drill**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
4. **Intonation Mimic**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
5. **Minimal Pairs**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
6. **Pitch Modulation**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
7. **Pitch Pattern Match**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
8. **Shadowing Challenge**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
9. **Speed Variance**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
10. **Syllable Stress**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
11. **Vowel Distinction**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
12. **Word Linking**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push

---

### 🎭 Roleplay (10 Games)
1. **Branching Dialogue**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
2. **Conflict Resolver**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
3. **Elevator Pitch**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
4. **Emergency Hub**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
5. **Gourmet Order**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
6. **Job Interview**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
7. **Medical Consult**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
8. **Situational Response**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
9. **Social Spark**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
10. **Travel Desk**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push

---

### 👑 Elite Mastery (4 Games)
1. **Accent Shadowing**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
2. **Idiom Match**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
3. **Speed Spelling**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
4. **Story Builder**
- [ ] Dual-Stage Scroll UX
- [ ] Sliver Performance Layout
- [ ] Zero setState (ValueNotifier)
- [ ] Feedback Card Logic
- [ ] Pedagogical Component: `TBD`
- [ ] Edge-to-Edge Scrollbar (RawScrollbar)
- [ ] Keyboard Scroll Stability (FocusNode visibility)
- [ ] Docked Input Padding (Keyboard Games Only)
- [ ] 10/10 UX Confirmation (No Patchwork)
- [ ] Git Commit & Push
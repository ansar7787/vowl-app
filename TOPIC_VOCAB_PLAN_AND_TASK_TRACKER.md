# 🎮 TOPIC VOCAB — MASTER AUDIT, PRODUCTION PLAN & TASK TRACKER
**Game Subtype:** `topicVocab` (`GameSubtype.topicVocab`) | **Category:** `Vocabulary` (`lib/features/vocabulary/topic_vocab`)  
**Recommended Concept:** **CLUSTER FUSION** *(The Thematic Matrix & Tile Merge — Inspired by NYT Connections)*  
**Rating:** **9.9/10** (Highest Rated & Recommended) | **Execution Mode:** `PLAN_FIRST` (Stops for user approval)

---

## 🔒 1. 100% RADICAL FRESH START GUARANTEE
Every line of code and JSON will be authored fresh. **Zero legacy widgets, zero legacy JSON, zero legacy tests, and zero recycled mechanics.**
- 🗑️ **Wipe Old Legacy Widgets**: `git rm -r lib/features/vocabulary/topic_vocab/presentation/widgets/*` (Deletes `TopicMachineHead`, `TopicContainmentBin`, `TopicDraggableWord`, `TopicBatchCounter`, `TopicVocabMindMap`).
- 🗑️ **Wipe Old Controller**: `git rm lib/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart`.
- 🗑️ **Wipe Old Tests**: `git rm -r test/features/vocabulary/topic_vocab/`.
- 🗑️ **Wipe All 60 Old JSON Files**: `git rm assets/curriculum/vocabulary/topicVocab_*`.
- 🧹 **Clean Slate Screen Canvases**: Screen bodies of `topic_vocab_screen.dart`, `topic_vocab_learn_screen.dart`, and `topic_vocab_practice_screen.dart` will be cleared to a blank canvas while retaining class names and constructors for router stability.

---

## 2. 🌍 CEFR CURRICULUM ARCHITECTURE (ALL 60 FILES)

The 200 levels across 20 batches (60 JSON files total) are strictly mapped to standard CEFR pedagogical progression bands:

| CEFR Band | Batches | Level Range | Files per Phase | Total Files (Learn + Practice + Mastery) | Thematic Lexicon Focus |
|---|---|---|---|---|---|
| **A2** | Batches 1–4 | Levels 1–40 | 4 Learn, 4 Practice, 4 Mastery | **12 files** | Foundation Topics: Temperature, Daily Routine, Food/Dining, House/Rooms |
| **B1** | Batches 5–8 | Levels 41–80 | 4 Learn, 4 Practice, 4 Mastery | **12 files** | Intermediate Topics: Travel/Transit, Jobs/Workplace, Shopping/Retail, Health/Body |
| **B2** | Batches 9–12 | Levels 81–120 | 4 Learn, 4 Practice, 4 Mastery | **12 files** | Upper-Intermediate: Education/Study, Media/News, Environment/Nature, Money/Finance |
| **C1** | Batches 13–16 | Levels 121–160 | 4 Learn, 4 Practice, 4 Mastery | **12 files** | Advanced Topics: Law/Justice, Science/Research, Politics/Society, Psychology/Emotion |
| **C2** | Batches 17–20 | Levels 161–200 | 4 Learn, 4 Practice, 4 Mastery | **12 files** | Mastery Nuance: Philosophy/Ethics, Diplomacy, Aesthetics/Literature, Rhetoric/Debate |

> **Placeholder Generation Rule**: Every batch file will carry its exact CEFR tag (`"cefr": "A2" | "B1" | "B2" | "C1" | "C2"`) matching `PhasedQuest.getCefrForLevel(level)`. File 1 (`1_10.json`) will be crafted with rich real-world A2 content; files 2–20 (57 files) will be generated with matching schemas and incremented batch data to guarantee 100% crash-free stability across all 200 levels.

---

## 3. DEEP ARCHITECTURAL & PIPELINE AUDIT FINDINGS

### A. Routing Contracts (Verified in Codebase):
- In `lib/features/games/game_routes.dart` (lines 506 & 1135):
  - `/learn?category=vocabulary&gameType=topicVocab&level=X` directly instantiates: `TopicVocabLearnScreen(level: level)`.
  - `/practice?category=vocabulary&gameType=topicVocab&level=X` directly instantiates: `TopicVocabPracticeScreen(level: level)`.
- In `lib/core/utils/app_router_game_resolvers.dart` (line 759):
  - `/game?category=vocabulary&gameType=topicVocab&level=X` directly calls: `TopicVocabMasteryScreen(level: level, gameType: gameType)`.
- **Architectural Standardization**: Setting `typedef TopicVocabMasteryScreen = TopicVocabScreen;` satisfies the exact resolver signature with zero routing changes or adapter overhead.

### B. Data Model & Deserialization Pipeline:
1. **Mastery Phase**:
   - `AssetQuestService` loads `topicVocab_mastery_1_10.json` via isolate compute `_parseQuestsInIsolate`.
   - `VocabularyQuestModel.fromJson` natively deserializes:
     - `topicBuckets`: `List<String>` (e.g. `["Intense Heat", "Extreme Cold"]`)
     - `options`: `List<String>` (shuffled tile pool for the matrix)
     - `correctAnswer`: `String` (cluster assignment string)
     - `relatedWords`: `List<String>` (word definitions & intensity notes)
     - `instruction`, `explanation`, `hint`
   - In `TopicVocabScreen`, `VocabularyLoaded.currentQuest` gives us clean, type-safe access to all properties.
2. **Learn & Practice Phases**:
   - Loaded via `rootBundle.loadString(path)` and parsed by `PhasedQuestBatch.fromJson(data)`.
   - `PhasedQuestBatch` maps into `PhasedQuest` where `rawExtra: json` preserves the entire JSON map.
   - This allows rich custom structures (`categories`, `contrastInsight`, `boards`, `clusters`, `oneAwayClues`) to be read directly from `quest.rawExtra` without missing data or schema exceptions.

### C. Phase Progression & Auth Recording:
- `TopicVocabLearnScreen` executes `PhaseProgressRecorder.recordPhaseCompleted(..., phase: 'learn')` and routes to `/practice`.
- `TopicVocabPracticeScreen` executes `PhaseProgressRecorder.recordPhaseCompleted(..., phase: 'practice')` and routes to `/game`.
- `TopicVocabScreen` interacts with `VocabularyBloc` and `VocabularyBaseLayout` to record XP, coins, and category accuracy statistics on level completion.

---

## 4. THE WINNING GAME CONCEPT: "CLUSTER FUSION"

```
┌────────────────────────────────────────────────────────┐
│                   CLUSTER FUSION                       │
├────────────────────────────────────────────────────────┤
│  [ Boiling ]    [ Freezing ]    [ Scorching ]          │
│  [ Chilly ]     [ Steaming ]    [ Frosty ]             │
│                                                        │
│  Tap 3 tiles in same category:                         │
│  [ Boiling ] + [ Scorching ] + [ Steaming ]            │
│                                                        │
│               ⬇️ FUSION ANIMATION ⬇️                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │  🔥 INTENSE HEAT (Boiling • Scorching • Steaming)│  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  Remaining tiles drop down & auto-compress:            │
│  [ Freezing ]   [ Chilly ]    [ Frosty ]               │
└────────────────────────────────────────────────────────┘
```

### Why "Cluster Fusion" is the Recommended #1 Winner:
1. **Unmatched Game Dopamine**: Finding connections and watching tiles physically slide together and merge into a gleaming category banner creates viral, satisfying game feel.
2. **Pedagogically Superior for ESL**: Trains the learner to evaluate the semantic boundaries of all words simultaneously, establishing mental lexical networks.
3. **100% Unique in Vowl**: Completely different from `Flashcards` (no flip cards, no swipe decks) and completely different from the old legacy implementation (no clunky bottom flicking bins).
4. **Performance Conscious**: Lightweight 2D spring physics with `flutter_animate` and `flutter_screenutil`, targeting 120 Hz native fluid refresh with zero jank.

---

## 5. THE THREE PHASES (100% BRAND NEW)

### 🧠 Phase 1: Learn Phase — "The Thematic Blueprint"
- **Visual Matrix**: The topic domain is displayed as an interactive semantic tree with clean `16.w` margins.
- **Interactive Branches**: Tapping a category branch (e.g., `🔥 Intense Heat` vs `❄️ Polar Cold`) unfolds its word tiles.
- **Audio & Collocations**: Tapping any word tile triggers native pronunciation via device TTS (`flutter_tts`), displays its intensity rating (e.g. liquid bubbles vs dry sun heat), and shows real-world collocations (*"scorching desert sun"*).
- **Zero Stress**: No timer, no lives, pure tactile discovery.

### ⚡ Phase 2: Practice Phase — "Cluster Fusion & One-Away Clues"
- **Tactile 6-to-8 Tile Matrix**: Mixed tiles representing two distinct categories.
- **Selection & Fusion**:
  - Learner taps tiles that belong to the same category.
  - Tapping **"FUSE CLUSTER"** (or auto-fusing on final match) causes the tiles to slide into the center with spring physics, compress, and lock into a gleaming Category Banner!
  - The remaining tiles drop down, align, and fuse for the next category.
- **"One-Away" Smart Feedback**: If the user selects 2 of 3 correct and 1 wrong, the wrong tile gently shakes and displays a helpful clue: *"One away! 'Chilly' doesn't fit with intense heat — try another!"*

### 🏆 Phase 3: Mastery Phase — "Rapid Convergence Rush"
- **Arcade Speed Challenge**: A 6-to-8 tile matrix with an adrenaline speed fuse timer.
- **Instant Recognition**: Player identifies and fuses clusters under time pressure.
- **Combo Multipliers**:
  - 1st Fusion: +100 XP
  - 2nd Fusion (within 10s): **2× Combo Multiplier** + flame trail on progress bar!
  - Full Board Wipe: **Board Cleared Bonus** (+200 XP, victory flight overlay, and mascot cheer)!
- **High-Refresh Fluidity**: Built for native 120 Hz displays with zero frame drops.

---

## 6. CURRICULUM JSON RECREATION BLUEPRINT

### File 1 Real Data (`_1_10.json`) + 57 Placeholder Files (`_11_20` to `_191_200`)
1. **Purge**: `git rm assets/curriculum/vocabulary/topicVocab_*` (removes all 60 old files).
2. **Recreate File 1 (Rich Real-World Content - A2)**:
   - `assets/curriculum/vocabulary/topicVocab_learn_1_10.json` (Thematic blueprint tree schema, A2)
   - `assets/curriculum/vocabulary/topicVocab_practice_1_10.json` (Cluster fusion boards with one-away clues, A2)
   - `assets/curriculum/vocabulary/topicVocab_mastery_1_10.json` (Timed convergence boards with combo targets, A2)
3. **Generate Files 2–20 (57 Identical Placeholder Files across A2, B1, B2, C1, C2)**:
   - Recreated with identical keys, valid placeholder strings, incremented batch numbers, and accurate CEFR tags to ensure `AssetQuestService` never throws missing-asset crashes across all 200 levels.

---

## 7. ARCHITECTURAL FILE SPLITTING BLUEPRINT (ALL < 250 LINES)

```
lib/features/vocabulary/topic_vocab/
├── presentation/
│   ├── controllers/
│   │   └── topic_vocab_controller.dart (~180 lines - selection state, cluster validation, fusion animation)
│   ├── pages/
│   │   ├── topic_vocab_screen.dart (~250 lines - Mastery Screen, uses VocabularyBaseLayout)
│   │   ├── topic_vocab_learn_screen.dart (~240 lines - Learn Screen, uses LearnPhaseScaffold)
│   │   ├── topic_vocab_practice_screen.dart (~250 lines - Practice Screen, uses PracticePhaseScaffold)
│   │   └── topic_vocab_mastery_screen.dart (15 lines - typedef TopicVocabMasteryScreen = TopicVocabScreen)
│   └── widgets/
│       ├── topic_fusion_tile.dart (~140 lines - bouncy, elevated word tile with selected/fused states)
│       ├── topic_cluster_banner.dart (~130 lines - golden merged category banner with celebration)
│       ├── topic_matrix_grid.dart (~180 lines - responsive grid with spring physics)
│       ├── topic_blueprint_tree.dart (~180 lines - interactive semantic tree for Learn phase)
│       └── topic_fusion_timer.dart (~90 lines - sleek arcade timer bar for Mastery)
```

---

## 8. MASTER TASK TRACKER

| ID | Area | Phase | Problem / Opportunity | Severity | Evidence | Recommended Fix | Status | Verification |
|---|---|---|---|---|---|---|---|---|
| **TV-01** | Stage 2 Purge | All | Old legacy files and 60 JSONs exist on disk | P0 | Directory inspection | Run `git rm` on old widgets, controller, tests, and JSON files | Pending Approval | Git status clean |
| **TV-02** | Architecture | Mastery | `topic_vocab_mastery_screen.dart` is custom widget | P1 | Lines 1–28 of screen | Standardize to `typedef TopicVocabMasteryScreen = TopicVocabScreen;` | Pending Approval | Router compile test |
| **TV-03** | Architecture | All | God-file line violations (>400 lines) | P1 | Screen files: 749, 699, 525 lines | Extract focused subwidgets under 250 lines in `presentation/widgets/` | Pending Approval | Line count check <250 |
| **TV-04** | UI / Vibe | All | Clunky legacy widgets (machine heads, bins) | P1 | `TopicMachineHead`, `TopicContainmentBin` | Replace with modern `TopicFusionTile`, `TopicClusterBanner`, `TopicMatrixGrid` | Pending Approval | Visual inspection & tests |
| **TV-05** | Curriculum | All | 60 legacy JSON files lack CEFR banding & depth | P0 | 60 files across 200 levels | Recreate File 1 (A2) + 57 placeholders across A2, B1, B2, C1, C2 | Pending Approval | Asset load test |
| **TV-06** | Pedagogy | Learn | Passive textbook dictionary feel | P2 | Static cards with text blobs in `topic_vocab_learn_screen.dart` | Rebuild as *Thematic Blueprint* with TTS and branch expansion | Pending Approval | Widget test |
| **TV-07** | Pedagogy | Practice | Boring legacy MCQ and plain TextField | P1 | Radio buttons with `A/B/C/D` and plain typing | Rebuild as *Cluster Fusion* with one-away clues and tile merge | Pending Approval | Interaction test |
| **TV-08** | Mechanics | Mastery | Old flicking bins feel stale | P1 | Legacy 2-bin flicking | Rebuild as *Rapid Convergence Rush* with fusion bursts & combo multipliers | Pending Approval | Interaction & streak test |
| **TV-09** | Layout | All | Screen width utilization & padding standard | P2 | Inconsistent padding and constraints | Standardize `16.w` horizontal margin and responsive `.w/.h/.sp/.r` | Pending Approval | Multi-screen size test |
| **TV-10** | Localization | Shared | Instructions and translation synchronization | P2 | Check `en.json` `instructions.topicVocab` and 17 language files | Update `en.json` with human game copy; sync placeholders | Pending Approval | JSON syntax check |
| **TV-11** | Story & Briefing | Shared | Milestone scripts and briefing verification | P3 | `StoryServiceImpl` and `GameInstructionService` | Verify entries in `story_service.dart` and `game_instruction_service.dart` | Pending Approval | Unit test verification |
| **TV-12** | Tests | All | Obsolete tests for legacy widgets | P1 | Old tests verify dead text strings | Wipe old tests; write complete fresh bloc/unit/widget test suite | Pending Approval | `flutter test` green |

---

## 9. READY FOR YOUR MANUAL "PROCEED"
This master plan and task tracker is locked and ready. **No code or file will be modified until you explicitly reply 'PROCEED'.**

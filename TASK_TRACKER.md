# 🗺️ VOWL Master Test Coverage Plan & Granular Task Tracker

> [!IMPORTANT]
> **Executive Summary & Brutal Audit**:
>
> - **Total Dart Files in `lib/`**: **1,068 files**
> - **Total Test Files in `test/`**: **70 files**
> - **Total Passing Tests**: **504 / 504 Tests Passing (100% Green)**
> - **Completed Test Suites**: **32 files** (Auth 12, Games Hub 1, Kids 22, Reading 2, Daily Challenges 5, Photo Vocab 2, Scan & Learn 2, Translation 2, Core 7)
> - **Remaining Game Screens & Hubs to Test**: **104+ screens** across 12 game categories, hubs, and shell routes.

---

## 🎯 Verification Quality Standards (No Blind / Fake Testing)

Every game test suite MUST rigorously satisfy:

1. **Authentic Game Mechanics (Never Blindly Assume Drag & Drop)**:
   - **Arranging / Sorting / Cloze / Buoy**: Dual interaction (both instant tap-to-answer AND drag-and-drop mechanics where applicable).
   - **Speech / Pronunciation / Repeat**: Microphone speech-to-text input, waveform visualization, and real-time audio playback.
   - **Handwriting**: Freeform canvas stroke drawing, stroke reset, path gesture evaluation.
   - **Flashcards / Matching / Memory**: Card flip animations, tile selection, and memory pair reveal.
   - **Text / Multiple Choice / True-False**: Single/multi-option tap selection, validation feedback, and clear submit states.
   - **Writing / Essay / Sentence**: Text input/insertion, token reordering, and submission.
2. **Two Master Level Maps Progression**:
   - **Modern Category Map (Main 100+ Games)**: Sequential level unlocking (Level 1 -> 2 -> 3), star rating awards (1-3 stars), active pulsating current level ring, and locked status for future levels.
   - **Kids Level Map (25 Kids Games)**: Child-friendly thematic progression, milestone badges, and interactive navigation.
3. **Offline & Online Firestore Resilience**:
   - **Offline Mode**: Automatic local persistence via SQLite/SharedPreferences cache. Free users respect the 3-level offline grace quota (`OfflinePlayGateService`). Premium users bypass quotas with unlimited offline play (`NetworkInfo.setPremiumOverride`).
   - **Online Sync**: Unsynced offline progress, stars, and XP atomically update to Firebase Firestore upon reconnection with zero data loss or state corruption.
4. **Zero Real-Money Leakage & Secure Economy**:
   - **In-App Purchases (Google Play)**: Strictly validated via backend Cloud Function (`validateIAPReceipt`) before delivery.
   - **Razorpay (India Gateway)**: Server-side order generation and signature verification before coins/premium are granted.
   - **Economy Blocs**: Zero client-side tampering; coin balances, hint deductions, and reward grants must be atomic.
5. **Audio Scaffolding**: Dedicated audio replay buttons invoking Text-to-Speech (`SoundService.playTts`) for both question and passage.
6. **Small Screen Layout Safety (320dp)**: Verified at `320 x 568` with zero `RenderFlex` overflow errors across all devices.
7. **BLoC & State Flow**: Dispatches `SubmitAnswer(true)` on correct path and `SubmitAnswer(false)` on incorrect path.
8. **Sensory Feedback**: Verifies selection haptics (`hapticService.selection()`), success haptics (`hapticService.success()`), error haptics (`hapticService.error()`), and SFX (`soundService.playWrong()`, `soundService.playCorrect()`).
9. **Curriculum Immutability**: All JSON files in `assets/curriculum/` remain **100% byte-for-byte untouched**.

---

## 📊 High-Level Category Status Summary

| # | Section / Category | Total Screens/Items | Completed | Remaining | Current Status |
| --- | -------------------- | :-------------------: | :---------: | :---------: | :--------------: |
| **1** | **Authentication & Accounts** | 12 | 12 | 0 | 🟢 100% Complete (62 tests) |
| **2** | **Games Hub & Routing** | 5 | 5 | 0 | 🟢 100% Complete (58 tests) |
| **3** | **Kids Zone** | 31 | 23 | 8 | 🟡 74% Complete (6 Hubs + 2 Layouts remaining) |
| **4** | **Reading Category** | 13 | 2 | 11 | 🟡 1 Game + BLoC Done (11 games remaining) |
| **5** | **Accent Training** | 13 | 1 | 12 | ⚠️ BLoC only (12 games remaining) |
| **6** | **Grammar Category** | 20 | 2 | 18 | ⚠️ BLoC + Model only (19 games remaining) |
| **7** | **Listening Category** | 11 | 2 | 9 | ⚠️ BLoC + Model only (10 games remaining) |
| **8** | **Roleplay Category** | 11 | 2 | 9 | ⚠️ BLoC + Model only (10 games remaining) |
| **9** | **Speaking Category** | 11 | 1 | 10 | ⚠️ BLoC only (10 games remaining) |
| **10** | **Vocabulary Category** | 13 | 2 | 11 | ⚠️ BLoC + Model only (12 games remaining) |
| **11** | **Writing Category** | 12 | 1 | 11 | ⚠️ BLoC only (11 games remaining) |
| **12** | **Elite Mastery** | 5 | 1 | 4 | ⚠️ BLoC only (4 games remaining) |
| **13** | **Daily Challenges & Micro-Games** | 11 | 11 | 0 | 🟢 100% Complete |
| **14** | **Home, Shell & Navigation** | 6 | 0 | 6 | 🔴 0% Tested (6 screens) |
| **15** | **Profile, Progress & Trophies** | 7 | 0 | 7 | 🔴 0% Tested (7 screens) |
| **16** | **Leaderboard, Settings, Paywall, Splash** | 8 | 1 | 7 | ⚠️ 1 Sheet tested (7 items remaining) |

---

## 📝 Granular Task Tracker (Item-by-Item)

---

### SECTION 1: AUTHENTICATION & ACCOUNTS (100% COMPLETE)

- [x] **1.1** `signup_cubit_test.dart` (Unit Test) — ✅ `[DONE - 15/15 tests passing]`
  - Validates full name, email format, password strength, terms acceptance, and registration state transitions.
- [x] **1.2** `forgot_password_cubit_test.dart` (Unit Test) — ✅ `[DONE - 8/8 tests passing]`
  - Validates email validation, submission loading, success states, and error handling.
- [x] **1.3** `signup_page_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
  - Validates form rendering, input submission, and navigation to login.
- [x] **1.4** `forgot_password_page_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
  - Validates reset email input, submission trigger, and back button navigation.
- [x] **1.5** `age_gate_screen_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
  - Validates age selector, under-13 routing to Kids Zone, and 13+ routing to Main App.
- [x] **1.6** `verify_email_page_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
  - Validates email confirmation instructions, resend verification button, and check status trigger.
- [x] **1.7** `login_page_test.dart` (Widget Test) — ✅ `[DONE - 2/2 tests passing]`
  - Validates email/password sign-in fields, validation errors, and submission.
- [x] **1.8** `auth_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 8/8 tests passing]`
  - Validates auth state changes (authenticated, unauthenticated, guest, loading).
- [x] **1.9** `economy_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 6/6 tests passing]`
  - Validates coin addition, deduction, hint purchases, and daily reward claims.
- [x] **1.10** `profile_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
  - Validates user profile updates, mascot changes, and stats loading.
- [x] **1.11** `progression_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
  - Validates level unlocking, XP calculations, and streak increments.
- [x] **1.12** `user_entity_test.dart` (Unit Test) — ✅ `[DONE - 3/3 tests passing]`
  - Validates entity serialization, immutability, and copyWith.

---

### SECTION 2: GAMES HUB & ROUTING (100% COMPLETE)

- [x] **2.1** `game_routes_test.dart` (Unit/Routing Test) — ✅ `[DONE - 25/25 tests passing]`
  - Validates 7 standard route paths, query parameter parsing across all 9 categories, subtype aliases, case-insensitivity, category and subtype fallback routing, missing/invalid level fallbacks, and authenticated/unauthenticated quest sequence routing.
- [x] **2.2** `games_screen_test.dart` (Widget Test) — ✅ `[DONE - 10/10 tests passing]`
  - Validates Quest Hub app bar, Shimmer loading placeholder on unauthenticated user, Hero Mastery Dashboard calculations and stat pills (XP, Streak, Levels Cleared, Core Games), BeginnerDiscoveryCard gating for adult vs kidsModeOnly users, Kids Zone shelf with balloon badge, Kids Zone See All navigation to `/kids-zone`, adult category shelves rendering (Speaking, Listening, Reading, Writing, Elite Mastery with gold badge and crown emoji), See All routing to `/category-games?category=speaking`, dark mode visual cleanliness, and small screen 320dp width zero-overflow layout safety.
- [x] **2.3** `kids_category_shelf_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
  - Validates horizontal ListView shelf rendering, 2026 spatial physics transform tilt/scale/opacity, NEW badge indicator for level 1 / 0 cleared, level number & circular progress ring for in-progress games, golden checkmark badge for mastered categories (200 levels), tap-to-navigate to `/kids/map/:gameType` with title and color payload, dark mode visual cleanliness, and compact mobile screen 320dp width zero-overflow layout safety.
- [x] **2.4** `modern_category_map_test.dart` (Universal Category Map & Progression Test) — ✅ `[DONE - 7/7 tests passing]`
  - Validates map structure, GlassMapHeader and CustomScrollView, AssetQuestService preloadBatch for active level, level node progression states (completed levels, earned stars, glowing playable current level), unlocked node tap routing to `/game?category=...&gameType=...&level=...`, back button navigation, dark mode visual cleanliness, and compact 320dp width zero-overflow layout safety.
- [x] **2.5** `offline_play_gate_service_test.dart` (Offline Play Gate & Quota Unit Test) — ✅ `[DONE - 8/8 tests passing]`
  - Validates offline level count, 3-level grace quota for free users, rewarded ad bonus plays (+3 plays), reconnect pending ad trigger, ad watch quota reset, and 24-hour timestamp persistence & auto-expiration.

---

### SECTION 3: KIDS ZONE (74% COMPLETE)

- [x] **3.1** `kids_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **3.2** `kids_clothing_layout_test.dart` (Widget Test) — ✅ `[DONE - 12/12 tests passing]`
  - Baseline fixed: Dual interaction, TTS audio, 320dp small screen zero-overflow.
- [x] **3.3** `kids_alphabet_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.4** `kids_animals_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.5** `kids_body_parts_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.6** `kids_handwriting_layout_test.dart` (Widget Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **3.7** `kids_home_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.8** `kids_nature_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.9** `kids_numbers_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.10** `kids_opposites_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.11** `kids_phonics_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.12** `kids_prepositions_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.13** `kids_professions_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.14** `kids_routine_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.15** `kids_school_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.16** `kids_shapes_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.17** `kids_time_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.18** `kids_transport_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.19** `kids_verbs_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.20** `kids_weather_layout_test.dart` (Widget Test) — ✅ `[DONE - 8/8 tests passing]`
- [x] **3.21** `handwriting_evaluator_test.dart` (Unit Test) — ✅ `[DONE - 14/14 tests passing]`
- [x] **3.22** `handwriting_content_alignment_test.dart` (Unit Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **3.23** `kids_verbs_story_and_instructions_test.dart` (Widget Test) — ✅ `[DONE - 4/4 tests passing]`
- [ ] **3.24** `kids_colors_layout_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **3.25** `kids_day_night_layout_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **3.26** `kids_emotions_layout_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **3.27** `kids_family_layout_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **3.28** `kids_food_layout_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **3.29** `kids_fruits_layout_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **3.30** `kids_zone_screen_test.dart` (Hub Screen Test) — 🔴 `[PENDING]`
- [ ] **3.31** `kids_level_map_test.dart` (Level Map Navigation Test) — 🔴 `[PENDING]`
- [ ] **3.32** `kids_room_screen_test.dart` (Pet Care / Interactive Room Test) — 🔴 `[PENDING]`
- [ ] **3.33** `buddy_boutique_screen_test.dart` (Wardrobe / Dressing Room Test) — 🔴 `[PENDING]`
- [ ] **3.34** `mascot_selection_screen_test.dart` (Mascot Selection Screen Test) — 🔴 `[PENDING]`
- [ ] **3.35** `sticker_book_screen_test.dart` (Sticker Collection Viewer Test) — 🔴 `[PENDING]`

---

### SECTION 4: READING CATEGORY (12 GAMES)

- [x] **4.1** `reading_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [x] **4.2** `read_and_answer_layout_test.dart` (Game Screen Layout Test) — ✅ `[DONE - 8/8 tests passing]`
  - Validates initial rendering, question TTS, passage TTS, tap-to-answer correct path (BLoC + success haptics), tap-to-answer incorrect path (BLoC + wrong sound + error haptics), drag-and-drop buoy drop onto anchor card, evidence phase trigger, long story adaptability, 320dp small screen safety.
- [ ] **4.3** `find_word_meaning_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.4** `cloze_test_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.5** `guess_title_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.6** `paragraph_summary_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.7** `reading_conclusion_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.8** `reading_inference_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.9** `reading_speed_check_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.10** `read_and_match_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.11** `sentence_order_reading_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.12** `skimming_scanning_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **4.13** `true_false_reading_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 5: ACCENT TRAINING CATEGORY (12 GAMES)

- [x] **5.1** `accent_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [ ] **5.2** `connected_speech_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.3** `consonant_clarity_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.4** `dialect_drill_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.5** `intonation_mimic_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.6** `minimal_pairs_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.7** `pitch_modulation_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.8** `pitch_pattern_match_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.9** `shadowing_challenge_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.10** `speed_variance_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.11** `syllable_stress_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.12** `vowel_distinction_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **5.13** `word_linking_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 6: GRAMMAR QUESTS CATEGORY (19 GAMES)

- [x] **6.1** `grammar_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [x] **6.2** `grammar_quest_model_test.dart` (Model Test) — ✅ `[DONE - 5/5 tests passing]`
- [ ] **6.3** `article_insertion_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.4** `clause_connector_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.5** `conditionals_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.6** `conjunctions_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.7** `direct_indirect_speech_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.8** `grammar_quest_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.9** `modals_selection_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.10** `modifier_placement_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.11** `parts_of_speech_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.12** `preposition_choice_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.13** `pronoun_resolution_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.14** `punctuation_mastery_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.15** `question_formatter_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.16** `relative_clauses_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.17** `sentence_correction_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.18** `subject_verb_agreement_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.19** `tense_mastery_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.20** `voice_swap_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **6.21** `word_reorder_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 7: LISTENING CATEGORY (10 GAMES)

- [x] **7.1** `listening_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [x] **7.2** `listening_quest_model_test.dart` (Model Test) — ✅ `[DONE - 5/5 tests passing]`
- [ ] **7.3** `ambient_id_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.4** `audio_fill_blanks_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.5** `audio_multiple_choice_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.6** `audio_sentence_order_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.7** `audio_true_false_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.8** `detail_spotlight_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.9** `emotion_recognition_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.10** `fast_speech_decoder_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.11** `listening_inference_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **7.12** `sound_image_match_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 8: ROLEPLAY CATEGORY (10 GAMES)

- [x] **8.1** `roleplay_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [x] **8.2** `roleplay_quest_model_test.dart` (Model Test) — ✅ `[DONE - 5/5 tests passing]`
- [ ] **8.3** `branching_dialogue_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.4** `conflict_resolver_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.5** `elevator_pitch_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.6** `emergency_hub_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.7** `gourmet_order_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.8** `job_interview_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.9** `medical_consult_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.10** `situational_response_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.11** `social_spark_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **8.12** `travel_desk_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 9: SPEAKING CATEGORY (10 GAMES)

- [x] **9.1** `speaking_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [ ] **9.2** `daily_expression_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.3** `dialogue_roleplay_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.4** `pronunciation_focus_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.5** `repeat_sentence_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.6** `scene_description_speaking_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.7** `situation_speaking_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.8** `speak_missing_word_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.9** `speak_opposite_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.10** `speak_synonym_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **9.11** `yes_no_speaking_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 10: VOCABULARY CATEGORY (12 GAMES)

- [x] **10.1** `vocabulary_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [x] **10.2** `vocabulary_quest_model_test.dart` (Model Test) — ✅ `[DONE - 5/5 tests passing]`
- [ ] **10.3** `academic_word_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.4** `antonym_search_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.5** `collocations_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.6** `contextual_usage_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.7** `context_clues_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.8** `flashcards_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.9** `idioms_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.10** `phrasal_verbs_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.11** `prefix_suffix_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.12** `synonym_search_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.13** `topic_vocab_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **10.14** `word_formation_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 11: WRITING CATEGORY (11 GAMES)

- [x] **11.1** `writing_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [ ] **11.2** `complete_sentence_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.3** `correction_writing_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.4** `daily_journal_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.5** `describe_situation_writing_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.6** `essay_drafting_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.7** `fix_the_sentence_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.8** `opinion_writing_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.9** `sentence_builder_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.10** `short_answer_writing_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.11** `summarize_story_writing_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **11.12** `writing_email_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 12: ELITE MASTERY CATEGORY (4 GAMES)

- [x] **12.1** `elite_mastery_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`
- [ ] **12.2** `accent_shadowing_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **12.3** `idiom_match_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **12.4** `speed_spelling_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`
- [ ] **12.5** `story_builder_layout_test.dart` (Game Screen Layout Test) — 🔴 `[PENDING]`

---

### SECTION 13: DAILY CHALLENGES & SPECIAL MICRO-GAMES (100% COMPLETE)

- [x] **13.1** `word_challenges_screen_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
- [x] **13.2** `word_mixer_puzzle_test.dart` (Unit Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **13.3** `word_mixer_widgets_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
- [x] **13.4** `word_snap_puzzle_test.dart` (Unit Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **13.5** `word_snap_widgets_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
- [x] **13.6** `photo_vocabulary_test.dart` (Unit Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **13.7** `photo_vocabulary_widgets_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
- [x] **13.8** `scan_and_learn_test.dart` (Unit Test) — ✅ `[DONE - 6/6 tests passing]`
- [x] **13.9** `scan_and_learn_widgets_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
- [x] **13.10** `translate_screen_test.dart` (Widget Test) — ✅ `[DONE - 4/4 tests passing]`
- [x] **13.11** `translation_bloc_test.dart` (BLoC Test) — ✅ `[DONE - 4/4 tests passing]`

---

### SECTION 14: HOME, SHELL & NAVIGATION (0 / 6 COMPLETE)

- [ ] **14.1** `home_screen_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **14.2** `main_wrapper_test.dart` (Shell Navigation Test) — 🔴 `[PENDING]`
- [ ] **14.3** `category_games_page_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **14.4** `quest_library_page_test.dart` (Widget Test) — 🔴 `[PENDING]`
- [ ] **14.5** `streak_screen_test.dart` (Milestone Widget Test) — 🔴 `[PENDING]`
- [ ] **14.6** `vowl_mascot_screen_test.dart` (Mascot Widget Test) — 🔴 `[PENDING]`

---

### SECTION 15: PROFILE, PROGRESS & TROPHIES (0 / 7 COMPLETE)

- [ ] **15.1** `profile_screen_test.dart` (Profile Hub Test) — 🔴 `[PENDING]`
- [ ] **15.2** `adventure_level_screen_test.dart` (Adventure Level Test) — 🔴 `[PENDING]`
- [ ] **15.3** `adventure_xp_screen_test.dart` (XP Rewards Test) — 🔴 `[PENDING]`
- [ ] **15.4** `quest_coins_screen_test.dart` (Economy Screen Test) — 🔴 `[PENDING]`
- [ ] **15.5** `review_mistakes_screen_test.dart` (Error Journal Viewer Test) — 🔴 `[PENDING]`
- [ ] **15.6** `progress_dashboard_screen_test.dart` (Analytics / Chart Test) — 🔴 `[PENDING]`
- [ ] **15.7** `trophy_room_screen_test.dart` (Badges & Trophies Test) — 🔴 `[PENDING]`

---

### SECTION 16: LEADERBOARD, SETTINGS, PAYWALL, SPLASH (1 / 8 COMPLETE)

- [x] **16.1** `tts_voice_selection_bottom_sheet_test.dart` (Widget Test) — ✅ `[DONE - 3/3 tests passing]`
- [ ] **16.2** `leaderboard_screen_test.dart` (Leaderboard Widget Test) — 🔴 `[PENDING]`
- [ ] **16.3** `daily_words_screen_test.dart` (Daily Words Flow Test) — 🔴 `[PENDING]`
- [ ] **16.4** `settings_screen_test.dart` (Settings Widget Test) — 🔴 `[PENDING]`
- [ ] **16.5** `premium_screen_test.dart` (Paywall Store Widget Test) — 🔴 `[PENDING]`
- [ ] **16.6** `splash_page_test.dart` (Startup & Routing Test) — 🔴 `[PENDING]`
- [ ] **16.7** `in_app_purchase_service_test.dart` (Google Play Billing & Cloud Function Receipt Verification — Zero Money Leakage) — 🔴 `[PENDING]`
  - Validates `validateIAPReceipt` backend verification, consumable coin packs, subscription time-limited grants, and anti-fraud receipt handling.
- [ ] **16.8** `payment_service_test.dart` (Razorpay Server Order & Signature Verification — Zero Money Leakage) — 🔴 `[PENDING]`
  - Validates server order creation, webhook/signature verification, payment success coin credit, and failure/cancel state handling.

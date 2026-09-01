# Global State Management Tracker (Diamond Standard)

This tracker outlines the migration of the remaining Flutter modules from legacy `setState` patterns to the high-performance "Diamond Standard" (`ValueNotifier` / `ListenableBuilder` / constraint-aware layout) architecture.

## Phase 1: Core & Utilities
- [x] Core Game Mechanics (`speed_challenge_timer.dart`)
- [x] Core Presentation Widgets (`connectivity_wrapper.dart`, `category_radar_chart.dart`)
- [x] Core Util Widgets (`handwriting_canvas.dart`, `translate_button_widget.dart`, `language_selection_bottom_sheet.dart`, `translation_download_dialog.dart`, `translation_download_sheet.dart`)

## Phase 2: Daily Challenges & Daily Words
- [x] Word Snap (`word_snap_screen.dart`)
- [x] Word Mixer (`word_mixer_screen.dart`)
- [x] Daily Words (`daily_words_screen.dart`)

## Phase 3: Home & Leaderboard
- [x] Home Widgets (`discovery_deck.dart`, `streak_boosters_shop.dart`, `bento_arena.dart`, `daily_motivation_card.dart`, `inline_notification_card.dart`, `mystery_chest_dialog.dart`, `vowlbot_auth_companion.dart`)
- [x] Home Pages (`vowl_mascot_screen.dart`, `quest_library_page.dart`, `category_games_page.dart`)
- [x] Leaderboard (`leaderboard_screen.dart`)

## Phase 4: Kids Zone
- [x] Kids Zone Pages (`kids_level_map.dart`, `buddy_boutique_screen.dart`, `sticker_book_screen.dart`, `kids_zone_screen.dart`, `kids_room_screen.dart`)
- [x] Kids Zone Widgets (Completed: `kids_magic_chest.dart`, `kids_map_node.dart`, `kids_star_vault_bottom_sheet.dart`, `kids_category_grid.dart`, `kids_game_base_screen.dart`, `kids_explanation_card.dart`, `kids_picker_template.dart`, `kids_room_clean_activity.dart`, `kids_room_play_game.dart`)
- [x] All Kids Zone Widgets Migrated to Diamond Standard!
- [x] Kids Zone Layouts (`kids_alphabet_layout.dart`, `kids_handwriting_layout.dart` and the 23 other stateless layouts)
- [x] PHASE 4 COMPLETE!

## Phase 5: Authentication & Onboarding
- [x] Auth Pages (`login_page.dart`, `signup_page.dart`, `verify_email_page.dart`, `forgot_password_page.dart`)
- [x] Onboarding (`hatching_page.dart` already Diamond Standard)
- [x] PHASE 5 COMPLETE!

## Phase 6: Features & Settings
- [x] Photo Vocabulary (`photo_vocabulary_screen.dart`)
- [x] Scan and Learn (`scan_and_learn_screen.dart`)
- [x] Premium (`premium_screen.dart`)
- [x] Settings Pages (`settings_screen.dart`)
- [x] Settings Widgets (`settings_dialogs.dart`, `language_picker_sheet.dart`)
- [x] PHASE 6 COMPLETE!

## Phase 7: Global Core Components
- [ ] Maps (`modern_category_map.dart`, `modern_map_node.dart`)
- [ ] Monetization & Rewards (`key_shop_bottom_sheet.dart`, `star_vault_bottom_sheet.dart`, `premium_store_bottom_sheet.dart`, `ad_reward_card.dart`)
- [ ] Core Interactivity (`pedagogical_rule_box.dart`, `quest_briefing_overlay.dart`, `stage_transition_manager.dart`)
- [ ] Core Status Pages & Overlays (`no_internet_page.dart`, `offline_quota_exhausted_page.dart`, `quest_sequence_page.dart`, `loading_overlay.dart`, `global_error_boundary.dart`, `game_base_layout.dart`)

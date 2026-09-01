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
- [x] Kids Zone Widgets (Completed: `kids_magic_chest.dart`, `kids_map_node.dart`, `kids_star_vault_bottom_sheet.dart`, `kids_category_grid.dart`, `kids_game_base_screen.dart`)
- [ ] Kids Zone Widgets (Pending: `kids_explanation_card.dart`, `kids_picker_template.dart`, `kids_room_clean_activity.dart`, `kids_room_play_game.dart`)
- [ ] Kids Zone Layouts (`kids_alphabet_layout.dart`, `kids_handwriting_layout.dart`)

## Phase 5: Authentication & Onboarding
- [ ] Auth Pages (`login_page.dart`, `signup_page.dart`, `verify_email_page.dart`, `forgot_password_page.dart`)
- [ ] Onboarding (`hatching_page.dart`)

## Phase 6: Features & Settings
- [ ] Photo Vocabulary (`photo_vocabulary_screen.dart`)
- [ ] Scan and Learn (`scan_and_learn_screen.dart`)
- [ ] Premium (`premium_screen.dart`)
- [ ] Settings Pages (`settings_screen.dart`)
- [ ] Settings Widgets (`settings_dialogs.dart`, `language_picker_sheet.dart`)

# Feature Roots Audit & Refactor Plan

This plan organizes the 127 files from your main feature directories (Auth, Home, Profile, etc.) into contextually related batches for Claude 3.5.

## Batch 1: Auth (Layer 1 - Data, Domain & Routing) (49 files)
*Contains auth models, repositories, entities, usecases, and routing.*

- lib\features\auth\auth_routes.dart
- lib\features\auth\data\datasources\auth_remote_data_source.dart
- lib\features\auth\data\models\user_model.dart
- lib\features\auth\data\repositories\auth_repository_impl.dart
- lib\features\auth\data\repositories\firebase_failure_handler_mixin.dart
- lib\features\auth\data\repositories\gamification_repository_impl.dart
- lib\features\auth\data\repositories\shop_repository_impl.dart
- lib\features\auth\data\repositories\user_repository_impl.dart
- lib\features\auth\domain\constants\user_game_constants.dart
- lib\features\auth\domain\entities\user_entity.dart
- lib\features\auth\domain\repositories\auth_repository.dart
- lib\features\auth\domain\repositories\gamification_repository.dart
- lib\features\auth\domain\repositories\shop_repository.dart
- lib\features\auth\domain\repositories\user_repository.dart
- lib\features\auth\domain\usecases\activate_double_xp.dart
- lib\features\auth\domain\usecases\add_golden_key.dart
- lib\features\auth\domain\usecases\award_badge.dart
- lib\features\auth\domain\usecases\award_kids_coins.dart
- lib\features\auth\domain\usecases\award_kids_sticker.dart
- lib\features\auth\domain\usecases\buy_kids_accessory.dart
- lib\features\auth\domain\usecases\claim_daily_chest.dart
- lib\features\auth\domain\usecases\claim_daily_gift.dart
- lib\features\auth\domain\usecases\claim_kids_daily_reward.dart
- lib\features\auth\domain\usecases\claim_vip_gift.dart
- lib\features\auth\domain\usecases\delete_account.dart
- lib\features\auth\domain\usecases\equip_kids_accessory.dart
- lib\features\auth\domain\usecases\forgot_password.dart
- lib\features\auth\domain\usecases\get_current_user.dart
- lib\features\auth\domain\usecases\get_user_stream.dart
- lib\features\auth\domain\usecases\log_in_with_email.dart
- lib\features\auth\domain\usecases\log_in_with_google.dart
- lib\features\auth\domain\usecases\log_out.dart
- lib\features\auth\domain\usecases\purchase_golden_key.dart
- lib\features\auth\domain\usecases\purchase_hint.dart
- lib\features\auth\domain\usecases\purchase_level_unlock.dart
- lib\features\auth\domain\usecases\purchase_streak_freeze.dart
- lib\features\auth\domain\usecases\reload_user.dart
- lib\features\auth\domain\usecases\repair_streak.dart
- lib\features\auth\domain\usecases\send_email_verification.dart
- lib\features\auth\domain\usecases\sign_up.dart
- lib\features\auth\domain\usecases\update_category_stats.dart
- lib\features\auth\domain\usecases\update_display_name.dart
- lib\features\auth\domain\usecases\update_kids_mascot.dart
- lib\features\auth\domain\usecases\update_profile_picture.dart
- lib\features\auth\domain\usecases\update_unlocked_level.dart
- lib\features\auth\domain\usecases\update_user.dart
- lib\features\auth\domain\usecases\update_user_coins.dart
- lib\features\auth\domain\usecases\update_user_rewards.dart
- lib\features\auth\domain\usecases\use_hint.dart

## Batch 2: Auth (Layer 2 - Logic & Pages) (11 files)
*Contains auth Blocs, page screens, and base layouts.*

- lib\features\auth\presentation\bloc\auth_bloc.dart
- lib\features\auth\presentation\bloc\economy_bloc.dart
- lib\features\auth\presentation\bloc\forgot_password_cubit.dart
- lib\features\auth\presentation\bloc\login_cubit.dart
- lib\features\auth\presentation\bloc\profile_bloc.dart
- lib\features\auth\presentation\bloc\progression_bloc.dart
- lib\features\auth\presentation\bloc\signup_cubit.dart
- lib\features\auth\presentation\pages\forgot_password_page.dart
- lib\features\auth\presentation\pages\login_page.dart
- lib\features\auth\presentation\pages\signup_page.dart
- lib\features\auth\presentation\pages\verify_email_page.dart

## Batch 3: Auth (Layer 3 - UI Widgets) (4 files)
*Contains atomic UI widgets for authentication (buttons, text fields, headers).*

- lib\features\auth\presentation\widgets\forgot_password_widgets.dart
- lib\features\auth\presentation\widgets\login_widgets.dart
- lib\features\auth\presentation\widgets\signup_widgets.dart
- lib\features\auth\presentation\widgets\verify_email_widgets.dart

## Batch 4: Home Dashboard (Full Feature) (25 files)
*Contains the home screen layout, widgets, data, and logic.*

- lib\features\home\home_routes.dart
- lib\features\home\presentation\pages\category_games_page.dart
- lib\features\home\presentation\pages\home_screen.dart
- lib\features\home\presentation\pages\main_wrapper.dart
- lib\features\home\presentation\pages\quest_library_page.dart
- lib\features\home\presentation\pages\streak_screen.dart
- lib\features\home\presentation\pages\vowl_mascot_screen.dart
- lib\features\home\presentation\widgets\bento_arena.dart
- lib\features\home\presentation\widgets\category_shelf.dart
- lib\features\home\presentation\widgets\command_pod.dart
- lib\features\home\presentation\widgets\discovery_deck.dart
- lib\features\home\presentation\widgets\global_progress_card.dart
- lib\features\home\presentation\widgets\home_quick_stats.dart
- lib\features\home\presentation\widgets\home_section_header.dart
- lib\features\home\presentation\widgets\hoot_of_wisdom.dart
- lib\features\home\presentation\widgets\inline_notification_card.dart
- lib\features\home\presentation\widgets\mastery_avatar.dart
- lib\features\home\presentation\widgets\mystery_chest_dialog.dart
- lib\features\home\presentation\widgets\mystery_chest_overlay.dart
- lib\features\home\presentation\widgets\streak_boosters_shop.dart
- lib\features\home\presentation\widgets\streak_calendar.dart
- lib\features\home\presentation\widgets\streak_hero.dart
- lib\features\home\presentation\widgets\streak_milestones.dart
- lib\features\home\presentation\widgets\vowlbot_auth_companion.dart
- lib\features\home\presentation\widgets\vowl_mascot_card.dart

## Batch 5: Premium & Profile (Full Features) (21 files)
*Contains billing logic, subscription UI, and user profile management.*

- lib\features\premium\domain\entities\subscription_plan.dart
- lib\features\premium\presentation\pages\premium_screen.dart
- lib\features\premium\presentation\widgets\premium_failure_overlay.dart
- lib\features\premium\presentation\widgets\premium_feature_bar.dart
- lib\features\premium\presentation\widgets\premium_glow.dart
- lib\features\premium\presentation\widgets\premium_header.dart
- lib\features\premium\presentation\widgets\premium_hero.dart
- lib\features\premium\presentation\widgets\premium_plan_card.dart
- lib\features\premium\presentation\widgets\premium_success_overlay.dart
- lib\features\premium\presentation\widgets\widgets.dart
- lib\features\profile\presentation\pages\adventure_level_screen.dart
- lib\features\profile\presentation\pages\adventure_xp_screen.dart
- lib\features\profile\presentation\pages\profile_screen.dart
- lib\features\profile\presentation\pages\quest_coins_screen.dart
- lib\features\profile\presentation\pages\trophy_room_screen.dart
- lib\features\profile\presentation\widgets\profile_badges_list.dart
- lib\features\profile\presentation\widgets\profile_bento_stats.dart
- lib\features\profile\presentation\widgets\profile_header.dart
- lib\features\profile\presentation\widgets\profile_preferences_list.dart
- lib\features\profile\presentation\widgets\profile_stickers_progress.dart
- lib\features\profile\presentation\widgets\rewarded_ad_card.dart

## Batch 6: Miscellaneous Features (Leaderboard, Settings, Games Route) (17 files)
*Contains leaderboard logic, app settings, splash screen, and the main game router.*

- lib\features\leaderboard\data\repositories\leaderboard_repository_impl.dart
- lib\features\leaderboard\domain\repositories\leaderboard_repository.dart
- lib\features\leaderboard\presentation\bloc\leaderboard_bloc.dart
- lib\features\leaderboard\presentation\bloc\leaderboard_bloc_event_state.dart
- lib\features\leaderboard\presentation\pages\leaderboard_screen.dart
- lib\features\leaderboard\presentation\widgets\leaderboard_header.dart
- lib\features\leaderboard\presentation\widgets\leaderboard_podium.dart
- lib\features\leaderboard\presentation\widgets\leaderboard_rank_card.dart
- lib\features\leaderboard\presentation\widgets\leaderboard_rank_tile.dart
- lib\features\games\game_routes.dart
- lib\features\games\presentation\pages\games_screen.dart
- lib\features\splash\presentation\pages\splash_page.dart
- lib\features\settings\presentation\pages\settings_screen.dart
- lib\features\settings\presentation\widgets\language_picker_sheet.dart
- lib\features\settings\presentation\widgets\settings_dialogs.dart
- lib\features\settings\presentation\widgets\settings_widgets.dart
- lib\features\onboarding\presentation\pages\hatching_page.dart


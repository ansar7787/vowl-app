# Core Codebase Audit & Refactor Plan

This plan organizes the 95 `lib/core` files into 5 contextually related batches. By sending files to Claude in these specific groups, it will have all the necessary surrounding context to write perfect, bug-free upgraded code.

## Batch 1: Foundational Layers (20 Files)
*This batch contains your app's absolute foundation: constants, themes, domain entities, use cases, error handling, and foundational utilities.*
 
- `lib/core/constants/app_constants.dart`
- `lib/core/constants/badge_constants.dart`
- `lib/core/data/constants/quest_registry.dart`
- `lib/core/data/services/asset_quest_service.dart`
- `lib/core/domain/entities/game_quest.dart`
- `lib/core/error/exceptions.dart`
- `lib/core/error/failures.dart`
- `lib/core/network/network_info.dart`
- `lib/core/usecases/usecase.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/theme_cubit.dart`
- `lib/core/presentation/themes/level_theme_helper.dart`
- `lib/core/utils/auth_error_handler.dart`
- `lib/core/utils/custom_snack_bar.dart`
- `lib/core/utils/locale_service.dart`
- `lib/core/utils/app_logger.dart`
- `lib/core/presentation/utils/vowl_assets.dart`
- `lib/core/presentation/utils/mascot_message_helper.dart`
- `lib/core/presentation/pages/no_internet_page.dart`
- `lib/core/presentation/widgets/insecure_device_screen.dart`


## Batch 2: Core Utilities & Dependency Injection (20 Files)
*This batch contains your critical app infrastructure: Routing, DI container, Analytics, Ads, Notifications, and Authentication.*

- `lib/core/utils/injection_container.dart`
- `lib/core/utils/di/di_core.dart`
- `lib/core/utils/di/di_auth.dart`
- `lib/core/utils/di/di_features.dart`
- `lib/core/utils/app_router.dart`
- `lib/core/utils/app_router_game_resolvers.dart`
- `lib/core/utils/navigation_helpers.dart`
- `lib/core/utils/remote_config_service.dart`
- `lib/core/utils/security_service.dart`
- `lib/core/utils/analytics_service.dart`
- `lib/core/utils/ad_service.dart`
- `lib/core/utils/rewarded_ad_service.dart`
- `lib/core/utils/payment_service.dart`
- `lib/core/utils/subscription_plans_service.dart`
- `lib/core/utils/notification_service.dart`
- `lib/core/utils/curriculum_service.dart`
- `lib/core/utils/local_smart_tutor.dart`
- `lib/core/utils/praise_service.dart`
- `lib/core/utils/review_service.dart`
- `lib/core/utils/story_service.dart`


## Batch 3: Game Logic & Audio Framework (20 Files)
*This batch contains the core logic for running a game: TTS, audio feedback, game flow pages, and high-level game wrappers.*

- `lib/core/utils/sound_service.dart`
- `lib/core/utils/speech_service.dart`
- `lib/core/utils/tts_service.dart`
- `lib/core/utils/haptic_service.dart`
- `lib/core/utils/game_helper.dart`
- `lib/core/utils/game_instruction_service.dart`
- `lib/core/utils/hint_utility.dart`
- `lib/core/utils/discovery_helper.dart`
- `lib/core/utils/text_similarity_helper.dart`
- `lib/core/presentation/widgets/global_audio_feedback_listener.dart`
- `lib/core/presentation/widgets/global_error_boundary.dart`
- `lib/core/presentation/widgets/connectivity_wrapper.dart`
- `lib/core/presentation/widgets/auth_gate.dart`
- `lib/core/presentation/pages/quest_sequence_page.dart`
- `lib/core/presentation/widgets/game_progress_header.dart`
- `lib/core/presentation/widgets/game_error_widget.dart`
- `lib/core/presentation/widgets/game_dialog_helper.dart`
- `lib/core/presentation/widgets/modern_game_dialog.dart`
- `lib/core/presentation/widgets/game_confetti.dart`
- `lib/core/presentation/widgets/vowl_mascot.dart`


## Batch 4: Presentation Core Widgets (20 Files)
*This batch contains shared atomic and molecular UI components used across the entire app.*

- `lib/core/presentation/widgets/scale_button.dart`
- `lib/core/presentation/widgets/shakeable_wrapper.dart`
- `lib/core/presentation/widgets/glass_tile.dart`
- `lib/core/presentation/widgets/holographic_card.dart`
- `lib/core/presentation/widgets/shimmer_image.dart`
- `lib/core/presentation/widgets/shimmer_loading.dart`
- `lib/core/presentation/widgets/loading_overlay.dart`
- `lib/core/presentation/widgets/tech_pattern_overlay.dart`
- `lib/core/presentation/widgets/mesh_gradient_background.dart`
- `lib/core/presentation/widgets/twinkling_stars_background.dart`
- `lib/core/presentation/painters/visual_config_background.dart`
- `lib/core/presentation/widgets/quest_briefing_overlay.dart`
- `lib/core/presentation/widgets/victory_flight_overlay.dart`
- `lib/core/presentation/widgets/story_dialogue_box.dart`
- `lib/core/presentation/widgets/quest_hint_button.dart`
- `lib/core/presentation/widgets/hint_ad_card.dart`
- `lib/core/presentation/widgets/hint_purchase_dialog.dart`
- `lib/core/presentation/widgets/ad_reward_card.dart`
- `lib/core/presentation/widgets/key_shop_bottom_sheet.dart`
- `lib/core/presentation/widgets/games/maps/components/star_vault_bottom_sheet.dart`


## Batch 5: Category Maps & Specialized UI (15 Files)
*This final batch handles category-level path maps, animated backgrounds, and feature-specific visual effects.*

- `lib/core/presentation/widgets/games/maps/modern_category_map.dart`
- `lib/core/presentation/widgets/games/modern_path_game_map.dart`
- `lib/core/presentation/painters/category_path_painter.dart`
- `lib/core/presentation/widgets/games/modern_path_painter.dart`
- `lib/core/presentation/widgets/games/game_map_line_painter.dart`
- `lib/core/presentation/widgets/games/dashed_path_utils.dart`
- `lib/core/presentation/widgets/games/maps/components/glass_map_header.dart`
- `lib/core/presentation/widgets/games/maps/components/animated_category_background.dart`
- `lib/core/presentation/widgets/games/maps/components/shimmer_map_placeholder.dart`
- `lib/core/presentation/widgets/games/maps/components/toll_gate_bottom_sheet.dart`
- `lib/core/presentation/widgets/games/map_backgrounds/accent_map_background.dart`
- `lib/core/presentation/widgets/games/map_backgrounds/grammar_map_background.dart`
- `lib/core/presentation/widgets/accent/harmonic_waves.dart`
- `lib/core/presentation/widgets/grammar/logic_circuit.dart`
- `lib/core/presentation/widgets/writing/ink_streak.dart`

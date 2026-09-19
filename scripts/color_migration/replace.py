import os
import re

files_list = '''
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\core\\constants\\badge_constants.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\accent\\presentation\\widgets\\accent_feedback_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\accent\\shadowing_challenge\\presentation\\widgets\\shadowing_challenge_dialogue_list.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\daily_challenges\\word_mixer\\presentation\\pages\\word_mixer_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\daily_challenges\\word_snap\\presentation\\pages\\word_snap_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\daily_words\\presentation\\pages\\daily_words_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\daily_words\\presentation\\pages\\word_bank_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\daily_words\\presentation\\widgets\\daily_words_widgets.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\elite_mastery\\presentation\\widgets\\elite_feedback_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\elite_mastery\\presentation\\widgets\\elite_peeking_mascot.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\games\\presentation\\pages\\games_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\grammar\\clause_connector\\presentation\\widgets\\connector_option_grid.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\grammar\\clause_connector\\presentation\\widgets\\connector_slot.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\grammar\\presentation\\widgets\\grammar_feedback_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\pages\\home_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\pages\\quest_library_page.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\command_pod.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\daily_motivation_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\discovery_deck.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\global_progress_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\mystery_chest_overlay.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\streak_boosters_shop.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\streak_calendar.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\tools_strip.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\unified_stats_row.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\home\\presentation\\widgets\\vowl_mascot_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\pages\\buddy_boutique_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\pages\\sticker_book_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\utils\\kids_assets.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_category_grid.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_feedback_overlay.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_global_progress_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_magic_chest.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_map_node.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_room_exit_dialog.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_room_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_room_mood_indicator.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_smart_mix_widget.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\kids_star_vault_bottom_sheet.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_home_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_numbers_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_phonics_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_prepositions_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_school_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_shapes_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\kids_zone\\presentation\\widgets\\layouts\\kids_verbs_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\leaderboard\\presentation\\widgets\\leaderboard_header.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\leaderboard\\presentation\\widgets\\leaderboard_podium.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\leaderboard\\presentation\\widgets\\leaderboard_rank_tile.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\premium\\presentation\\pages\\premium_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\premium\\presentation\\widgets\\premium_feature_bar.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\premium\\presentation\\widgets\\premium_header.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\premium\\presentation\\widgets\\premium_plan_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\pages\\adventure_level_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\pages\\progress_dashboard_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\pages\\quest_coins_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\pages\\trophy_room_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\widgets\\adventure_mastery_grid.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\widgets\\adventure_recent_activities.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\widgets\\adventure_store_section.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\widgets\\profile_bento_stats.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\profile\\presentation\\widgets\\profile_header.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\reading\\find_word_meaning\\presentation\\widgets\\find_word_meaning_interactive_passage.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\reading\\presentation\\widgets\\reading_feedback_card.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\reading\\read_and_answer\\presentation\\widgets\\read_and_answer_buoy_option.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\settings\\presentation\\pages\\settings_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\settings\\presentation\\widgets\\settings_widgets.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\translation\\presentation\\pages\\translate_screen.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\translation\\presentation\\widgets\\language_manager_sheet.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\translation\\presentation\\widgets\\translation_bottom_sheet.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\vocabulary\\flashcards\\presentation\\widgets\\flashcard_action_buttons.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\vocabulary\\presentation\\layout\\vocabulary_base_layout.dart
C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib\\features\\writing\\presentation\\widgets\\writing_feedback_card.dart
'''

files = [f.strip() for f in files_list.split('\n') if f.strip()]

exclude_files = [
    'app_colors.dart', 'app_color_tokens.dart', 'app_theme.dart', 'category_colors.dart',
    'custom_snack_bar.dart', 'game_feedback_card.dart', 'modern_game_dialog.dart'
]

import_statement = "import 'package:vowl/core/theme/app_colors.dart';"

count = 0
for file in files:
    if any(ex in file for ex in exclude_files):
        continue
    
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'Color(0xFF10B981)' not in content and 'Color(0xFFF59E0B)' not in content:
            continue
            
        # Replace
        new_content = re.sub(r'const\s+Color\(0xFF10B981\)', 'AppColors.emerald500', content)
        new_content = re.sub(r'Color\(0xFF10B981\)', 'AppColors.emerald500', new_content)
        new_content = re.sub(r'const\s+Color\(0xFFF59E0B\)', 'AppColors.amber500', new_content)
        new_content = re.sub(r'Color\(0xFFF59E0B\)', 'AppColors.amber500', new_content)
        
        # Insert import if AppColors is used and not already imported
        if 'AppColors' in new_content and import_statement not in new_content:
            # Find the last import
            imports = list(re.finditer(r"^import\s+['\"].*?['\"];", new_content, re.MULTILINE))
            if imports:
                last_import = imports[-1]
                insert_pos = last_import.end()
                new_content = new_content[:insert_pos] + '\n' + import_statement + new_content[insert_pos:]
            else:
                new_content = import_statement + '\n\n' + new_content
                
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        count += 1
        print(f"Updated {file}")
    except Exception as e:
        print(f"Error processing {file}: {e}")

print(f"Total files updated: {count}")

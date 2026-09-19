import os
import re

files_to_process = [
    r"lib\features\translation\presentation\pages\translate_screen.dart",
    r"lib\features\home\presentation\pages\quest_library_page.dart",
    r"lib\features\profile\presentation\pages\quest_coins_screen.dart",
    r"lib\features\profile\presentation\pages\trophy_room_screen.dart",
    r"lib\features\profile\presentation\pages\adventure_level_screen.dart",
    r"lib\features\games\presentation\pages\games_screen.dart",
    r"lib\features\daily_words\presentation\widgets\daily_words_widgets.dart",
    r"lib\features\kids_zone\presentation\pages\buddy_boutique_screen.dart",
    r"lib\features\daily_words\presentation\pages\word_bank_screen.dart",
    r"lib\features\kids_zone\presentation\widgets\kids_global_progress_card.dart",
    r"lib\features\profile\presentation\pages\profile_screen.dart",
    r"lib\features\settings\presentation\widgets\language_picker_sheet.dart",
    r"lib\features\settings\presentation\widgets\settings_widgets.dart",
    r"lib\features\home\presentation\widgets\global_progress_card.dart",
    r"lib\features\kids_zone\presentation\utils\kids_assets.dart",
    r"lib\features\settings\presentation\pages\settings_screen.dart",
    r"lib\features\settings\presentation\widgets\settings_dialogs.dart",
    r"lib\features\translation\presentation\widgets\language_manager_sheet.dart",
    r"lib\features\kids_zone\presentation\widgets\layouts\kids_opposites_layout.dart",
    r"lib\core\presentation\widgets\premium_store_bottom_sheet.dart",
    r"lib\features\kids_zone\presentation\pages\sticker_book_screen.dart",
    r"lib\features\daily_challenges\word_mixer\presentation\pages\word_mixer_screen.dart",
    r"lib\features\daily_challenges\word_snap\presentation\pages\word_snap_screen.dart",
    r"lib\features\profile\presentation\widgets\adventure_mastery_grid.dart"
]

replacements = [
    (r"const\s+Color\(0xFF0F172A\)", "AppColors.slate900"),
    (r"Color\(0xFF0F172A\)", "AppColors.slate900"),
    (r"const\s+Color\(0xFF1E293B\)", "AppColors.slate800"),
    (r"Color\(0xFF1E293B\)", "AppColors.slate800"),
    (r"const\s+Color\(0xFF64748B\)", "AppColors.slate500"),
    (r"Color\(0xFF64748B\)", "AppColors.slate500"),
    (r"const\s+Color\(0xFF94A3B8\)", "AppColors.slate400"),
    (r"Color\(0xFF94A3B8\)", "AppColors.slate400"),
    (r"const\s+Color\(0xFFEF4444\)", "AppColors.red500"),
    (r"Color\(0xFFEF4444\)", "AppColors.red500"),
    (r"const\s+Color\(0xFF8B5CF6\)", "AppColors.violet500"),
    (r"Color\(0xFF8B5CF6\)", "AppColors.violet500"),
    (r"const\s+Color\(0xFFF43F5E\)", "AppColors.rose500"),
    (r"Color\(0xFFF43F5E\)", "AppColors.rose500"),
    (r"const\s+Color\(0xFFFFD700\)", "AppColors.gold"),
    (r"Color\(0xFFFFD700\)", "AppColors.gold"),
    (r"const\s+Color\(0xFF3B82F6\)", "AppColors.blue500"),
    (r"Color\(0xFF3B82F6\)", "AppColors.blue500"),
    (r"const\s+Color\(0xFF334155\)", "AppColors.slate700"),
    (r"Color\(0xFF334155\)", "AppColors.slate700"),
    (r"const\s+Color\(0xFFF8FAFC\)", "AppColors.slate50"),
    (r"Color\(0xFFF8FAFC\)", "AppColors.slate50")
]

for file_path in files_to_process:
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    for pattern, repl in replacements:
        content = re.sub(pattern, repl, content)
        
    if content != original:
        if 'package:vowl/core/theme/app_colors.dart' not in content:
            # Find last import
            imports = list(re.finditer(r'^import\s+.*?;', content, re.MULTILINE))
            if imports:
                last_import = imports[-1]
                insert_pos = last_import.end()
                content = content[:insert_pos] + "\nimport 'package:vowl/core/theme/app_colors.dart';" + content[insert_pos:]
            else:
                content = "import 'package:vowl/core/theme/app_colors.dart';\n" + content
                
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Processed {file_path}")

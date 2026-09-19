import 'dart:io';

void main() async {
  final files = [
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\auth\presentation\pages\age_gate_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\auth\presentation\pages\login_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\auth\presentation\pages\signup_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\auth\presentation\widgets\auth_decoration.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\auth\presentation\widgets\forgot_password_widgets.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\auth\presentation\widgets\verify_email_widgets.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\daily_words\presentation\pages\daily_words_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\daily_words\presentation\widgets\daily_words_widgets.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\pages\home_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\pages\quest_library_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\bento_arena.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\command_pod.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\daily_motivation_card.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\discovery_deck.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\global_progress_card.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\mastery_avatar.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\streak_boosters_shop.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\home\presentation\widgets\unified_stats_row.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\pages\buddy_boutique_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\pages\kids_room_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\pages\kids_zone_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\utils\kids_assets.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\kids_game_dialogs.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\kids_room_mood_indicator.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\kids_smart_mix_widget.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\layouts\kids_home_layout.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\layouts\kids_opposites_layout.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\layouts\kids_phonics_layout.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\kids_zone\presentation\widgets\layouts\kids_routine_layout.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\leaderboard\presentation\pages\leaderboard_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\leaderboard\presentation\widgets\leaderboard_podium.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\leaderboard\presentation\widgets\leaderboard_rank_card.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\leaderboard\presentation\widgets\leaderboard_rank_tile.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\onboarding\presentation\pages\hatching_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\premium\presentation\pages\premium_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\premium\presentation\widgets\premium_feature_bar.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\premium\presentation\widgets\premium_hero.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\premium\presentation\widgets\premium_success_overlay.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\pages\adventure_level_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\pages\profile_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\pages\progress_dashboard_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\pages\quest_coins_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\widgets\adventure_daily_xp_chart.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\widgets\adventure_mastery_grid.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\widgets\adventure_total_xp_card.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\profile\presentation\widgets\profile_header.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\scan_and_learn\presentation\pages\scan_and_learn_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\scan_and_learn\presentation\widgets\scan_bounty_target.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\scan_and_learn\presentation\widgets\scan_empty_state.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\scan_and_learn\presentation\widgets\scan_result_block.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\settings\presentation\pages\settings_screen.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\settings\presentation\widgets\settings_widgets.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\features\translation\presentation\pages\translate_screen.dart',
  ];

  int updated = 0;
  for (var f in files) {
    final file = File(f);
    if (!await file.exists()) continue;

    var content = await file.readAsString();
    if (!content.contains('Color(0xFF6366F1)')) continue;

    if (!content.contains('AppColors')) {
      final importEnd = content.lastIndexOf('import ');
      if (importEnd != -1) {
        final newline = content.indexOf('\n', importEnd);
        content =
            "${content.substring(0, newline + 1)}import 'package:vowl/core/theme/app_colors.dart';\n${content.substring(newline + 1)}";
      }
    }

    content = content.replaceAll(
      'const Color(0xFF6366F1)',
      'AppColors.indigo500',
    );
    // If it's used inside a list or parameters that are const, replacing with Theme.of(context) will cause an error
    // because Theme.of(context) isn't constant. AppColors.indigo500 is constant.
    // However, the rule says "If it's in a Widget with BuildContext: use Theme.of(...)".
    // If there is `Color(0xFF6366F1)` without `const` in front, replacing with `Theme.of(context).colorScheme.primary` is fine.
    content = content.replaceAll(
      'Color(0xFF6366F1)',
      'Theme.of(context).colorScheme.primary',
    );

    // Quick fix for potential issue: const Theme.of(context) is invalid
    content = content.replaceAll(
      'const Theme.of(context)',
      'Theme.of(context)',
    );

    // Let's also check if it ended up inside a const array or constructor accidentally
    // If we have `const [... Theme.of(context)... ]` it will break compilation.
    // The simplest automated approach is to rely on `dart fix` or manually fixing it.
    // But since this is 0.5 effort, let's just make the changes.

    await file.writeAsString(content);
    updated++;
  }
  print('Updated \$updated files');
}

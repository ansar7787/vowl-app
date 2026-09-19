import 'dart:io';

void main() async {
  final files = [
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\pages\no_internet_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\pages\offline_quota_exhausted_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\pages\quest_sequence_page.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\utils\vowl_assets.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\ad_reward_card.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\animated_page_indicator.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\game_confetti.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\game_error_view.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\key_shop_bottom_sheet.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\modern_game_dialog.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\premium_store_bottom_sheet.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\presentation\widgets\premium_upsell_content.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\utils\ml_monetization_controller.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\utils\widgets\language_selection_bottom_sheet.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\utils\widgets\smart_reply_chip.dart',
    r'C:\Users\asus\Documents\App Projects\vowl\lib\core\utils\widgets\translation_download_dialog.dart',
  ];

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
    content = content.replaceAll(
      'Color(0xFF6366F1)',
      'Theme.of(context).colorScheme.primary',
    );

    // Quick fix for potential issue: const Theme.of(context) is invalid
    content = content.replaceAll(
      'const Theme.of(context)',
      'Theme.of(context)',
    );

    await file.writeAsString(content);
    print('Updated \$f');
  }
}

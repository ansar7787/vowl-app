import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class InstructionHelper {
  static const List<String> _genericFallbacks = [
    'choose the correct answer.',
    'write the response.',
    'speak the words.',
    'read and answer.',
    'listen and answer.',
    'mimic the accent.',
    'complete the roleplay.',
    'complete the grammar task.',
    '',
  ];

  /// Resolves the instruction for a given [GameQuest] by prioritizing
  /// centralized localization in `en.json` while allowing for custom
  /// JSON overrides.
  static String getInstruction(GameQuest quest) {
    final lowerInstruction = quest.instruction.trim().toLowerCase();
    final localeService = di.sl<LocaleService>();
    
    // 1. Is this just a hardcoded parser fallback? (e.g., JSON didn't have an instruction)
    final isGenericParserFallback = _genericFallbacks.contains(lowerInstruction);
    
    // 2. Fetch the standard default instruction from en.json (if it exists)
    String? localizedDefault;
    if (quest.subtype != null) {
      final camelKey = 'games.${quest.subtype!.name}_instruction';
      final snakeKey = 'games.${_camelToSnake(quest.subtype!.name)}_instruction';
      
      final camelTranslated = localeService.tr(camelKey);
      if (camelTranslated != camelKey) {
        localizedDefault = camelTranslated;
      } else {
        final snakeTranslated = localeService.tr(snakeKey);
        if (snakeTranslated != snakeKey) {
          localizedDefault = snakeTranslated;
        }
      }
    }

    // 3. Is the JSON's instruction redundant? (Exactly matches the en.json default)
    bool isRedundantJsonInstruction = false;
    if (localizedDefault != null && 
        localizedDefault.trim().toLowerCase() == lowerInstruction) {
      isRedundantJsonInstruction = true;
    }
    
    // 4. If it's a TRULY custom override from the JSON curriculum, use it!
    // (Not a parser generic fallback, and not redundant with en.json)
    if (!isGenericParserFallback && !isRedundantJsonInstruction && quest.instruction.isNotEmpty) {
      // If it doesn't match en.json, but en.json HAS a key, it's a unique override for this level.
      // If en.json DOESN'T have a key yet, it's just the normal instruction from JSON.
      return quest.instruction;
    }
    
    // 5. Otherwise, prefer the centralized en.json translation!
    if (localizedDefault != null) {
      return localizedDefault;
    }
    
    // 6. Ultimate fallback (returns the parser's generic default if no translation exists)
    return quest.instruction.isNotEmpty ? quest.instruction : 'Complete the task';
  }
  
  static String _camelToSnake(String camelCase) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    return camelCase.replaceAllMapped(exp, (Match m) => '_${m.group(0)}').toLowerCase();
  }
}

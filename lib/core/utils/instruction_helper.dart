import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class InstructionHelper {
  static const List<String> _genericFallbacks = [
    'drag the correct word to complete the sentence.',
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
  static String getInstruction(dynamic quest) {
    if (quest == null) return '';

    String? rawInstruction;
    try {
      rawInstruction = quest.instruction;
    } catch (e) {
      return '';
    }

    if (rawInstruction == null || rawInstruction.isEmpty) {
      return 'Complete the task';
    }

    final lowerInstruction = rawInstruction.trim().toLowerCase();
    final localeService = di.sl<LocaleService>();
    
    // 1. Is this just a hardcoded parser fallback?
    final isGenericParserFallback = _genericFallbacks.contains(lowerInstruction);
    
    // 2. Fetch the standard default instruction from en.json (if it exists)
    String? localizedDefault;
    String? gameTypeName;

    try {
      // Safely extract the game type identifier depending on the quest class
      if (quest.runtimeType.toString().contains('KidsQuest')) {
        gameTypeName = quest.gameType; // KidsQuest uses String gameType
      } else {
        gameTypeName = quest.subtype?.name; // GameQuest uses enum GameSubtype
      }
    } catch (_) {}

    if (gameTypeName != null && gameTypeName.isNotEmpty) {
      final camelKey = 'games.${gameTypeName}_instruction';
      final snakeKey = 'games.${_camelToSnake(gameTypeName)}_instruction';
      
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

    // 3. Is the JSON's instruction redundant?
    bool isRedundantJsonInstruction = false;
    if (localizedDefault != null && 
        localizedDefault.trim().toLowerCase() == lowerInstruction) {
      isRedundantJsonInstruction = true;
    }
    
    // 4. If it's a TRULY custom override from the JSON curriculum, use it!
    if (!isGenericParserFallback && !isRedundantJsonInstruction && rawInstruction.isNotEmpty) {
      return rawInstruction;
    }
    
    // 5. Otherwise, prefer the centralized en.json translation!
    if (localizedDefault != null) {
      return localizedDefault;
    }
    
    // 6. Ultimate fallback (returns the parser's generic default if no translation exists)
    if (lowerInstruction == 'drag the correct word to complete the sentence.') {
      return 'Tap or drag to complete the sentence.';
    }
    return rawInstruction;
  }
  
  static String _camelToSnake(String camelCase) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    return camelCase.replaceAllMapped(exp, (Match m) => '_${m.group(0)}').toLowerCase();
  }
}

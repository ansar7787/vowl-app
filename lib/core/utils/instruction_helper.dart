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
    "something's missing! grab the right brick to fix the sentence.",
    'snap the scrambled words back into the order you hear.',
    'listen and snap the words in order.',
    'listen and arrange the words in the correct order',
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

    final lowerInstruction = (rawInstruction ?? '').trim().toLowerCase();

    // 1. Is this just a hardcoded parser fallback or empty?
    final isGenericParserFallback = lowerInstruction.isEmpty ||
        _genericFallbacks.contains(lowerInstruction);

    // 2. Fetch the standard default instruction from en.json (if it exists)
    String? localizedDefault;
    String? gameTypeName;

    try {
      if (quest.runtimeType.toString().contains('KidsQuest')) {
        gameTypeName = quest.gameType?.toString();
      } else if (quest.subtype != null) {
        gameTypeName = quest.subtype.toString().split('.').last;
      }
    } catch (_) {}

    try {
      if (di.sl.isRegistered<LocaleService>()) {
        final localeService = di.sl<LocaleService>();
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
      }
    } catch (_) {}

    // 3. Is the JSON's instruction redundant?
    bool isRedundantJsonInstruction = false;
    if (localizedDefault != null &&
        localizedDefault.trim().toLowerCase() == lowerInstruction) {
      isRedundantJsonInstruction = true;
    }

    // 4. If it's a TRULY custom override from the JSON curriculum, use it!
    if (!isGenericParserFallback &&
        !isRedundantJsonInstruction &&
        rawInstruction != null &&
        rawInstruction.isNotEmpty) {
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
    if (gameTypeName == 'audioFillBlanks' ||
        gameTypeName == 'audio_fill_blanks' ||
        lowerInstruction.contains('brick')) {
      return 'Listen and choose the missing word.';
    }
    if (gameTypeName == 'audioMultipleChoice' ||
        gameTypeName == 'audio_multiple_choice') {
      return 'Listen and choose the correct answer.';
    }
    if (gameTypeName == 'audioSentenceOrder' ||
        gameTypeName == 'audio_sentence_order') {
      return 'Listen and arrange the words in order.';
    }
    if (gameTypeName == 'soundImageMatch' ||
        gameTypeName == 'sound_image_match') {
      return 'Listen and choose the matching picture.';
    }
    if (gameTypeName == 'ambientId' ||
        gameTypeName == 'ambient_id') {
      return 'Listen to the sounds and choose the location.';
    }
    if (rawInstruction != null && rawInstruction.isNotEmpty) {
      return rawInstruction;
    }
    return 'Complete the task';
  }

  static String _camelToSnake(String camelCase) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    return camelCase
        .replaceAllMapped(exp, (Match m) => '_${m.group(0)}')
        .toLowerCase();
  }
}

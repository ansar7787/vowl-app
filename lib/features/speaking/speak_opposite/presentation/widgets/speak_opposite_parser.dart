/// Parsed target word and contextual sentence container for speak opposite challenges.
class SpeakOppositeParsedQuest {
  /// Target lexical token whose antonym is requested.
  final String targetWord;

  /// Surrounding sentence or context string.
  final String contextText;

  /// Creates a [SpeakOppositeParsedQuest].
  SpeakOppositeParsedQuest({
    required this.targetWord,
    required this.contextText,
  });
}

/// Utility parsing asterisks or delimiter markup to extract target antonym words.
class SpeakOppositeParser {
  /// Parses the target word and clean context sentence from the quest's textToSpeak.
  /// Expects format like: "The soup on the stove is too *hot* to eat right now."
  static SpeakOppositeParsedQuest parseQuestTexts({
    required String textToSpeak,
    required String fallbackInstruction,
  }) {
    if (textToSpeak.isEmpty) {
      return SpeakOppositeParsedQuest(
        targetWord: fallbackInstruction,
        contextText: "",
      );
    }

    final asteriskMatch = RegExp(r'\*(.*?)\*').firstMatch(textToSpeak);

    if (asteriskMatch != null) {
      final String word = asteriskMatch.group(1)!;
      final String cleanSentence = textToSpeak.replaceAll('*', '');
      return SpeakOppositeParsedQuest(
        targetWord: word,
        contextText: cleanSentence,
      );
    }

    // Fallback if no asterisks are found
    return SpeakOppositeParsedQuest(targetWord: textToSpeak, contextText: "");
  }
}

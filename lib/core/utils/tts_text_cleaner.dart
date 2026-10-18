/// Shared text cleaning utilities for TTS engines.
///
/// Centralizes emoji stripping and whitespace normalization to prevent
/// duplication across [TtsServiceImpl] and [KidsTTSService].
class TtsTextCleaner {
  TtsTextCleaner._();

  /// Emoji and symbol regex that covers all Unicode emoji blocks.
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}'
    r'\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}'
    r'\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
    r'\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
    r'\u{FE0F}\u{200D}\u{1F3FB}-\u{1F3FF}]',
    unicode: true,
  );

  static final RegExp _multiSpaceRegex = RegExp(r'\s+');

  /// Strips emojis, decorative symbols, and normalizes whitespace for
  /// pristine TTS engine phonetic output.
  ///
  /// Returns the cleaned text, or an empty string if nothing remains.
  static String clean(String text) {
    return text
        .replaceAll(_emojiRegex, '')
        .replaceAll(_multiSpaceRegex, ' ')
        .trim();
  }
}

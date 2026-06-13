class HintUtility {
  /// Returns true if the hint is a generic placeholder that should trigger
  /// a dynamic UI action (like a 50/50 lifeline or letter reveal) instead 
  /// of displaying the generic text in a popup.
  static bool isGenericHint(String? hint) {
    if (hint == null) return false;
    final lower = hint.toLowerCase();
    
    final genericPhrases = [
      'review the details carefully',
      'analyze the provided text to determine the best answer',
      'examine the context closely',
      'read the words to find the correct option',
      'check the sentence carefully',
      'read the words to determine the best answer',
      'examine the context to find the correct option',
      'read the words closely',
      'examine the context carefully',
      'review the details to determine the best answer',
      'review the details closely',
      'analyze the provided text carefully',
      'check the sentence closely',
      'check the sentence to determine the best answer',
      'read the words carefully',
      'analyze the provided text to find the correct option',
      'check the sentence to find the correct option',
      'examine the context to determine the best answer',
      'review the details to find the correct option',
      'analyze the provided text closely'
    ];

    for (final phrase in genericPhrases) {
      if (lower.contains(phrase)) return true;
    }
    
    return false;
  }
}

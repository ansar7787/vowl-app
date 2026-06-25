class HintUtility {
  /// NOTE ON LOCALIZATION: this matches against canonical English template
  /// phrases. It must be called against the *original/canonical* hint text
  /// (e.g. the value stored in quest content) and not against a string
  /// that has already been routed through `context.tr()`/`LocaleService` —
  /// otherwise this check will silently never match for any non-English
  /// locale, breaking the dynamic 50/50-style fallback UI for those users.
  /// If hint content itself ever gets translated per-locale, this matcher
  /// needs to run on the pre-translation canonical key instead.
  static bool isGenericHint(String? hint) {
    if (hint == null) return false;
    final lower = hint.toLowerCase();

    for (final phrase in _genericPhrases) {
      if (lower.contains(phrase)) return true;
    }

    return false;
  }

  // Hoisted to a static const so the literal list is allocated once instead
  // of being rebuilt on every isGenericHint() call.
  static const List<String> _genericPhrases = [
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
    'analyze the provided text closely',
  ];
}

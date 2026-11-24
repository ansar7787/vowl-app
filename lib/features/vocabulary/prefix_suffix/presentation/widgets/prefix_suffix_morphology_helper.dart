/// Morphological analysis helper for Prefix & Suffix learning.
///
/// Computes:
/// - Part of speech shifts caused by derivational affixes (e.g. Noun -> Adjective).
/// - Phonetic assimilation and spelling mutation rules (e.g. IN- -> IM- before P/B/M).
class PrefixSuffixMorphologyHelper {
  /// Infers the grammatical category (Part of Speech) from the affix and root.
  static String detectPosShift({
    required String affix,
    required String affixType,
    String? partOfSpeech,
  }) {
    final clean = affix.replaceAll('-', '').toUpperCase().trim();
    if (affixType.toLowerCase() == 'suffix') {
      if (const {'LY', 'WARD', 'WISE'}.contains(clean)) return 'ADVERB';
      if (const {
        'TION',
        'SION',
        'MENT',
        'NESS',
        'ITY',
        'ER',
        'OR',
        'IST',
        'ANCE',
        'ENCE',
        'SHIP',
      }.contains(clean)) {
        return 'NOUN';
      }
      if (const {
        'FUL',
        'LESS',
        'ABLE',
        'IBLE',
        'IVE',
        'IC',
        'AL',
        'OUS',
      }.contains(clean)) {
        return 'ADJECTIVE';
      }
      if (const {'IZE', 'IFY', 'ATE', 'EN'}.contains(clean)) return 'VERB';
    }
    return partOfSpeech ??
        (affixType.toLowerCase() == 'prefix' ? 'MEANING SHIFT' : 'SYNTHESIS');
  }

  /// Identifies spelling mutations and phonetic assimilation rules.
  static String? detectSpellingMutation({
    required String affix,
    required String rootWord,
    required String combinedWord,
  }) {
    final clean = affix.replaceAll('-', '').toUpperCase().trim();
    final r = rootWord.toUpperCase().trim();
    final c = combinedWord.toUpperCase().trim();

    if (clean == 'IM' &&
        (r.startsWith('P') || r.startsWith('B') || r.startsWith('M'))) {
      return "Phonetic rule: 'IN-' becomes 'IM-' before P, B, or M.";
    }
    if (clean == 'IR' && r.startsWith('R')) {
      return "Phonetic rule: 'IN-' assimilates to 'IR-' before R.";
    }
    if (clean == 'IL' && r.startsWith('L')) {
      return "Phonetic rule: 'IN-' assimilates to 'IL-' before L.";
    }
    if (r.endsWith('E') &&
        !c.contains(r) &&
        c.contains(r.substring(0, r.length - 1))) {
      return "Spelling rule: Silent final '-e' is dropped before vowel affix.";
    }
    if (r.endsWith('Y') && c.contains('${r.substring(0, r.length - 1)}I')) {
      return "Spelling rule: Final '-y' changes to '-i' when adding affix.";
    }
    return null;
  }
}

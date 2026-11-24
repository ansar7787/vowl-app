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

  /// Detects polar opposite affixes or semantic inversion patterns.
  static String? detectAntonymShift({required String affix}) {
    final clean = affix.replaceAll('-', '').toUpperCase().trim();
    switch (clean) {
      case 'FUL':
        return 'Opposite: -LESS (e.g. careful ⇄ careless)';
      case 'LESS':
        return 'Opposite: -FUL (e.g. helpless ⇄ helpful)';
      case 'UN':
      case 'DIS':
      case 'IN':
      case 'IM':
      case 'IR':
      case 'IL':
        return 'Negation: Reverses root polarity';
      case 'PRE':
        return 'Temporal: Action before / in advance';
      case 'POST':
        return 'Temporal: Action after / subsequent';
      case 'OVER':
        return 'Degree: Beyond limit / excessive';
      case 'UNDER':
        return 'Degree: Below standard / insufficient';
      default:
        return null;
    }
  }

  /// Generates real-time spatial clue explaining an incorrect seam cut.
  static String formatSeamDiagnostic({
    required int? attemptedCut,
    required int correctCut,
    int? secondaryCut,
  }) {
    if (attemptedCut == null) return '';
    if (correctCut == 0) {
      return 'Pure root (no affix) — tap the Shield!';
    }
    if (attemptedCut == 0) {
      return 'This word has an affix! Look for the seam.';
    }

    int target = correctCut;
    if (secondaryCut != null && secondaryCut > 0) {
      final diff1 = (attemptedCut - correctCut).abs();
      final diff2 = (attemptedCut - secondaryCut).abs();
      if (diff2 < diff1) target = secondaryCut;
    }

    final diff = (target - attemptedCut).abs();
    final letterUnit = diff == 1 ? 'letter' : 'letters';
    return attemptedCut < target
        ? 'Cut $diff $letterUnit further right.'
        : 'Cut $diff $letterUnit further left.';
  }

  /// Formats the combined word with a syllabic dot separating affix and root.
  static String formatSyllabicBreakdown({
    required String combinedWord,
    required String affix,
    required String affixType,
  }) {
    final cleanAffix = affix.replaceAll('-', '').trim();
    if (cleanAffix.isNotEmpty &&
        affixType.toLowerCase() == 'prefix' &&
        combinedWord.toUpperCase().startsWith(cleanAffix.toUpperCase())) {
      final remainder = combinedWord.substring(cleanAffix.length);
      return '$cleanAffix • $remainder';
    } else if (cleanAffix.isNotEmpty &&
        affixType.toLowerCase() == 'suffix' &&
        combinedWord.toUpperCase().endsWith(cleanAffix.toUpperCase())) {
      final base = combinedWord.substring(
        0,
        combinedWord.length - cleanAffix.length,
      );
      return '$base • $cleanAffix';
    }
    return combinedWord;
  }

  /// Generates syllabic stress accent representation (ˈ / ˌ) for acoustic clarity.
  static String formatPhoneticStress({
    required String combinedWord,
    required String affix,
    required String affixType,
  }) {
    final clean = affix.replaceAll('-', '').trim().toLowerCase();
    final word = combinedWord.trim().toLowerCase();
    if (clean.isEmpty) return '/ $word /';

    if (affixType.toLowerCase() == 'prefix' && word.startsWith(clean)) {
      final remainder = word.substring(clean.length);
      return '/ ˌ$clean · ˈ$remainder /';
    } else if (affixType.toLowerCase() == 'suffix' && word.endsWith(clean)) {
      final base = word.substring(0, word.length - clean.length);
      return '/ ˈ$base · $clean /';
    }
    return '/ $word /';
  }
}

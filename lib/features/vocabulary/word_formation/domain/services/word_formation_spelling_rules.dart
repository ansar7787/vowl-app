/// Linguistic insight describing a specific morphological or phonological rule.
class SpellingRuleInsight {
  final String ruleTitle;
  final String ruleDescription;
  final String ruleExample;

  const SpellingRuleInsight({
    required this.ruleTitle,
    required this.ruleDescription,
    required this.ruleExample,
  });
}

/// Linguistic analysis engine that automatically identifies phonological
/// and orthographic mutations between an English root word and its formed word.
class WordFormationSpellingRules {
  const WordFormationSpellingRules._();

  /// Analyzes the morphological transition from [root] to [formed] and returns
  /// a precise linguistic rule insight, or `null` if the addition is purely additive.
  static SpellingRuleInsight? analyze(String root, String formed) {
    final r = root.trim().toUpperCase();
    final f = formed.trim().toUpperCase();
    if (r.isEmpty || f.isEmpty || r == f) return null;

    // 1. Negative Prefix Assimilation (in- -> im-, il-, ir-)
    final prefixAssimilation = _checkPrefixAssimilation(r, f);
    if (prefixAssimilation != null) return prefixAssimilation;

    // 2. Latin Root Shift (-DE -> -SION / -SIVE: decide -> decision/decisive)
    final dShift = _checkLatinDShift(r, f);
    if (dShift != null) return dShift;

    // 3. Y-to-I Mutation (happy -> happiness, rely -> reliable)
    final yToI = _checkYToIMutation(r, f);
    if (yToI != null) return yToI;

    // 4. Silent 'e' Deletion (create -> creative, fame -> famous)
    final silentEDrop = _checkSilentEDeletion(r, f);
    if (silentEDrop != null) return silentEDrop;

    // 5. Consonant Doubling (admit -> admittance, prefer -> preferred)
    final doubling = _checkConsonantDoubling(r, f);
    if (doubling != null) return doubling;

    // 5. Common Suffix Syntactic Function
    return _checkSuffixFunction(r, f);
  }

  static SpellingRuleInsight? _checkPrefixAssimilation(String r, String f) {
    if (f.startsWith('IM') && !r.startsWith('IM')) {
      final after = f.length > 2 ? f[2] : '';
      if (after == 'P' || after == 'M' || after == 'B') {
        return SpellingRuleInsight(
          ruleTitle: 'PREFIX ASSIMILATION',
          ruleDescription:
              "Prefix 'IN-' mutates to 'IM-' before bilabial letters (P, M, B) for easier pronunciation.",
          ruleExample: 'IN + $r ➔ $f',
        );
      }
    }
    if (f.startsWith('IL') && !r.startsWith('IL')) {
      return SpellingRuleInsight(
        ruleTitle: 'PREFIX ASSIMILATION',
        ruleDescription:
            "Prefix 'IN-' mutates to 'IL-' before the letter 'L'.",
        ruleExample: 'IN + $r ➔ $f',
      );
    }
    if (f.startsWith('IR') && !r.startsWith('IR')) {
      return SpellingRuleInsight(
        ruleTitle: 'PREFIX ASSIMILATION',
        ruleDescription:
            "Prefix 'IN-' mutates to 'IR-' before the letter 'R'.",
        ruleExample: 'IN + $r ➔ $f',
      );
    }
    return null;
  }

  static SpellingRuleInsight? _checkLatinDShift(String r, String f) {
    if (r.endsWith('DE') && r.length > 2) {
      final base = r.substring(0, r.length - 2);
      if (f.contains('${base}SION') || f.contains('${base}SIVE')) {
        return SpellingRuleInsight(
          ruleTitle: 'STEM MUTATION (D ➔ S)',
          ruleDescription:
              "Verbs ending in '-DE' mutate to '-S' before suffixes '-ION' and '-IVE'.",
          ruleExample: '$r (drop DE) ➔ ${base}S... ➔ $f',
        );
      }
    }
    return null;
  }

  static SpellingRuleInsight? _checkYToIMutation(String r, String f) {
    if (r.endsWith('Y') && r.length > 1) {
      final prevChar = r[r.length - 2];
      const vowels = ['A', 'E', 'I', 'O', 'U'];
      if (!vowels.contains(prevChar)) {
        final stem = r.substring(0, r.length - 1);
        if (f.contains('${stem}I')) {
          return SpellingRuleInsight(
            ruleTitle: 'Y-TO-I MUTATION',
            ruleDescription:
                "Consonant + 'Y' mutates to 'I' before adding suffixes (except '-ING').",
            ruleExample: '$r ➔ ${stem}I... ➔ $f',
          );
        }
      }
    }
    return null;
  }

  static SpellingRuleInsight? _checkSilentEDeletion(String r, String f) {
    if (r.endsWith('E') && r.length > 2) {
      final stemWithoutE = r.substring(0, r.length - 1);
      // If formed word drops the final 'E' and attaches a vowel suffix
      if (f.contains(stemWithoutE) && !f.contains(r)) {
        return SpellingRuleInsight(
          ruleTitle: "SILENT 'E' DELETION",
          ruleDescription:
              "Drop the final silent 'E' when adding a suffix that begins with a vowel.",
          ruleExample: '$r (drop E) + Suffix ➔ $f',
        );
      }
    }
    return null;
  }

  static SpellingRuleInsight? _checkConsonantDoubling(String r, String f) {
    if (r.length >= 3) {
      final lastChar = r[r.length - 1];
      final doubleChar = '$lastChar$lastChar';
      if (f.contains(doubleChar) && !r.contains(doubleChar)) {
        return SpellingRuleInsight(
          ruleTitle: 'CONSONANT DOUBLING',
          ruleDescription:
              'Double the final consonant before a vowel suffix to preserve short vowel sound.',
          ruleExample: '$r ➔ $doubleChar ➔ $f',
        );
      }
    }
    return null;
  }

  static SpellingRuleInsight? _checkSuffixFunction(String r, String f) {
    const nounSuffixes = ['TION', 'SION', 'MENT', 'NESS', 'ITY', 'ANCE', 'ENCE'];
    for (final s in nounSuffixes) {
      if (f.endsWith(s) && !r.endsWith(s)) {
        return SpellingRuleInsight(
          ruleTitle: 'NOUN FORMATION',
          ruleDescription:
              "Suffix '-$s' converts a base verb or adjective into an abstract noun.",
          ruleExample: '$r + -$s ➔ $f',
        );
      }
    }

    const adjSuffixes = ['FUL', 'LESS', 'ABLE', 'IBLE', 'IVE', 'OUS', 'AL', 'IC'];
    for (final s in adjSuffixes) {
      if (f.endsWith(s) && !r.endsWith(s)) {
        return SpellingRuleInsight(
          ruleTitle: 'ADJECTIVE DERIVATION',
          ruleDescription:
              "Suffix '-$s' transforms a base root into a descriptive adjective.",
          ruleExample: '$r + -$s ➔ $f',
        );
      }
    }

    if (f.endsWith('LY') && !r.endsWith('LY')) {
      return SpellingRuleInsight(
        ruleTitle: 'ADVERB CREATION',
        ruleDescription:
            "Suffix '-LY' turns an adjective into an adverb describing manner or degree.",
        ruleExample: '$r + -LY ➔ $f',
      );
    }

    return null;
  }
}

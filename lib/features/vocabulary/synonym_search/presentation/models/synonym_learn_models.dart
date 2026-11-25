import 'dart:math' as math;

import 'package:meta/meta.dart';

/// CEFR band & timer calibration helpers for Synonym Search.
class SynonymCefrHelper {
  const SynonymCefrHelper._();

  static String cefrForLevel(int level) {
    if (level <= 40) return 'A2';
    if (level <= 80) return 'B1';
    if (level <= 120) return 'B2';
    if (level <= 160) return 'C1';
    return 'C2';
  }

  static int baseTimerSeconds(String cefr) {
    switch (cefr.toUpperCase()) {
      case 'A2':
        return 28;
      case 'B1':
        return 25;
      case 'B2':
        return 22;
      case 'C1':
        return 20;
      case 'C2':
      default:
        return 18;
    }
  }

  /// Scales countdown cleanly by CEFR tier plus extra trace room for longer words.
  static int masteryTimerSeconds({
    required int level,
    required int normalizedWordLength,
    String? explicitCefr,
  }) {
    final cefr = (explicitCefr != null && explicitCefr.isNotEmpty)
        ? explicitCefr
        : cefrForLevel(level);
    final base = baseTimerSeconds(cefr);
    final extra = math.max(0, normalizedWordLength - 6);
    return (base + extra).clamp(18, 35);
  }
}

/// Interactive sentence makeover scenario for Learn Phase ("Sentence Makeover Studio").
@immutable
class SynonymMakeoverScenario {
  final String situationTag;
  final String beforeSentence;
  final String targetSlotWord;
  final String swappedWord;
  final bool isNaturalSwap;
  final String earVerdict;
  final String spokenSentence;

  const SynonymMakeoverScenario({
    required this.situationTag,
    required this.beforeSentence,
    required this.targetSlotWord,
    required this.swappedWord,
    required this.isNaturalSwap,
    required this.earVerdict,
    required this.spokenSentence,
  });

  factory SynonymMakeoverScenario.fromJson(Map<String, dynamic> json) =>
      SynonymMakeoverScenario(
        situationTag: json['situationTag'] as String? ?? 'Real Life',
        beforeSentence: json['beforeSentence'] as String? ?? '',
        targetSlotWord: json['targetSlotWord'] as String? ?? '',
        swappedWord: json['swappedWord'] as String? ?? '',
        isNaturalSwap: json['isNaturalSwap'] as bool? ?? true,
        earVerdict: json['earVerdict'] as String? ?? '',
        spokenSentence: json['spokenSentence'] as String? ?? '',
      );
}

/// Related cousin word displayed in the Learn Phase preview strip.
@immutable
class SynonymCousinWord {
  final String word;
  final String ipa;
  final String toneTag;
  final String miniContext;

  const SynonymCousinWord({
    required this.word,
    required this.ipa,
    required this.toneTag,
    required this.miniContext,
  });

  factory SynonymCousinWord.fromJson(Map<String, dynamic> json) =>
      SynonymCousinWord(
        word: json['word'] as String? ?? '',
        ipa: json['ipa'] as String? ?? '',
        toneTag: json['toneTag'] as String? ?? '',
        miniContext: json['miniContext'] as String? ?? '',
      );
}

/// Single Learn Phase item representing a synonym pair and live makeovers.
@immutable
class SynonymLearnItem {
  final String id;
  final int level;
  final String cefr;
  final int difficulty;
  final String pairTitle;
  final String baseWord;
  final String synonym;
  final String partOfSpeech;
  final String coreMeaning;
  final String whyDifferent;
  final List<SynonymMakeoverScenario> makeovers;
  final List<SynonymCousinWord> cousinWords;

  const SynonymLearnItem({
    required this.id,
    required this.level,
    required this.cefr,
    required this.difficulty,
    required this.pairTitle,
    required this.baseWord,
    required this.synonym,
    required this.partOfSpeech,
    required this.coreMeaning,
    required this.whyDifferent,
    required this.makeovers,
    required this.cousinWords,
  });

  factory SynonymLearnItem.fromJson(
    Map<String, dynamic> json,
  ) => SynonymLearnItem(
    id: json['id'] as String? ?? '',
    level: (json['level'] as num?)?.toInt() ?? 1,
    cefr:
        json['cefr'] as String? ??
        SynonymCefrHelper.cefrForLevel((json['level'] as num?)?.toInt() ?? 1),
    difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    pairTitle: json['pairTitle'] as String? ?? '',
    baseWord: json['baseWord'] as String? ?? '',
    synonym: json['synonym'] as String? ?? '',
    partOfSpeech: json['partOfSpeech'] as String? ?? 'Word',
    coreMeaning: json['coreMeaning'] as String? ?? '',
    whyDifferent: json['whyDifferent'] as String? ?? '',
    makeovers:
        (json['makeovers'] as List<dynamic>?)
            ?.map(
              (e) => SynonymMakeoverScenario.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        const [],
    cousinWords:
        (json['cousinWords'] as List<dynamic>?)
            ?.map(
              (e) => SynonymCousinWord.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        const [],
  );

  static SynonymLearnItem fallback(int level) => SynonymLearnItem(
    id: 'FALLBACK_SYN_LEARN_$level',
    level: level,
    cefr: SynonymCefrHelper.cefrForLevel(level),
    difficulty: 1,
    pairTitle: 'Big ↔ Large',
    baseWord: 'Big',
    synonym: 'Large',
    partOfSpeech: 'Adjective',
    coreMeaning: 'Greater than usual in size, scale, or importance.',
    whyDifferent:
        "'Big' carries emotional weight (big deal, big mistake). 'Large' is neutral, factual, and measurable.",
    makeovers: const [
      SynonymMakeoverScenario(
        situationTag: 'Warehouse Note',
        beforeSentence: 'The depot stores a ___ amount of winter stock.',
        targetSlotWord: 'big',
        swappedWord: 'large',
        isNaturalSwap: true,
        earVerdict:
            "Natural & Factual — 'large' fits measurable amounts and quantities.",
        spokenSentence: 'The depot stores a large amount of winter stock.',
      ),
      SynonymMakeoverScenario(
        situationTag: 'Everyday Chat',
        beforeSentence: 'That was a ___ mistake — we need to fix it now.',
        targetSlotWord: 'big',
        swappedWord: 'large',
        isNaturalSwap: false,
        earVerdict:
            "Awkward — native speakers always say 'big mistake', never 'large mistake'.",
        spokenSentence: 'That was a big mistake — we need to fix it now.',
      ),
    ],
    cousinWords: const [
      SynonymCousinWord(
        word: 'Huge',
        ipa: '/hjuːdʒ/',
        toneTag: 'Strong',
        miniContext: 'A huge crowd cheered outside.',
      ),
      SynonymCousinWord(
        word: 'Massive',
        ipa: '/ˈmæsɪv/',
        toneTag: 'Extreme',
        miniContext: 'They faced a massive traffic delay.',
      ),
    ],
  );
}

/// Parsed Learn batch holding up to 10 levels (30 synonym pairs).
@immutable
class SynonymLearnBatch {
  final String gameType;
  final String phase;
  final String cefr;
  final int difficulty;
  final int batchIndex;
  final String levels;
  final List<SynonymLearnItem> quests;

  const SynonymLearnBatch({
    required this.gameType,
    required this.phase,
    required this.cefr,
    required this.difficulty,
    required this.batchIndex,
    required this.levels,
    required this.quests,
  });

  factory SynonymLearnBatch.fromJson(Map<String, dynamic> json) =>
      SynonymLearnBatch(
        gameType: json['gameType'] as String? ?? 'synonymSearch',
        phase: json['phase'] as String? ?? 'learn',
        cefr: json['cefr'] as String? ?? 'A2',
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        batchIndex: (json['batchIndex'] as num?)?.toInt() ?? 1,
        levels: json['levels'] as String? ?? '1-10',
        quests:
            (json['quests'] as List<dynamic>?)
                ?.map(
                  (e) => SynonymLearnItem.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList() ??
            const [],
      );

  List<SynonymLearnItem> itemsForLevel(int level) {
    final matching = quests.where((q) => q.level == level).toList();
    return matching.isNotEmpty ? matching : quests.take(3).toList();
  }
}

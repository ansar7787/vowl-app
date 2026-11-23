import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';

/// Production-grade data service dedicated to resolving, parsing, and caching
/// Word Formation curriculum quests for Learn and Practice phases.
///
/// Ensures the Presentation Layer (UI screens) remains 100% decoupled from
/// asset bundle I/O, file paths, and JSON serialization.
class WordFormationCurriculumService {
  static final WordFormationCurriculumService _instance =
      WordFormationCurriculumService._internal();

  factory WordFormationCurriculumService({AssetBundle? bundle}) {
    if (bundle != null) {
      _instance._bundle = bundle;
    }
    return _instance;
  }

  WordFormationCurriculumService._internal();

  AssetBundle _bundle = rootBundle;

  // In-memory cache to eliminate redundant disk reads across phase transitions
  final Map<String, List<PhasedQuest>> _cache = {};

  /// Loads curriculum quests for the Learn phase.
  Future<List<PhasedQuest>> getLearnQuests(int level) async {
    final batchIndex = ((level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final cacheKey = 'learn_${startLevel}_${endLevel}_level_$level';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final path =
          'assets/curriculum/vocabulary/wordFormation_learn_${startLevel}_$endLevel.json';
      final jsonStr = await _bundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests.where((q) => q.level == level).toList();
      final result = levelQuests.isNotEmpty ? levelQuests : batch.quests;
      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      return _buildLearnFallback(level);
    }
  }

  /// Loads curriculum quests for the Practice phase.
  Future<List<PhasedQuest>> getPracticeQuests(int level) async {
    final batchIndex = ((level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final cacheKey = 'practice_${startLevel}_${endLevel}_level_$level';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final path =
          'assets/curriculum/vocabulary/wordFormation_practice_${startLevel}_$endLevel.json';
      final jsonStr = await _bundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests.where((q) => q.level == level).toList();
      final result = levelQuests.isNotEmpty ? levelQuests : batch.quests;
      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      return _buildPracticeFallback(level);
    }
  }

  /// Clears in-memory cache.
  void clearCache() => _cache.clear();

  List<PhasedQuest> _buildLearnFallback(int level) {
    return [
      PhasedQuest(
        id: 'FALLBACK_WF_L${level}_LEARN_Q1',
        level: level,
        word: 'DECIDE',
        definition: 'To make a choice after thinking carefully.',
        rawExtra: {
          'rootWord': 'DECIDE',
          'rootMeaning': 'To make a choice after thinking carefully.',
          'northNoun': {
            'word': 'DECISION',
            'role': 'Noun',
            'rule': 'Drop -de, add -sion',
            'example': 'Making a tough career decision takes courage.',
          },
          'eastAdjective': {
            'word': 'DECISIVE',
            'role': 'Adjective',
            'rule': 'Drop -e, add -isive',
            'example': 'A decisive manager resolves issues quickly.',
          },
          'southAdverb': {
            'word': 'DECISIVELY',
            'role': 'Adverb',
            'rule': 'Add -ly to adjective',
            'example': 'She acted decisively during the crisis.',
          },
          'westOpposite': {
            'word': 'INDECISIVE',
            'role': 'Opposite',
            'rule': 'Prefix in- + decisive',
            'example': 'An indecisive customer hesitated for hours.',
          },
        },
      ),
      PhasedQuest(
        id: 'FALLBACK_WF_L${level}_LEARN_Q2',
        level: level,
        word: 'CREATE',
        definition: 'To bring something new into existence.',
        rawExtra: {
          'rootWord': 'CREATE',
          'rootMeaning': 'To bring something new into existence.',
          'northNoun': {
            'word': 'CREATION',
            'role': 'Noun',
            'rule': 'Drop -e, add -ion',
            'example': 'The artistic creation took three years.',
          },
          'eastAdjective': {
            'word': 'CREATIVE',
            'role': 'Adjective',
            'rule': 'Drop -e, add -ive',
            'example': 'A creative solution to a hard problem.',
          },
          'southAdverb': {
            'word': 'CREATIVELY',
            'role': 'Adverb',
            'rule': 'Add -ly to adjective',
            'example': 'They thought creatively to save costs.',
          },
          'westOpposite': {
            'word': 'UNCREATIVE',
            'role': 'Opposite',
            'rule': 'Prefix un- + creative',
            'example': 'Copying others is uncreative work.',
          },
        },
      ),
    ];
  }

  List<PhasedQuest> _buildPracticeFallback(int level) {
    return [
      PhasedQuest(
        id: 'FALLBACK_WF_L${level}_PRACTICE_Q1',
        level: level,
        word: 'DECIDE',
        example:
            'The committee reached a unanimous _______ after hours of debate.',
        rawExtra: {
          'sentence':
              'The committee reached a unanimous _______ after hours of debate.',
          'targetWord': 'DECISION',
          'correctAnswer': 'DECISION',
          'correctDirection': 'north',
          'targetRole': 'Noun',
          'roleClue':
              "The adjective 'unanimous' must describe a NOUN (North ⬆️).",
          'northNoun': 'DECISION',
          'eastAdjective': 'DECISIVE',
          'southAdverb': 'DECISIVELY',
          'westOpposite': 'INDECISIVE',
          'options': [
            'DECISION',
            'DECISIVE',
            'DECISIVELY',
            'INDECISIVE',
          ],
          'bounceFeedback':
              "Notice: 'unanimous' is an adjective, which describes a NOUN (North ⬆️)!",
        },
      ),
      PhasedQuest(
        id: 'FALLBACK_WF_L${level}_PRACTICE_Q2',
        level: level,
        word: 'CREATE',
        example:
            'She approached the complex project with a fresh, _______ mindset.',
        rawExtra: {
          'sentence':
              'She approached the complex project with a fresh, _______ mindset.',
          'targetWord': 'CREATIVE',
          'correctAnswer': 'CREATIVE',
          'correctDirection': 'east',
          'targetRole': 'Adjective',
          'roleClue':
              "Modifies the noun 'mindset' ➔ Needs an ADJECTIVE (East ➡️).",
          'northNoun': 'CREATION',
          'eastAdjective': 'CREATIVE',
          'southAdverb': 'CREATIVELY',
          'westOpposite': 'UNCREATIVE',
          'options': [
            'CREATION',
            'CREATIVE',
            'CREATIVELY',
            'UNCREATIVE',
          ],
          'bounceFeedback':
              "Notice: Modifying 'mindset' requires an ADJECTIVE (East ➡️)!",
        },
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Statistical progress snapshot for a learning category / realm.
class CategoryProgressStats {
  final int totalGames;
  final int masteredGames;
  final int totalLevels;
  final int completedLevels;
  final int earnedStars;
  final int maxPossibleStars;
  final double progress; // 0.0 to 1.0

  const CategoryProgressStats({
    required this.totalGames,
    required this.masteredGames,
    required this.totalLevels,
    required this.completedLevels,
    required this.earnedStars,
    required this.maxPossibleStars,
    required this.progress,
  });
}

/// Centralized, DRY pedagogical logic for category games, journey order,
/// mastery rankings, and statistical aggregation.
class CategoryGamesLogic {
  const CategoryGamesLogic._();

  /// Curated progression journey order for each primary syllabus category.
  static const Map<String, List<GameSubtype>> _journeyOrder = {
    'vocabulary': [
      GameSubtype.flashcards,
      GameSubtype.topicVocab,
      GameSubtype.wordFormation,
      GameSubtype.prefixSuffix,
      GameSubtype.synonymSearch,
      GameSubtype.antonymSearch,
      GameSubtype.contextClues,
      GameSubtype.collocations,
      GameSubtype.phrasalVerbs,
      GameSubtype.idioms,
      GameSubtype.academicWord,
      GameSubtype.contextualUsage,
    ],
    'grammar': [
      GameSubtype.partsOfSpeech,
      GameSubtype.grammarQuest,
      GameSubtype.wordReorder,
      GameSubtype.sentenceCorrection,
      GameSubtype.tenseMastery,
      GameSubtype.subjectVerbAgreement,
      GameSubtype.articleInsertion,
      GameSubtype.questionFormatter,
      GameSubtype.clauseConnector,
      GameSubtype.voiceSwap,
      GameSubtype.punctuationMastery,
      GameSubtype.modifierPlacement,
      GameSubtype.modalsSelection,
      GameSubtype.prepositionChoice,
      GameSubtype.pronounResolution,
      GameSubtype.relativeClauses,
      GameSubtype.conditionals,
      GameSubtype.conjunctions,
      GameSubtype.directIndirectSpeech,
    ],
    'listening': [
      GameSubtype.audioFillBlanks,
      GameSubtype.audioMultipleChoice,
      GameSubtype.audioSentenceOrder,
      GameSubtype.audioTrueFalse,
      GameSubtype.soundImageMatch,
      GameSubtype.detailSpotlight,
      GameSubtype.emotionRecognition,
      GameSubtype.fastSpeechDecoder,
      GameSubtype.listeningInference,
      GameSubtype.ambientId,
    ],
    'reading': [
      GameSubtype.readAndAnswer,
      GameSubtype.findWordMeaning,
      GameSubtype.trueFalseReading,
      GameSubtype.sentenceOrderReading,
      GameSubtype.guessTitle,
      GameSubtype.readAndMatch,
      GameSubtype.skimmingScanning,
      GameSubtype.paragraphSummary,
      GameSubtype.readingSpeedCheck,
      GameSubtype.readingInference,
      GameSubtype.readingConclusion,
      GameSubtype.clozeTest,
    ],
    'writing': [
      GameSubtype.sentenceBuilder,
      GameSubtype.completeSentence,
      GameSubtype.fixTheSentence,
      GameSubtype.describeSituationWriting,
      GameSubtype.summarizeStoryWriting,
      GameSubtype.shortAnswerWriting,
      GameSubtype.opinionWriting,
      GameSubtype.dailyJournal,
      GameSubtype.writingEmail,
      GameSubtype.correctionWriting,
      GameSubtype.essayDrafting,
    ],
    'speaking': [
      GameSubtype.repeatSentence,
      GameSubtype.speakMissingWord,
      GameSubtype.yesNoSpeaking,
      GameSubtype.pronunciationFocus,
      GameSubtype.speakSynonym,
      GameSubtype.speakOpposite,
      GameSubtype.dailyExpression,
      GameSubtype.situationSpeaking,
      GameSubtype.sceneDescriptionSpeaking,
      GameSubtype.dialogueRoleplay,
    ],
    'accent': [
      GameSubtype.minimalPairs,
      GameSubtype.vowelDistinction,
      GameSubtype.consonantClarity,
      GameSubtype.syllableStress,
      GameSubtype.wordLinking,
      GameSubtype.connectedSpeech,
      GameSubtype.intonationMimic,
      GameSubtype.pitchModulation,
      GameSubtype.pitchPatternMatch,
      GameSubtype.speedVariance,
      GameSubtype.shadowingChallenge,
      GameSubtype.dialectDrill,
    ],
    'roleplay': [
      GameSubtype.situationalResponse,
      GameSubtype.branchingDialogue,
      GameSubtype.socialSpark,
      GameSubtype.travelDesk,
      GameSubtype.gourmetOrder,
      GameSubtype.jobInterview,
      GameSubtype.medicalConsult,
      GameSubtype.conflictResolver,
      GameSubtype.elevatorPitch,
      GameSubtype.emergencyHub,
    ],
    'elitemastery': [
      GameSubtype.storyBuilder,
      GameSubtype.idiomMatch,
      GameSubtype.speedSpelling,
      GameSubtype.accentShadowing,
    ],
  };

  /// Safely resolves the canonical lookup key for category mapping.
  static String normalizeCategoryKey(String category) {
    return category.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  }

  /// Returns all non-legacy [GameSubtype]s for [category], sorted in pedagogical sequence.
  static List<GameSubtype> getGamesForCategory(String category) {
    final normKey = normalizeCategoryKey(category);
    final List<GameSubtype> allGames = GameSubtype.values.where((s) {
      if (s.isLegacy) return false;
      final sNorm = normalizeCategoryKey(s.category.name);
      return sNorm == normKey;
    }).toList();

    final order = _journeyOrder[normKey];
    if (order != null) {
      allGames.sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    return allGames;
  }

  /// Computes aggregate learner progress, mastery level, and star metrics for a category.
  static CategoryProgressStats getCategoryStats(UserEntity user, String category) {
    final games = getGamesForCategory(category);
    int totalLevels = 0;
    int completedLevels = 0;
    int masteredGames = 0;
    int earnedStars = 0;

    for (final game in games) {
      final totalGameLevels = CurriculumManifest.getLevels(game.name);
      totalLevels += totalGameLevels;

      final completed = user.completedLevels[game.name]?.length ?? 0;
      final clamped = completed.clamp(0, totalGameLevels);
      completedLevels += clamped;

      if (clamped >= totalGameLevels && totalGameLevels > 0) {
        masteredGames++;
      }

      final starsMap = user.starRatings[game.name] ?? {};
      starsMap.forEach((key, val) {
        if (key != 'magic_stars' && key != 'claimed_chests') {
          earnedStars += val;
        }
      });
    }

    final maxPossibleStars = totalLevels * 3;
    final progress = totalLevels > 0
        ? (completedLevels / totalLevels).clamp(0.0, 1.0)
        : 0.0;

    return CategoryProgressStats(
      totalGames: games.length,
      masteredGames: masteredGames,
      totalLevels: totalLevels,
      completedLevels: completedLevels,
      earnedStars: earnedStars,
      maxPossibleStars: maxPossibleStars,
      progress: progress,
    );
  }

  /// Resolves motivational learner rank badge based on percentage progress.
  static String getRank(BuildContext context, double progress) {
    if (progress <= 0.0) {
      return context.tr('category_games.rank_beginner', fallback: 'BEGINNER');
    }
    if (progress < 0.15) {
      return context.tr('category_games.rank_novice', fallback: 'NOVICE');
    }
    if (progress < 0.35) {
      return context.tr('category_games.rank_scholar', fallback: 'SCHOLAR');
    }
    if (progress < 0.55) {
      return context
          .tr('home.discovery_diff_expert', fallback: 'Expert')
          .toUpperCase();
    }
    if (progress < 0.80) {
      return context.tr('category_games.rank_virtuoso', fallback: 'VIRTUOSO');
    }
    if (progress < 0.99) {
      return context.tr(
        'quest_archive.status_grandmaster',
        fallback: 'GRANDMASTER',
      );
    }
    return context.tr('quest_archive.status_legendary', fallback: 'LEGENDARY');
  }

  /// Formats integers with thousands comma separation (e.g. 2000 -> 2,000).
  static String formatNumber(int count) {
    return count.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

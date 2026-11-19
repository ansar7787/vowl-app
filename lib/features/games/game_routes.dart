import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/app_router_game_resolvers.dart';
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/pages/category_games_page.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_level_screen.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:vowl/features/profile/presentation/pages/quest_coins_screen.dart';
import 'package:vowl/core/presentation/pages/quest_sequence_page.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_practice_screen.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_learn_screen.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_practice_screen.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_learn_screen.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_practice_screen.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_learn_screen.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_practice_screen.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_learn_screen.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_practice_screen.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_learn_screen.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_practice_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_learn_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_practice_screen.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_learn_screen.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_practice_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_learn_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_practice_screen.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/pages/collocations_learn_screen.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/pages/collocations_practice_screen.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_learn_screen.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_practice_screen.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_learn_screen.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_practice_screen.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_learn_screen.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_practice_screen.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_learn_screen.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_practice_screen.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_learn_screen.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_practice_screen.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_learn_screen.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_practice_screen.dart';
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_learn_screen.dart';
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_practice_screen.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_learn_screen.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_practice_screen.dart';
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_learn_screen.dart';
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_practice_screen.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_learn_screen.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_practice_screen.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_learn_screen.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_practice_screen.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_learn_screen.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_practice_screen.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/pages/modifier_placement_learn_screen.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/pages/modifier_placement_practice_screen.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_learn_screen.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_practice_screen.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_learn_screen.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_practice_screen.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_learn_screen.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_practice_screen.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_learn_screen.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_practice_screen.dart';
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_learn_screen.dart';
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_practice_screen.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/pages/conjunctions_learn_screen.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/pages/conjunctions_practice_screen.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_learn_screen.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_practice_screen.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_learn_screen.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_practice_screen.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_learn_screen.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_practice_screen.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_learn_screen.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_practice_screen.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_learn_screen.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_practice_screen.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_learn_screen.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_practice_screen.dart';
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_learn_screen.dart';
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_practice_screen.dart';
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_learn_screen.dart';
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_practice_screen.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/pages/paragraph_summary_learn_screen.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/pages/paragraph_summary_practice_screen.dart';
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_learn_screen.dart';
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_practice_screen.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_learn_screen.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_practice_screen.dart';
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_learn_screen.dart';
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_practice_screen.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_learn_screen.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_practice_screen.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_learn_screen.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_practice_screen.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_learn_screen.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_practice_screen.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_learn_screen.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_practice_screen.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_learn_screen.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_practice_screen.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_learn_screen.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_practice_screen.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_learn_screen.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_practice_screen.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_learn_screen.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_practice_screen.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_learn_screen.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_practice_screen.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_learn_screen.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_practice_screen.dart';
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_learn_screen.dart';
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_practice_screen.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_learn_screen.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_practice_screen.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_learn_screen.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_practice_screen.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_learn_screen.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_practice_screen.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_learn_screen.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_practice_screen.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_learn_screen.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_practice_screen.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_learn_screen.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_practice_screen.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_learn_screen.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_practice_screen.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_learn_screen.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_practice_screen.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_learn_screen.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_practice_screen.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_learn_screen.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_practice_screen.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_learn_screen.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_practice_screen.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_learn_screen.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_practice_screen.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_learn_screen.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_practice_screen.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_learn_screen.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_practice_screen.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_learn_screen.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_practice_screen.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_learn_screen.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_practice_screen.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_learn_screen.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_practice_screen.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_learn_screen.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_practice_screen.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_learn_screen.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_practice_screen.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_learn_screen.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_practice_screen.dart';
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_learn_screen.dart';
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_practice_screen.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_learn_screen.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_practice_screen.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_learn_screen.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_practice_screen.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_learn_screen.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_practice_screen.dart';
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_learn_screen.dart';
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_practice_screen.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_learn_screen.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_practice_screen.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_learn_screen.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_practice_screen.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_learn_screen.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_practice_screen.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_learn_screen.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_practice_screen.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_learn_screen.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_practice_screen.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/pages/dialect_drill_learn_screen.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/pages/dialect_drill_practice_screen.dart';
import 'package:vowl/features/accent/connected_speech/presentation/pages/connected_speech_learn_screen.dart';
import 'package:vowl/features/accent/connected_speech/presentation/pages/connected_speech_practice_screen.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/pages/pitch_modulation_learn_screen.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/pages/pitch_modulation_practice_screen.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_learn_screen.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_practice_screen.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/pages/situational_response_learn_screen.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/pages/situational_response_practice_screen.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_learn_screen.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_practice_screen.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_learn_screen.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_practice_screen.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_learn_screen.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_practice_screen.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_learn_screen.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_practice_screen.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_learn_screen.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_practice_screen.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_learn_screen.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_practice_screen.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/discovery_helper.dart';
import 'package:vowl/core/utils/toll_gate_helper.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ---------------------------------------------------------------------------
// Private: configuration descriptor for each game category.
//
// FIX (HIGH-3): Replaces the 9-case switch statement. Adding a new category
// now requires a single map entry instead of copy-pasting ~10 lines.
// Routing is O(1) map lookup vs O(n) sequential case evaluation.
// ---------------------------------------------------------------------------

typedef _ScreenFactory = Widget Function(GameSubtype subtype, int level);

class _CategoryConfig {
  const _CategoryConfig({required this.defaultSubtype, required this.factory});

  final GameSubtype defaultSubtype;
  final _ScreenFactory factory;
}

/// Central routing configuration and game screen resolvers for all curriculum games.
///
/// Provides declarative [GoRoute] definitions and O(1) map-based screen
/// resolution across reading, writing, listening, speaking, grammar, vocabulary,
/// accent, roleplay, and elite mastery.
class GameRoutes {
  GameRoutes._(); // Non-instantiable utility class.

  /// Route path for category-specific game list screens.
  static const String categoryGamesRoute = '/category-games';

  /// Route path for level detail dialogs and views.
  static const String levelRoute = '/level-details';

  /// Route path for adventure XP breakdown views.
  static const String adventureXPRoute = '/xp-details';

  /// Route path for quest coins details and shop navigation.
  static const String questCoinsRoute = '/coins-details';

  /// Route path for multi-step quest sequence runners.
  static const String questSequenceRoute = '/quest-sequence';

  /// Route path for the Learn phase.
  static const String learnRoute = '/learn';

  /// Route path for the Practice phase.
  static const String practiceRoute = '/practice';

  // ---------------------------------------------------------------------------
  // Category → (default GameSubtype, screen factory) mapping.
  // ---------------------------------------------------------------------------
  static final Map<String, _CategoryConfig> _categoryConfigs = {
    'reading': _CategoryConfig(
      defaultSubtype: GameSubtype.readAndAnswer,
      factory: AppRouterGameResolvers.getReadingScreen,
    ),
    'writing': _CategoryConfig(
      defaultSubtype: GameSubtype.sentenceBuilder,
      factory: AppRouterGameResolvers.getWritingScreen,
    ),
    'speaking': _CategoryConfig(
      defaultSubtype: GameSubtype.repeatSentence,
      factory: AppRouterGameResolvers.getSpeakingScreen,
    ),
    'grammar': _CategoryConfig(
      defaultSubtype: GameSubtype.grammarQuest,
      factory: AppRouterGameResolvers.getGrammarScreen,
    ),
    'roleplay': _CategoryConfig(
      defaultSubtype: GameSubtype.branchingDialogue,
      factory: AppRouterGameResolvers.getRoleplayScreen,
    ),
    'accent': _CategoryConfig(
      defaultSubtype: GameSubtype.minimalPairs,
      factory: AppRouterGameResolvers.getAccentScreen,
    ),
    'listening': _CategoryConfig(
      defaultSubtype: GameSubtype.audioMultipleChoice,
      factory: AppRouterGameResolvers.getListeningScreen,
    ),
    'vocabulary': _CategoryConfig(
      defaultSubtype: GameSubtype.flashcards,
      factory: AppRouterGameResolvers.getVocabularyScreen,
    ),
    'elitemastery': _CategoryConfig(
      defaultSubtype: GameSubtype.storyBuilder,
      factory: AppRouterGameResolvers.getEliteMasteryScreen,
    ),
    'elite_mastery': _CategoryConfig(
      defaultSubtype: GameSubtype.storyBuilder,
      factory: AppRouterGameResolvers.getEliteMasteryScreen,
    ),
  };

  // ---------------------------------------------------------------------------
  // Resolves a game screen from URL query parameters.
  // Falls back to reading/readAndAnswer for unknown categories.
  // ---------------------------------------------------------------------------
  static Widget _resolveGameScreen({
    required String category,
    required String? gameTypeStr,
    required int level,
  }) {
    final normalized = category
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');
    final config =
        _categoryConfigs[normalized] ??
        _categoryConfigs[category.toLowerCase()] ??
        _categoryConfigs['reading']!;

    final subtype = gameTypeStr != null
        ? GameSubtype.values.firstWhere(
            (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
            orElse: () => config.defaultSubtype,
          )
        : config.defaultSubtype;

    return config.factory(subtype, level);
  }

  // ---------------------------------------------------------------------------
  // Route definitions
  // ---------------------------------------------------------------------------
  /// Declarative [RouteBase] definitions registered with GoRouter.
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/game',
      redirect: (context, state) {
        final authBloc =
            di.sl.isRegistered<AuthBloc>() ? di.sl<AuthBloc>() : null;
        final user = authBloc?.state.user;
        final gameTypeStr = state.uri.queryParameters['gameType'] ??
            state.uri.queryParameters['subtype'];
        final level =
            int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;

        if (gameTypeStr != null &&
            TollGateHelper.isTollGate(
              user: user,
              gameType: gameTypeStr,
              level: level,
            )) {
          final category =
              state.uri.queryParameters['category'] ?? 'reading';
          return '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(gameTypeStr)}';
        }
        return null;
      },
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'reading';
        final level =
            int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
        final gameTypeStr =
            state.uri.queryParameters['gameType'] ??
            state.uri.queryParameters['subtype'];

        final screen = _resolveGameScreen(
          category: category,
          gameTypeStr: gameTypeStr,
          level: level,
        );

        return fadeTransitionPage(child: screen, state: state);
      },
    ),

    GoRoute(
      path: '/levels',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['category'] ?? 'reading';
        final gameType =
            state.uri.queryParameters['gameType'] ?? 'readAndAnswer';

        return fadeTransitionPage(
          child: ModernCategoryMap(
            key: ValueKey('${categoryId}_$gameType'),
            gameType: gameType,
            categoryId: categoryId,
          ),
          state: state,
        );
      },
    ),

    GoRoute(
      path: categoryGamesRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: CategoryGamesPage(
          categoryId: state.uri.queryParameters['category'] ?? 'speaking',
        ),
        state: state,
      ),
    ),

    GoRoute(
      path: levelRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const AdventureLevelScreen(), state: state),
    ),

    GoRoute(
      path: adventureXPRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const AdventureXPScreen(), state: state),
    ),

    GoRoute(
      path: questCoinsRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const VowlCoinsScreen(), state: state),
    ),

    GoRoute(
      path: questSequenceRoute,
      pageBuilder: (context, state) {
        final sequenceId = state.uri.queryParameters['id'] ?? 'daily_workout';
        UserEntity? user;
        try {
          user = context.read<AuthBloc>().state.user;
        } catch (_) {
          try {
            user = di.sl<AuthBloc>().state.user;
          } catch (_) {}
        }
        final quests = user != null
            ? DiscoveryHelper.getQuestsForSequence(sequenceId, user)
            : <GameQuest>[];

        return fadeTransitionPage(
          child: QuestSequencePage(sequenceId: sequenceId, quests: quests),
          state: state,
        );
      },
    ),

    GoRoute(
      path: learnRoute,
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'vocabulary';
        final gameType = state.uri.queryParameters['gameType'] ?? 'flashcards';
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;

        if (gameType.toLowerCase() == 'flashcards') {
          return fadeTransitionPage(
            child: FlashcardsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'synonymsearch') {
          return fadeTransitionPage(
            child: SynonymSearchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'antonymsearch') {
          return fadeTransitionPage(
            child: AntonymSearchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'contextclues') {
          return fadeTransitionPage(
            child: ContextCluesLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'phrasalverbs') {
          return fadeTransitionPage(
            child: PhrasalVerbsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'idioms') {
          return fadeTransitionPage(
            child: IdiomsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'academicword') {
          return fadeTransitionPage(
            child: AcademicWordLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'topicvocab') {
          return fadeTransitionPage(
            child: TopicVocabLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'wordformation') {
          return fadeTransitionPage(
            child: WordFormationLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'prefixsuffix') {
          return fadeTransitionPage(
            child: PrefixSuffixLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'collocations') {
          return fadeTransitionPage(
            child: CollocationsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'contextualusage') {
          return fadeTransitionPage(
            child: ContextualUsageLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'partsofspeech') {
          return fadeTransitionPage(
            child: PartsOfSpeechLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'grammarquest') {
          return fadeTransitionPage(
            child: GrammarQuestLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'wordreorder') {
          return fadeTransitionPage(
            child: WordReorderLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'sentencecorrection') {
          return fadeTransitionPage(
            child: SentenceCorrectionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'tensemastery') {
          return fadeTransitionPage(
            child: TenseMasteryLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'subjectverbagreement') {
          return fadeTransitionPage(
            child: SubjectVerbAgreementLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'articleinsertion') {
          return fadeTransitionPage(
            child: ArticleInsertionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'questionformatter') {
          return fadeTransitionPage(
            child: QuestionFormatterLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'clauseconnector') {
          return fadeTransitionPage(
            child: ClauseConnectorLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'voiceswap') {
          return fadeTransitionPage(
            child: VoiceSwapLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'punctuationmastery') {
          return fadeTransitionPage(
            child: PunctuationMasteryLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'modifierplacement') {
          return fadeTransitionPage(
            child: ModifierPlacementLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'modalsselection') {
          return fadeTransitionPage(
            child: ModalsSelectionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'prepositionchoice') {
          return fadeTransitionPage(
            child: PrepositionChoiceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pronounresolution') {
          return fadeTransitionPage(
            child: PronounResolutionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'relativeclauses') {
          return fadeTransitionPage(
            child: RelativeClausesLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'conditionals') {
          return fadeTransitionPage(
            child: ConditionalsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'conjunctions') {
          return fadeTransitionPage(
            child: ConjunctionsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'directindirectspeech') {
          return fadeTransitionPage(
            child: DirectIndirectSpeechLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readandanswer') {
          return fadeTransitionPage(
            child: ReadAndAnswerLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'findwordmeaning') {
          return fadeTransitionPage(
            child: FindWordMeaningLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'truefalsereading') {
          return fadeTransitionPage(
            child: TrueFalseReadingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'sentenceorderreading') {
          return fadeTransitionPage(
            child: SentenceOrderReadingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readingspeedcheck') {
          return fadeTransitionPage(
            child: ReadingSpeedCheckLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'guesstitle') {
          return fadeTransitionPage(
            child: GuessTitleLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readandmatch') {
          return fadeTransitionPage(
            child: ReadAndMatchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'paragraphsummary') {
          return fadeTransitionPage(
            child: ParagraphSummaryLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readinginference') {
          return fadeTransitionPage(
            child: ReadingInferenceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readingconclusion') {
          return fadeTransitionPage(
            child: ReadingConclusionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'clozetest') {
          return fadeTransitionPage(
            child: ClozeTestLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'skimmingscanning') {
          return fadeTransitionPage(
            child: SkimmingScanningLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'sentencebuilder') {
          return fadeTransitionPage(
            child: SentenceBuilderLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'completesentence') {
          return fadeTransitionPage(
            child: CompleteSentenceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'describesituationwriting') {
          return fadeTransitionPage(
            child: DescribeSituationWritingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'fixthesentence') {
          return fadeTransitionPage(
            child: FixTheSentenceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'shortanswerwriting') {
          return fadeTransitionPage(
            child: ShortAnswerWritingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'opinionwriting') {
          return fadeTransitionPage(
            child: OpinionWritingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dailyjournal') {
          return fadeTransitionPage(
            child: DailyJournalLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'summarizestorywriting') {
          return fadeTransitionPage(
            child: SummarizeStoryWritingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'writingemail') {
          return fadeTransitionPage(
            child: WritingEmailLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'correctionwriting') {
          return fadeTransitionPage(
            child: CorrectionWritingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'essaydrafting') {
          return fadeTransitionPage(
            child: EssayDraftingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'repeatsentence') {
          return fadeTransitionPage(
            child: RepeatSentenceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speakmissingword') {
          return fadeTransitionPage(
            child: SpeakMissingWordLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pronunciationfocus') {
          return fadeTransitionPage(
            child: PronunciationFocusLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dailyexpression') {
          return fadeTransitionPage(
            child: DailyExpressionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dialogueroleplay') {
          return fadeTransitionPage(
            child: DialogueRoleplayLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'scenedescriptionspeaking') {
          return fadeTransitionPage(
            child: SceneDescriptionSpeakingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'situationspeaking') {
          return fadeTransitionPage(
            child: SituationSpeakingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speakopposite') {
          return fadeTransitionPage(
            child: SpeakOppositeLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speaksynonym') {
          return fadeTransitionPage(
            child: SpeakSynonymLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'yesnospeaking') {
          return fadeTransitionPage(
            child: YesNoSpeakingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiofillblanks') {
          return fadeTransitionPage(
            child: AudioFillBlanksLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiomultiplechoice') {
          return fadeTransitionPage(
            child: AudioMultipleChoiceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiosentenceorder') {
          return fadeTransitionPage(
            child: AudioSentenceOrderLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiotruefalse') {
          return fadeTransitionPage(
            child: AudioTrueFalseLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'soundimagematch') {
          return fadeTransitionPage(
            child: SoundImageMatchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'fastspeechdecoder') {
          return fadeTransitionPage(
            child: FastSpeechDecoderLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'emotionrecognition') {
          return fadeTransitionPage(
            child: EmotionRecognitionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'detailspotlight') {
          return fadeTransitionPage(
            child: DetailSpotlightLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'listeninginference') {
          return fadeTransitionPage(
            child: ListeningInferenceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'ambientid') {
          return fadeTransitionPage(
            child: AmbientIdLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'minimalpairs') {
          return fadeTransitionPage(
            child: MinimalPairsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'intonationmimic') {
          return fadeTransitionPage(
            child: IntonationMimicLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'syllablestress') {
          return fadeTransitionPage(
            child: SyllableStressLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'wordlinking') {
          return fadeTransitionPage(
            child: WordLinkingLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'shadowingchallenge') {
          return fadeTransitionPage(
            child: ShadowingChallengeLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'voweldistinction') {
          return fadeTransitionPage(
            child: VowelDistinctionLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'consonantclarity') {
          return fadeTransitionPage(
            child: ConsonantClarityLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pitchpatternmatch') {
          return fadeTransitionPage(
            child: PitchPatternMatchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speedvariance') {
          return fadeTransitionPage(
            child: SpeedVarianceLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dialectdrill') {
          return fadeTransitionPage(
            child: DialectDrillLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'connectedspeech') {
          return fadeTransitionPage(
            child: ConnectedSpeechLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pitchmodulation') {
          return fadeTransitionPage(
            child: PitchModulationLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'branchingdialogue') {
          return fadeTransitionPage(
            child: BranchingDialogueLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'situationalresponse') {
          return fadeTransitionPage(
            child: SituationalResponseLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'jobinterview') {
          return fadeTransitionPage(
            child: JobInterviewLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'medicalconsult') {
          return fadeTransitionPage(
            child: MedicalConsultLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'gourmetorder') {
          return fadeTransitionPage(
            child: GourmetOrderLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'traveldesk') {
          return fadeTransitionPage(
            child: TravelDeskLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'conflictresolver') {
          return fadeTransitionPage(
            child: ConflictResolverLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'elevatorpitch') {
          return fadeTransitionPage(
            child: ElevatorPitchLearnScreen(level: level),
            state: state,
          );
        }

        return fadeTransitionPage(
          child: LearnPhaseScaffold(
            title: '$gameType Discovery',
            gameType: gameType,
            level: level,
            onComplete: () {
              final targetPractice = '$practiceRoute?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(gameType)}&level=$level';
              context.pushReplacement(targetPractice);
            },
            child: Center(
              child: Text(
                'Learn Phase: $category / $gameType (Level $level)',
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
            ),
          ),
          state: state,
        );
      },
    ),

    GoRoute(
      path: practiceRoute,
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'vocabulary';
        final gameType = state.uri.queryParameters['gameType'] ?? 'flashcards';
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;

        if (gameType.toLowerCase() == 'flashcards') {
          return fadeTransitionPage(
            child: FlashcardsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'synonymsearch') {
          return fadeTransitionPage(
            child: SynonymSearchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'antonymsearch') {
          return fadeTransitionPage(
            child: AntonymSearchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'contextclues') {
          return fadeTransitionPage(
            child: ContextCluesPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'phrasalverbs') {
          return fadeTransitionPage(
            child: PhrasalVerbsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'idioms') {
          return fadeTransitionPage(
            child: IdiomsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'academicword') {
          return fadeTransitionPage(
            child: AcademicWordPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'topicvocab') {
          return fadeTransitionPage(
            child: TopicVocabPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'wordformation') {
          return fadeTransitionPage(
            child: WordFormationPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'prefixsuffix') {
          return fadeTransitionPage(
            child: PrefixSuffixPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'collocations') {
          return fadeTransitionPage(
            child: CollocationsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'contextualusage') {
          return fadeTransitionPage(
            child: ContextualUsagePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'partsofspeech') {
          return fadeTransitionPage(
            child: PartsOfSpeechPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'grammarquest') {
          return fadeTransitionPage(
            child: GrammarQuestPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'wordreorder') {
          return fadeTransitionPage(
            child: WordReorderPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'sentencecorrection') {
          return fadeTransitionPage(
            child: SentenceCorrectionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'tensemastery') {
          return fadeTransitionPage(
            child: TenseMasteryPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'subjectverbagreement') {
          return fadeTransitionPage(
            child: SubjectVerbAgreementPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'articleinsertion') {
          return fadeTransitionPage(
            child: ArticleInsertionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'questionformatter') {
          return fadeTransitionPage(
            child: QuestionFormatterPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'clauseconnector') {
          return fadeTransitionPage(
            child: ClauseConnectorPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'voiceswap') {
          return fadeTransitionPage(
            child: VoiceSwapPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'punctuationmastery') {
          return fadeTransitionPage(
            child: PunctuationMasteryPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'modifierplacement') {
          return fadeTransitionPage(
            child: ModifierPlacementPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'modalsselection') {
          return fadeTransitionPage(
            child: ModalsSelectionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'prepositionchoice') {
          return fadeTransitionPage(
            child: PrepositionChoicePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pronounresolution') {
          return fadeTransitionPage(
            child: PronounResolutionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'relativeclauses') {
          return fadeTransitionPage(
            child: RelativeClausesPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'conditionals') {
          return fadeTransitionPage(
            child: ConditionalsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'conjunctions') {
          return fadeTransitionPage(
            child: ConjunctionsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'directindirectspeech') {
          return fadeTransitionPage(
            child: DirectIndirectSpeechPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readandanswer') {
          return fadeTransitionPage(
            child: ReadAndAnswerPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'findwordmeaning') {
          return fadeTransitionPage(
            child: FindWordMeaningPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'truefalsereading') {
          return fadeTransitionPage(
            child: TrueFalseReadingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'sentenceorderreading') {
          return fadeTransitionPage(
            child: SentenceOrderReadingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readingspeedcheck') {
          return fadeTransitionPage(
            child: ReadingSpeedCheckPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'guesstitle') {
          return fadeTransitionPage(
            child: GuessTitlePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readandmatch') {
          return fadeTransitionPage(
            child: ReadAndMatchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'paragraphsummary') {
          return fadeTransitionPage(
            child: ParagraphSummaryPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readinginference') {
          return fadeTransitionPage(
            child: ReadingInferencePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'readingconclusion') {
          return fadeTransitionPage(
            child: ReadingConclusionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'clozetest') {
          return fadeTransitionPage(
            child: ClozeTestPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'skimmingscanning') {
          return fadeTransitionPage(
            child: SkimmingScanningPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'sentencebuilder') {
          return fadeTransitionPage(
            child: SentenceBuilderPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'completesentence') {
          return fadeTransitionPage(
            child: CompleteSentencePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'describesituationwriting') {
          return fadeTransitionPage(
            child: DescribeSituationWritingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'fixthesentence') {
          return fadeTransitionPage(
            child: FixTheSentencePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'shortanswerwriting') {
          return fadeTransitionPage(
            child: ShortAnswerWritingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'opinionwriting') {
          return fadeTransitionPage(
            child: OpinionWritingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dailyjournal') {
          return fadeTransitionPage(
            child: DailyJournalPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'summarizestorywriting') {
          return fadeTransitionPage(
            child: SummarizeStoryWritingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'writingemail') {
          return fadeTransitionPage(
            child: WritingEmailPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'correctionwriting') {
          return fadeTransitionPage(
            child: CorrectionWritingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'essaydrafting') {
          return fadeTransitionPage(
            child: EssayDraftingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'repeatsentence') {
          return fadeTransitionPage(
            child: RepeatSentencePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speakmissingword') {
          return fadeTransitionPage(
            child: SpeakMissingWordPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pronunciationfocus') {
          return fadeTransitionPage(
            child: PronunciationFocusPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dailyexpression') {
          return fadeTransitionPage(
            child: DailyExpressionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dialogueroleplay') {
          return fadeTransitionPage(
            child: DialogueRoleplayPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'scenedescriptionspeaking') {
          return fadeTransitionPage(
            child: SceneDescriptionSpeakingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'situationspeaking') {
          return fadeTransitionPage(
            child: SituationSpeakingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speakopposite') {
          return fadeTransitionPage(
            child: SpeakOppositePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speaksynonym') {
          return fadeTransitionPage(
            child: SpeakSynonymPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'yesnospeaking') {
          return fadeTransitionPage(
            child: YesNoSpeakingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiofillblanks') {
          return fadeTransitionPage(
            child: AudioFillBlanksPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiomultiplechoice') {
          return fadeTransitionPage(
            child: AudioMultipleChoicePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiosentenceorder') {
          return fadeTransitionPage(
            child: AudioSentenceOrderPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'audiotruefalse') {
          return fadeTransitionPage(
            child: AudioTrueFalsePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'soundimagematch') {
          return fadeTransitionPage(
            child: SoundImageMatchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'fastspeechdecoder') {
          return fadeTransitionPage(
            child: FastSpeechDecoderPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'emotionrecognition') {
          return fadeTransitionPage(
            child: EmotionRecognitionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'detailspotlight') {
          return fadeTransitionPage(
            child: DetailSpotlightPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'listeninginference') {
          return fadeTransitionPage(
            child: ListeningInferencePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'ambientid') {
          return fadeTransitionPage(
            child: AmbientIdPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'minimalpairs') {
          return fadeTransitionPage(
            child: MinimalPairsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'intonationmimic') {
          return fadeTransitionPage(
            child: IntonationMimicPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'syllablestress') {
          return fadeTransitionPage(
            child: SyllableStressPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'wordlinking') {
          return fadeTransitionPage(
            child: WordLinkingPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'shadowingchallenge') {
          return fadeTransitionPage(
            child: ShadowingChallengePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'voweldistinction') {
          return fadeTransitionPage(
            child: VowelDistinctionPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'consonantclarity') {
          return fadeTransitionPage(
            child: ConsonantClarityPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pitchpatternmatch') {
          return fadeTransitionPage(
            child: PitchPatternMatchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'speedvariance') {
          return fadeTransitionPage(
            child: SpeedVariancePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'dialectdrill') {
          return fadeTransitionPage(
            child: DialectDrillPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'connectedspeech') {
          return fadeTransitionPage(
            child: ConnectedSpeechPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'pitchmodulation') {
          return fadeTransitionPage(
            child: PitchModulationPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'branchingdialogue') {
          return fadeTransitionPage(
            child: BranchingDialoguePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'situationalresponse') {
          return fadeTransitionPage(
            child: SituationalResponsePracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'jobinterview') {
          return fadeTransitionPage(
            child: JobInterviewPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'medicalconsult') {
          return fadeTransitionPage(
            child: MedicalConsultPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'gourmetorder') {
          return fadeTransitionPage(
            child: GourmetOrderPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'traveldesk') {
          return fadeTransitionPage(
            child: TravelDeskPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'conflictresolver') {
          return fadeTransitionPage(
            child: ConflictResolverPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'elevatorpitch') {
          return fadeTransitionPage(
            child: ElevatorPitchPracticeScreen(level: level),
            state: state,
          );
        }

        return fadeTransitionPage(
          child: PracticePhaseScaffold(
            title: '$gameType Gym',
            gameType: gameType,
            level: level,
            currentExerciseIndex: 0,
            totalExercises: 1,
            onComplete: () {
              final targetTest = '/game?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(gameType)}&level=$level';
              context.pushReplacement(targetTest);
            },
            child: Center(
              child: Text(
                'Practice Phase: $category / $gameType (Level $level)',
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
            ),
          ),
          state: state,
        );
      },
    ),
  ];
}

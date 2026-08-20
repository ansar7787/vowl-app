import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/app_logger.dart';

// ── BLoCs ─────────────────────────────────────────────────────────────────────

import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart'
    as vocab;

// ── Speaking screens ──────────────────────────────────────────────────────────

import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_screen.dart'
    as rs_game;
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart'
    as smw_game;
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart'
    as ss_game;
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart'
    as sd_game;
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart'
    as yn_game;
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_screen.dart'
    as ssyn_game;
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart'
    as dr_game;
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart'
    as pf_game;
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart'
    as sp_opp_game;
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart'
    as de_game;

// ── Reading screens ───────────────────────────────────────────────────────────

import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_screen.dart'
    as ra_game;
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_screen.dart'
    as fwm_game;
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_screen.dart'
    as tfr_game;
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_screen.dart'
    as so_game;
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_screen.dart'
    as rsc_game;
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_screen.dart'
    as gt_game;
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_screen.dart'
    as ram_game;
import 'package:vowl/features/reading/paragraph_summary/presentation/pages/paragraph_summary_screen.dart'
    as ps_game;
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_screen.dart'
    as ri_game;
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_screen.dart'
    as rcm_game;
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_screen.dart'
    as ct_game;
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_screen.dart'
    as ss_game_read;

// ── Writing screens ───────────────────────────────────────────────────────────

import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_screen.dart'
    as sb_game;
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_screen.dart'
    as cs_game;
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_screen.dart'
    as ds_game;
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_screen.dart'
    as fts_game;
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_screen.dart'
    as sa_game;
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_screen.dart'
    as ow_game;
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_screen.dart'
    as dj_game;
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_screen.dart'
    as ssw_game;
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_screen.dart'
    as we_game;
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_screen.dart'
    as cw_game;
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_screen.dart'
    as ed_game;

// ── Elite Mastery screens ─────────────────────────────────────────────────────

import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart'
    as sb_elite;
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_screen.dart'
    as im_elite;
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart'
    as ss_elite;
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_screen.dart'
    as as_elite;

// ── Grammar screens ───────────────────────────────────────────────────────────

import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_screen.dart'
    as gq_game;
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_screen.dart'
    as g_tm_game;
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_screen.dart'
    as g_ps_game;
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_screen.dart'
    as g_wr_game;
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_screen.dart'
    as g_sva_game;
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_screen.dart'
    as g_sc_game;
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_screen.dart'
    as g_ai_game;
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_screen.dart'
    as g_cc_game;
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_screen.dart'
    as g_qf_game;
import 'package:vowl/features/grammar/conjunctions/presentation/pages/conjunctions_screen.dart'
    as g_cj_game;
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_screen.dart'
    as g_ms_game;
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_screen.dart'
    as g_cd_game;
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_screen.dart'
    as g_rc_game;
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart'
    as g_pr_game;
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_screen.dart'
    as g_di_game;
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart'
    as g_vs_game;
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_screen.dart'
    as g_pc_game;
import 'package:vowl/features/grammar/modifier_placement/presentation/pages/modifier_placement_screen.dart'
    as g_mp_game;
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_screen.dart'
    as punc_game;

// ── Listening screens ─────────────────────────────────────────────────────────

import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_screen.dart'
    as l_afb_game;
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_screen.dart'
    as l_amc_game;
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_screen.dart'
    as l_aso_game;
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_screen.dart'
    as l_atf_game;
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_screen.dart'
    as l_sim_game;
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_screen.dart'
    as l_fsd_game;
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_screen.dart'
    as l_er_game;
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_screen.dart'
    as l_ds_game;
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_screen.dart'
    as l_li_game;
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_screen.dart'
    as l_ai_game;

// ── Accent screens ────────────────────────────────────────────────────────────

import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart'
    as a_mp_game;
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_screen.dart'
    as a_im_game;
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_screen.dart'
    as a_ss_game;
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_screen.dart'
    as a_wl_game;
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart'
    as a_sc_game;
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_screen.dart'
    as a_vd_game;
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_screen.dart'
    as a_cc_game;
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_screen.dart'
    as a_ppm_game;
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_screen.dart'
    as a_sv_game;
import 'package:vowl/features/accent/dialect_drill/presentation/pages/dialect_drill_screen.dart'
    as a_dd_game;
import 'package:vowl/features/accent/connected_speech/presentation/pages/connected_speech_screen.dart'
    as a_cs_game;
import 'package:vowl/features/accent/pitch_modulation/presentation/pages/pitch_modulation_screen.dart'
    as a_pm_game;

// ── Roleplay screens ──────────────────────────────────────────────────────────

import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_screen.dart'
    as r_bd_game;
import 'package:vowl/features/roleplay/situational_response/presentation/pages/situational_response_screen.dart'
    as r_sr_game;
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_screen.dart'
    as r_ji_game;
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_screen.dart'
    as r_mc_game;
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_screen.dart'
    as r_go_game;
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_screen.dart'
    as r_td_game;
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_screen.dart'
    as r_cr_game;
import 'package:vowl/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_screen.dart'
    as r_ep_game;
import 'package:vowl/features/roleplay/social_spark/presentation/pages/social_spark_screen.dart'
    as r_sk_game;
import 'package:vowl/features/roleplay/emergency_hub/presentation/pages/emergency_hub_screen.dart'
    as r_eh_game;

// ── Vocabulary screens ────────────────────────────────────────────────────────

import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart'
    as v_fc_game;
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_screen.dart'
    as v_ss_game;
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_screen.dart'
    as v_as_game;
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_screen.dart'
    as v_cc_game;
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_screen.dart'
    as v_pv_game;
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_screen.dart'
    as v_id_game;
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_screen.dart'
    as v_aw_game;
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_screen.dart'
    as v_tv_game;
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_screen.dart'
    as v_wf_game;
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_screen.dart'
    as v_ps_game;
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_screen.dart'
    as v_cu_game;
import 'package:vowl/features/vocabulary/collocations/presentation/pages/collocations_screen.dart'
    as v_co_game;
import 'package:vowl/features/vocabulary/jigsaw_puzzle/presentation/pages/jigsaw_puzzle_screen.dart'
    as v_jp_game;

/// Maps [GameSubtype] values to game screens wrapped in their required BlocProvider.
///
/// ### Pattern
/// Each `getXxxScreen(GameSubtype, int)` method:
/// 1. Provides the appropriate BLoC via `BlocProvider`.
/// 2. Delegates screen selection to the private `_getXxxScreenContent` helper.
///
/// This two-method pattern keeps BLoC injection and screen selection separated
/// and makes each half independently testable. All resolvers are static so
/// they can be referenced as function pointers in the routing map.
class AppRouterGameResolvers {
  AppRouterGameResolvers._(); // Non-instantiable.

  /// FIX (PRODUCTION READINESS / ERROR HANDLING): every `_getXxxScreenContent`
  /// switch below has a `default:` branch that silently substitutes a
  /// different screen within the same category. That fallback is necessary
  /// because `GameSubtype` is a single flat enum shared across all
  /// categories - `switch` can't be made exhaustive per-category without
  /// forcing every resolver to also handle every unrelated category's
  /// values - but it also means that if a new `GameSubtype` value is ever
  /// added without updating its resolver (or a category dispatcher sends
  /// the wrong subtype into the wrong resolver), the result today is a
  /// silent wrong-screen swap: no crash, no log, just a confusing "I picked
  /// X but got Y" bug report with nothing in Crashlytics to point at it.
  /// This helper turns that into a visible, non-fatal diagnostic while
  /// leaving the actual fallback behavior completely unchanged.
  static Widget _unhandledSubtype(
    GameSubtype gameType,
    String category,
    Widget fallback,
  ) {
    di.sl<AppLogger>().error(
      'AppRouterGameResolvers: Unhandled GameSubtype "${gameType.name}" '
      'reached the $category resolver\'s default case - falling back to '
      '"${fallback.runtimeType}". This means either a new GameSubtype was '
      'added without a matching case here, or a caller routed the wrong '
      'subtype into getXxxScreen() for this category.',
    );
    return fallback;
  }

  // ── Speaking ────────────────────────────────────────────────────────────────

  static Widget getSpeakingScreen(GameSubtype gameType, int level) {
    return BlocProvider<SpeakingBloc>(
      create: (_) => di.sl<SpeakingBloc>(),
      child: _getSpeakingScreenContent(gameType, level),
    );
  }

  static Widget _getSpeakingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.repeatSentence:
        return rs_game.RepeatSentenceScreen(level: level, gameType: gameType);
      case GameSubtype.speakMissingWord:
        return smw_game.SpeakMissingWordScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.situationSpeaking:
        return ss_game.SituationSpeakingScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.sceneDescriptionSpeaking:
        return sd_game.SceneDescriptionScreen(level: level, gameType: gameType);
      case GameSubtype.yesNoSpeaking:
        return yn_game.YesNoSpeakingScreen(level: level, gameType: gameType);
      case GameSubtype.speakSynonym:
        return ssyn_game.SpeakSynonymScreen(level: level, gameType: gameType);
      case GameSubtype.dialogueRoleplay:
        return dr_game.DialogueRoleplayScreen(level: level, gameType: gameType);
      case GameSubtype.pronunciationFocus:
        return pf_game.PronunciationFocusScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.speakOpposite:
        return sp_opp_game.SpeakOppositeScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.dailyExpression:
        return de_game.DailyExpressionScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'Speaking',
          rs_game.RepeatSentenceScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Reading ─────────────────────────────────────────────────────────────────

  static Widget getReadingScreen(GameSubtype gameType, int level) {
    return BlocProvider<ReadingBloc>(
      create: (_) => di.sl<ReadingBloc>(),
      child: _getReadingScreenContent(gameType, level),
    );
  }

  static Widget _getReadingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.readAndAnswer:
        return ra_game.ReadAndAnswerScreen(level: level, gameType: gameType);
      case GameSubtype.findWordMeaning:
        return fwm_game.FindWordMeaningScreen(level: level, gameType: gameType);
      case GameSubtype.trueFalseReading:
        return tfr_game.TrueFalseReadingScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.sentenceOrderReading:
        return so_game.SentenceOrderReadingScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.readingSpeedCheck:
        return rsc_game.ReadingSpeedCheckScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.guessTitle:
        return gt_game.GuessTitleScreen(level: level, gameType: gameType);
      case GameSubtype.readAndMatch:
        return ram_game.ReadAndMatchScreen(level: level, gameType: gameType);
      case GameSubtype.paragraphSummary:
        return ps_game.ParagraphSummaryScreen(level: level, gameType: gameType);
      case GameSubtype.readingInference:
        return ri_game.ReadingInferenceScreen(level: level, gameType: gameType);
      case GameSubtype.readingConclusion:
        return rcm_game.ReadingConclusionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.clozeTest:
        return ct_game.ClozeTestScreen(level: level, gameType: gameType);
      case GameSubtype.skimmingScanning:
        return ss_game_read.SkimmingScanningScreen(
          level: level,
          gameType: gameType,
        );
      default:
        return _unhandledSubtype(
          gameType,
          'Reading',
          ra_game.ReadAndAnswerScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Writing ─────────────────────────────────────────────────────────────────

  static Widget getWritingScreen(GameSubtype gameType, int level) {
    return BlocProvider<WritingBloc>(
      create: (_) => di.sl<WritingBloc>(),
      child: _getWritingScreenContent(gameType, level),
    );
  }

  static Widget _getWritingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.sentenceBuilder:
        return sb_game.SentenceBuilderScreen(level: level, gameType: gameType);
      case GameSubtype.completeSentence:
        return cs_game.CompleteSentenceScreen(level: level, gameType: gameType);
      case GameSubtype.describeSituationWriting:
        return ds_game.DescribeSituationScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.fixTheSentence:
        return fts_game.FixTheSentenceScreen(level: level, gameType: gameType);
      case GameSubtype.shortAnswerWriting:
        return sa_game.ShortAnswerScreen(level: level, gameType: gameType);
      case GameSubtype.opinionWriting:
        return ow_game.OpinionWritingScreen(level: level, gameType: gameType);
      case GameSubtype.dailyJournal:
        return dj_game.DailyJournalScreen(level: level, gameType: gameType);
      case GameSubtype.summarizeStoryWriting:
        return ssw_game.SummarizeStoryWritingScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.correctionWriting:
        return cw_game.CorrectionWritingScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.writingEmail:
        return we_game.WritingEmailScreen(level: level, gameType: gameType);
      case GameSubtype.essayDrafting:
        return ed_game.EssayDraftingScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'Writing',
          sb_game.SentenceBuilderScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Grammar ─────────────────────────────────────────────────────────────────

  static Widget getGrammarScreen(GameSubtype gameType, int level) {
    return BlocProvider<GrammarBloc>(
      create: (_) => di.sl<GrammarBloc>(),
      child: _getGrammarScreenContent(gameType, level),
    );
  }

  static Widget _getGrammarScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.grammarQuest:
        return gq_game.GrammarQuestScreen(level: level, gameType: gameType);
      case GameSubtype.sentenceCorrection:
        return g_sc_game.SentenceCorrectionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.wordReorder:
        return g_wr_game.WordReorderScreen(level: level, gameType: gameType);
      case GameSubtype.tenseMastery:
        return g_tm_game.TenseMasteryScreen(level: level, gameType: gameType);
      case GameSubtype.partsOfSpeech:
        return g_ps_game.PartsOfSpeechScreen(level: level, gameType: gameType);
      case GameSubtype.subjectVerbAgreement:
        return g_sva_game.SubjectVerbAgreementScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.articleInsertion:
        return g_ai_game.ArticleInsertionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.clauseConnector:
        return g_cc_game.ClauseConnectorScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.questionFormatter:
        return g_qf_game.QuestionFormatterScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.voiceSwap:
        return g_vs_game.VoiceSwapScreen(level: level, gameType: gameType);
      case GameSubtype.modifierPlacement:
        return g_mp_game.ModifierPlacementScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.conditionals:
        return g_cd_game.ConditionalsScreen(level: level, gameType: gameType);
      case GameSubtype.directIndirectSpeech:
        return g_di_game.DirectIndirectSpeechScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.pronounResolution:
        return g_pr_game.PronounResolutionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.punctuationMastery:
        return punc_game.PunctuationMasteryScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.modalsSelection:
        return g_ms_game.ModalsSelectionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.prepositionChoice:
        return g_pc_game.PrepositionChoiceScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.relativeClauses:
        return g_rc_game.RelativeClausesScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.conjunctions:
        return g_cj_game.ConjunctionsScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'Grammar',
          gq_game.GrammarQuestScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Listening ────────────────────────────────────────────────────────────────

  static Widget getListeningScreen(GameSubtype gameType, int level) {
    return BlocProvider<ListeningBloc>(
      create: (_) => di.sl<ListeningBloc>(),
      child: _getListeningScreenContent(gameType, level),
    );
  }

  static Widget _getListeningScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.audioFillBlanks:
        return l_afb_game.AudioFillBlanksScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.audioMultipleChoice:
        return l_amc_game.AudioMultipleChoiceScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.audioSentenceOrder:
        return l_aso_game.AudioSentenceOrderScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.audioTrueFalse:
        return l_atf_game.AudioTrueFalseScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.soundImageMatch:
        return l_sim_game.SoundImageMatchScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.fastSpeechDecoder:
        return l_fsd_game.FastSpeechDecoderScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.emotionRecognition:
        return l_er_game.EmotionRecognitionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.detailSpotlight:
        return l_ds_game.DetailSpotlightScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.listeningInference:
        return l_li_game.ListeningInferenceScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.ambientId:
        return l_ai_game.AmbientIdScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'Listening',
          l_afb_game.AudioFillBlanksScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Accent ───────────────────────────────────────────────────────────────────

  static Widget getAccentScreen(GameSubtype gameType, int level) {
    return BlocProvider<AccentBloc>(
      create: (_) => di.sl<AccentBloc>(),
      child: _getAccentScreenContent(gameType, level),
    );
  }

  static Widget _getAccentScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.minimalPairs:
        return a_mp_game.MinimalPairsScreen(level: level, gameType: gameType);
      case GameSubtype.intonationMimic:
        return a_im_game.IntonationMimicScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.syllableStress:
        return a_ss_game.SyllableStressScreen(level: level, gameType: gameType);
      case GameSubtype.wordLinking:
        return a_wl_game.WordLinkingScreen(level: level, gameType: gameType);
      case GameSubtype.shadowingChallenge:
        return a_sc_game.ShadowingChallengeScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.vowelDistinction:
        return a_vd_game.VowelDistinctionScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.consonantClarity:
        return a_cc_game.ConsonantClarityScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.pitchPatternMatch:
        return a_ppm_game.PitchPatternMatchScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.speedVariance:
        return a_sv_game.SpeedVarianceScreen(level: level, gameType: gameType);
      case GameSubtype.dialectDrill:
        return a_dd_game.DialectDrillScreen(level: level, gameType: gameType);
      case GameSubtype.connectedSpeech:
        return a_cs_game.ConnectedSpeechScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.pitchModulation:
        return a_pm_game.PitchModulationScreen(
          level: level,
          gameType: gameType,
        );
      default:
        return _unhandledSubtype(
          gameType,
          'Accent',
          a_mp_game.MinimalPairsScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Roleplay ─────────────────────────────────────────────────────────────────

  static Widget getRoleplayScreen(GameSubtype gameType, int level) {
    return BlocProvider<RoleplayBloc>(
      create: (_) => di.sl<RoleplayBloc>(),
      child: _getRoleplayScreenContent(gameType, level),
    );
  }

  static Widget _getRoleplayScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.branchingDialogue:
        return r_bd_game.BranchingDialogueScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.situationalResponse:
        return r_sr_game.SituationalResponseScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.jobInterview:
        return r_ji_game.JobInterviewScreen(level: level, gameType: gameType);
      case GameSubtype.medicalConsult:
        return r_mc_game.MedicalConsultScreen(level: level, gameType: gameType);
      case GameSubtype.gourmetOrder:
        return r_go_game.GourmetOrderScreen(level: level, gameType: gameType);
      case GameSubtype.travelDesk:
        return r_td_game.TravelDeskScreen(level: level, gameType: gameType);
      case GameSubtype.conflictResolver:
        return r_cr_game.ConflictResolverScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.elevatorPitch:
        return r_ep_game.ElevatorPitchScreen(level: level, gameType: gameType);
      case GameSubtype.socialSpark:
        return r_sk_game.SocialSparkScreen(level: level, gameType: gameType);
      case GameSubtype.emergencyHub:
        return r_eh_game.EmergencyHubScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'Roleplay',
          r_bd_game.BranchingDialogueScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Vocabulary ────────────────────────────────────────────────────────────────

  static Widget getVocabularyScreen(GameSubtype gameType, int level) {
    return BlocProvider<vocab.VocabularyBloc>(
      create: (_) => di.sl<vocab.VocabularyBloc>(),
      child: _getVocabularyScreenContent(gameType, level),
    );
  }

  static Widget _getVocabularyScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.flashcards:
        return v_fc_game.FlashcardsScreen(level: level, gameType: gameType);
      case GameSubtype.synonymSearch:
        return v_ss_game.SynonymSearchScreen(level: level, gameType: gameType);
      case GameSubtype.antonymSearch:
        return v_as_game.AntonymSearchScreen(level: level, gameType: gameType);
      case GameSubtype.contextClues:
        return v_cc_game.ContextCluesScreen(level: level, gameType: gameType);
      case GameSubtype.idioms:
        return v_id_game.IdiomsScreen(level: level, gameType: gameType);
      case GameSubtype.phrasalVerbs:
        return v_pv_game.PhrasalVerbsScreen(level: level, gameType: gameType);
      case GameSubtype.academicWord:
        return v_aw_game.AcademicWordScreen(level: level, gameType: gameType);
      case GameSubtype.topicVocab:
        return v_tv_game.TopicVocabScreen(level: level, gameType: gameType);
      case GameSubtype.wordFormation:
        return v_wf_game.WordFormationScreen(level: level, gameType: gameType);
      case GameSubtype.prefixSuffix:
        return v_ps_game.PrefixSuffixScreen(level: level, gameType: gameType);
      case GameSubtype.contextualUsage:
        return v_cu_game.ContextualUsageScreen(
          level: level,
          gameType: gameType,
        );
      case GameSubtype.collocations:
        return v_co_game.CollocationsScreen(level: level, gameType: gameType);
      case GameSubtype.jigsawPuzzle:
        return v_jp_game.JigsawPuzzleScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'Vocabulary',
          v_fc_game.FlashcardsScreen(level: level, gameType: gameType),
        );
    }
  }

  // ── Elite Mastery ─────────────────────────────────────────────────────────────

  static Widget getEliteMasteryScreen(GameSubtype gameType, int level) {
    return BlocProvider<EliteMasteryBloc>(
      create: (_) => di.sl<EliteMasteryBloc>(),
      // FIX (MEDIUM-5): Removed the unnecessary `Builder` wrapper that
      // previously wrapped the switch statement. The `Builder` created a new
      // BuildContext but that context was never used inside the callback —
      // `gameType` and `level` are captured from the enclosing scope, not
      // from context. Removing it makes this resolver consistent with all
      // other `getXxxScreen` methods in this class.
      child: _getEliteMasteryScreenContent(gameType, level),
    );
  }

  static Widget _getEliteMasteryScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.storyBuilder:
        return sb_elite.StoryBuilderScreen(level: level, gameType: gameType);
      case GameSubtype.idiomMatch:
        return im_elite.IdiomMatchScreen(level: level, gameType: gameType);
      case GameSubtype.speedSpelling:
        return ss_elite.SpeedSpellingScreen(level: level, gameType: gameType);
      case GameSubtype.accentShadowing:
        return as_elite.AccentShadowingScreen(level: level, gameType: gameType);
      default:
        return _unhandledSubtype(
          gameType,
          'EliteMastery',
          sb_elite.StoryBuilderScreen(level: level, gameType: gameType),
        );
    }
  }
}

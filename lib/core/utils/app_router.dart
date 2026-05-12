import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/auth/presentation/pages/login_page.dart';
import 'package:vowl/features/auth/presentation/pages/signup_page.dart';
import 'package:vowl/features/auth/presentation/pages/verify_email_page.dart';
import 'package:vowl/features/home/presentation/pages/home_screen.dart';
import 'package:vowl/features/home/presentation/pages/main_wrapper.dart';
import 'package:vowl/features/home/presentation/pages/category_games_page.dart';
import 'package:vowl/features/home/presentation/pages/quest_library_page.dart';
import 'package:vowl/features/home/presentation/pages/streak_screen.dart';
import 'package:vowl/features/home/presentation/pages/vowl_mascot_screen.dart';
import 'package:vowl/features/auth/presentation/pages/trophy_room_screen.dart';
import 'package:vowl/features/onboarding/presentation/pages/hatching_page.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

import 'package:vowl/core/utils/injection_container.dart' as di;

// --- SPEAKING SCREENS ---
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

// --- READING SCREENS ---
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

// --- WRITING SCREENS ---
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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart' as vocab;
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart' as sb_elite;
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_map.dart' as sb_map;
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_screen.dart' as im_elite;
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_map.dart' as im_map;
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart' as ss_elite;
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_map.dart' as ss_map;
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_screen.dart' as as_elite;
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_map.dart' as as_map;

// --- GRAMMAR SCREENS ---
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

// --- LISTENING SCREENS ---
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

// --- ACCENT SCREENS ---
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

// --- ROLEPLAY SCREENS ---
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

// --- VOCABULARY SCREENS ---
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

import 'package:vowl/features/games/presentation/pages/games_screen.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';
import 'package:vowl/features/profile/presentation/pages/profile_screen.dart';
import 'package:vowl/features/settings/presentation/pages/settings_screen.dart';
import 'package:vowl/features/leaderboard/presentation/pages/leaderboard_screen.dart';
import 'package:vowl/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vowl/features/settings/presentation/pages/admin_dashboard.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_level_screen.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:vowl/features/profile/presentation/pages/quest_coins_screen.dart';
import 'package:vowl/core/presentation/pages/quest_sequence_page.dart';
import 'package:vowl/features/splash/presentation/pages/splash_page.dart';
import 'dart:async';
import 'package:vowl/core/presentation/widgets/auth_gate.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/sticker_book_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/mascot_selection_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_zone_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_level_map.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/alphabet_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/numbers_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/colors_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/shapes_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/animals_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/fruits_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/family_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/school_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/verbs_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/routine_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/emotions_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/prepositions_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/phonics_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/time_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/opposites_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/day_night_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/nature_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/home_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/food_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/transport_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/body_parts_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/clothing_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/buddy_boutique_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_room_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/admin/kids_admin_screen.dart';
import 'package:vowl/core/utils/discovery_helper.dart';

class AppRouter {
  static const String initialRoute = '/splash';
  static const String splashRoute = '/splash';
  static const String homeRoute = '/home';
  static const String gamesRoute = '/games';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String premiumRoute = '/premium';
  static const String profileRoute = '/profile';
  static const String adminRoute = '/admin';
  static const String settingsRoute = '/settings';
  static const String leaderboardRoute = '/leaderboard';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String trophyRoomRoute = '/trophy-room';
  static const String verifyEmailRoute = '/verify-email';
  static const String levelsRoute = '/levels';
  static const String categoryGamesRoute = '/category-games';
  static const String libraryRoute = '/library';
  static const String streakRoute = '/streak';
  static const String levelRoute = '/level-details';
  static const String adventureXPRoute = '/xp-details';
  static const String questCoinsRoute = '/coins-details';
  static const String questSequenceRoute = '/quest-sequence';
  static const String kidsZoneRoute = '/kids-zone';
  static const String kidsLevelMapRoute = '/kids/map/:gameType';
  static const String kidsAlphabetRoute = '/kids-alphabet';
  static const String kidsNumbersRoute = '/kids-numbers';
  static const String kidsColorsRoute = '/kids-colors';
  static const String kidsShapesRoute = '/kids-shapes';
  static const String kidsAnimalsRoute = '/kids-animals';
  static const String kidsFruitsRoute = '/kids-fruits';
  static const String kidsFamilyRoute = '/kids-family';
  static const String kidsSchoolRoute = '/kids-school';
  static const String kidsVerbsRoute = '/kids-verbs';
  static const String kidsStickerBookRoute = '/kids-stickers';
  static const String kidsMascotSelectionRoute = '/kids-mascot';
  static const String kidsRoutineRoute = '/kids-routine';
  static const String kidsEmotionsRoute = '/kids-emotions';
  static const String kidsPrepositionsRoute = '/kids-prepositions';
  static const String kidsPhonicsRoute = '/kids-phonics';
  static const String kidsTimeRoute = '/kids-time';
  static const String kidsOppositesRoute = '/kids-opposites';
  static const String kidsDayNightRoute = '/kids-day-night';
  static const String kidsNatureRoute = '/kids-nature';
  static const String kidsHomeRoute = '/kids-home';
  static const String kidsFoodRoute = '/kids-food';
  static const String kidsTransportRoute = '/kids-transport';
  static const String kidsBodyPartsRoute = '/kids-body-parts';
  static const String kidsClothingRoute = '/kids-clothing';
  static const String kidsBuddyBoutiqueRoute = '/kids-zone/boutique';
  static const String kidsAdminRoute = '/kids-admin';
  static const String kidsRoomRoute = '/kids-room';
  static const String hatchingRoute = '/hatching';
  static const String vowlMascotRoute = '/vowl-mascot';

  static String getKidsGameTitle(String gameType) {
    switch (gameType) {
      case 'alphabet':
        return 'Alphabet';
      case 'numbers':
        return 'Numbers';
      case 'colors':
        return 'Colors';
      case 'shapes':
        return 'Shapes';
      case 'animals':
        return 'Animals';
      case 'fruits':
        return 'Fruits';
      case 'family':
        return 'Family';
      case 'school':
        return 'School';
      case 'verbs':
        return 'Verbs';
      case 'routine':
        return 'Routine';
      case 'emotions':
        return 'Emotions';
      case 'prepositions':
        return 'Prepositions';
      case 'phonics':
        return 'Phonics';
      case 'jumble':
        return 'Jumble';
      case 'time':
        return 'Time';
      case 'opposites':
        return 'Opposites';
      case 'day_night':
        return 'Day/Night';
      case 'nature':
        return 'Nature';
      case 'home':
        return 'Home';
      case 'food':
        return 'Food';
      case 'transport':
        return 'Transport';
      case 'body_parts':
        return 'Body Parts';
      case 'clothing':
        return 'Clothing';
      default:
        return 'Kids Game';
    }
  }

  static Color getKidsGameColor(String gameType) {
    switch (gameType) {
      case 'alphabet':
        return const Color(0xFFF43F5E);
      case 'numbers':
        return const Color(0xFF0EA5E9);
      case 'colors':
        return const Color(0xFFF59E0B);
      case 'shapes':
        return const Color(0xFF10B981);
      case 'animals':
        return const Color(0xFF6366F1);
      case 'fruits':
        return const Color(0xFFEF4444);
      case 'family':
        return const Color(0xFFEC4899);
      case 'school':
        return const Color(0xFFF59E0B);
      case 'verbs':
        return const Color(0xFF8B5CF6);
      case 'routine':
        return const Color(0xFFF97316);
      case 'emotions':
        return const Color(0xFF06B6D4);
      case 'prepositions':
        return const Color(0xFF64748B);
      case 'phonics':
        return const Color(0xFFFFCC00);
      case 'jumble':
        return const Color(0xFFF43F5E);
      case 'time':
        return const Color(0xFF333333);
      case 'opposites':
        return const Color(0xFF94A3B8);
      case 'day_night':
        return const Color(0xFF1E293B);
      case 'nature':
        return const Color(0xFF16A34A);
      case 'home':
        return const Color(0xFFD946EF);
      case 'food':
        return const Color(0xFFFB923C);
      case 'transport':
        return const Color(0xFF2563EB);
      case 'body_parts':
        return const Color(0xFFF43F5E);
      case 'clothing':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.blue;
    }
  }

  /// Creates a fade transition page that prevents the white flash during navigation.
  /// Wraps the child in a dark Container so no white Scaffold peeks through.
  static Page<void> _fadeTransitionPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  static final router = GoRouter(
    initialLocation: initialRoute,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    refreshListenable: _StreamListenable(di.sl<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = di.sl<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isVerified = authState.user?.isEmailVerified ?? false;

      final isLoginRoute = state.uri.path == loginRoute;
      final isSignupRoute = state.uri.path == signupRoute;
      final isForgotPasswordRoute = state.uri.path == forgotPasswordRoute;
      final isSplashRoute = state.uri.path == splashRoute;

      if (isSplashRoute) return null;

      final isVerifyEmailRoute = state.uri.path == verifyEmailRoute;
      final isHatchingRoute = state.uri.path == hatchingRoute;

      final isAuthRoute =
          isLoginRoute || isSignupRoute || isForgotPasswordRoute;

      // Routes that should not trigger a redirect to login during transitions
      final isTransitionRoute = isVerifyEmailRoute || isHatchingRoute;

      // 1. Wait for Auth State (Prevent early redirect during initialization)
      if (authState.status == AuthStatus.unknown) {
        // If we are not already on the splash screen, go there
        return isSplashRoute ? null : splashRoute;
      }

      // 2. Handle Unauthenticated Users
      if (!isAuthenticated) {
        if (!isAuthRoute && !isTransitionRoute && !isSplashRoute) {
          return loginRoute;
        }
        return null;
      } else {
        if (isAuthRoute) {
          return isVerified ? homeRoute : verifyEmailRoute;
        }
        if (!isVerified) {
          // Only force verification redirect if we are coming from the auth/start flow.
          // This prevents interrupting users who are already active in the app.
          if (isAuthRoute || isSplashRoute || state.uri.path == '/') {
            return verifyEmailRoute;
          }
        } else {
          if (state.uri.path == verifyEmailRoute) {
            return homeRoute;
          }
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: splashRoute,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      GoRoute(path: loginRoute, builder: (context, state) => const LoginPage()),
      GoRoute(
        path: signupRoute,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: forgotPasswordRoute,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: verifyEmailRoute,
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: hatchingRoute,
        builder: (context, state) {
          final name = state.uri.queryParameters['name'] ?? 'Traveler';
          return HatchingPage(userName: name);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainWrapper(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: homeRoute,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: gamesRoute,
                builder: (context, state) => const GamesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: leaderboardRoute,
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: profileRoute,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: settingsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const SettingsScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: trophyRoomRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const TrophyRoomScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: vowlMascotRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const VowlMascotScreen(),
          state: state,
        ),
      ),

      GoRoute(
        path: kidsZoneRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: BlocProvider<KidsBloc>(
            create: (context) => di.sl<KidsBloc>(),
            child: const KidsZoneScreen(),
          ),
          state: state,
        ),
        routes: [
          GoRoute(
            path: 'boutique',
            name: 'kids-boutique',
            pageBuilder: (context, state) => _fadeTransitionPage(
              child: const BuddyBoutiqueScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: 'map/:gameType',
            builder: (context, state) {
              final gameType = state.pathParameters['gameType'] ?? 'alphabet';
              final extra = state.extra as Map<String, dynamic>?;
              final title = extra?['title'] as String? ?? 'Level Map';
              final primaryColor = extra?['primaryColor'] as Color? ?? Colors.blue;

              return BlocProvider<KidsBloc>(
                create: (context) => di.sl<KidsBloc>(),
                child: KidsLevelMap(
                  gameType: gameType,
                  title: title,
                  primaryColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: kidsStickerBookRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const StickerBookScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsMascotSelectionRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const MascotSelectionScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsLevelMapRoute,
        pageBuilder: (context, state) {
          final gameType = state.pathParameters['gameType'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;

          return _fadeTransitionPage(
            child: _getKidsBlocWrapper(
              KidsLevelMap(
                gameType: gameType.isEmpty
                    ? (extra?['gameType'] as String? ?? 'alphabet')
                    : gameType,
                title: extra?['title'] as String? ?? getKidsGameTitle(gameType),
                primaryColor: extra?['primaryColor'] as Color? ?? getKidsGameColor(gameType),
              ),
            ),
            state: state,
          );
        },
      ),
      GoRoute(
        path: kidsAlphabetRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(AlphabetGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsNumbersRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(NumbersGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsColorsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(ColorsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsShapesRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(ShapesGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsAnimalsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(AnimalsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsFruitsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(FruitsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsFamilyRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(FamilyGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsSchoolRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(SchoolGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsVerbsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(VerbsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsRoutineRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(RoutineGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsEmotionsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(EmotionsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsPrepositionsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(PrepositionsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsPhonicsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(PhonicsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsTimeRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(TimeGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsOppositesRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(OppositesGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsDayNightRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(DayNightGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsNatureRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(NatureGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsHomeRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(HomeGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsFoodRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(FoodGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsTransportRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(TransportGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsBodyPartsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(BodyPartsGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsClothingRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: _getKidsBlocWrapper(ClothingGameScreen(level: state.extra as int? ?? 1)),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsAdminRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const KidsAdminScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: kidsRoomRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const KidsRoomScreen(),
          state: state,
        ),
      ),

      GoRoute(
        path: '/game',
        pageBuilder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? 'reading';
          final level =
              int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
          final gameTypeStr =
              state.uri.queryParameters['gameType'] ??
              state.uri.queryParameters['subtype'];

          Widget screen;
          switch (category.toLowerCase()) {
            case 'reading':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.readAndAnswer,
                    )
                  : GameSubtype.readAndAnswer;
              screen = _getReadingScreen(gameType, level);
              break;
            case 'writing':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.sentenceBuilder,
                    )
                  : GameSubtype.sentenceBuilder;
              screen = _getWritingScreen(gameType, level);
              break;
            case 'speaking':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.repeatSentence,
                    )
                  : GameSubtype.repeatSentence;
              screen = _getSpeakingScreen(gameType, level);
              break;
            case 'grammar':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.grammarQuest,
                    )
                  : GameSubtype.grammarQuest;
              screen = _getGrammarScreen(gameType, level);
              break;
            case 'roleplay':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.branchingDialogue,
                    )
                  : GameSubtype.branchingDialogue;
              screen = _getRoleplayScreen(gameType, level);
              break;
            case 'accent':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.minimalPairs,
                    )
                  : GameSubtype.minimalPairs;
              screen = _getAccentScreen(gameType, level);
              break;
            case 'listening':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.audioMultipleChoice,
                    )
                  : GameSubtype.audioMultipleChoice;
              screen = _getListeningScreen(gameType, level);
              break;
            case 'vocabulary':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.flashcards,
                    )
                  : GameSubtype.flashcards;
              screen = _getVocabularyScreen(gameType, level);
              break;
            case 'elitemastery':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.storyBuilder,
                    )
                  : GameSubtype.storyBuilder;
              screen = _getEliteMasteryScreen(gameType, level);
              break;
            default:
              screen = _getReadingScreen(GameSubtype.readAndAnswer, level);
          }
          return _fadeTransitionPage(child: screen, state: state);
        },
      ),

      GoRoute(
        path: '/levels',
        pageBuilder: (context, state) {
          final categoryId = state.uri.queryParameters['category'] ?? 'reading';
          final gameType = state.uri.queryParameters['gameType'] ?? 'readAndAnswer';

          return _fadeTransitionPage(
            child: ModernCategoryMap(
              gameType: gameType,
              categoryId: categoryId,
            ),
            state: state,
          );
        },
      ),
      GoRoute(
        path: categoryGamesRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: CategoryGamesPage(
            categoryId: state.uri.queryParameters['category'] ?? 'speaking',
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: libraryRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const QuestLibraryPage(),
          state: state,
        ),
      ),
      GoRoute(
        path: premiumRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const PremiumScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: streakRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const StreakScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: adminRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const AdminDashboard(),
          state: state,
        ),
      ),
      // --- ELITE MASTERY MODULAR ROUTES ---
      GoRoute(
        path: '/story-builder-map',
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const sb_map.StoryBuilderMap(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/story-builder/:level',
        pageBuilder: (context, state) {
          final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
          return _fadeTransitionPage(
            child: _getEliteMasteryScreen(GameSubtype.storyBuilder, level),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/idiom-match-map',
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const im_map.IdiomMatchMap(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/idiom-match/:level',
        pageBuilder: (context, state) {
          final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
          return _fadeTransitionPage(
            child: _getEliteMasteryScreen(GameSubtype.idiomMatch, level),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/speed-spelling-map',
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const ss_map.SpeedSpellingMap(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/speed-spelling/:level',
        pageBuilder: (context, state) {
          final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
          return _fadeTransitionPage(
            child: _getEliteMasteryScreen(GameSubtype.speedSpelling, level),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/accent-shadowing-map',
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const as_map.AccentShadowingMap(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/accent-shadowing/:level',
        pageBuilder: (context, state) {
          final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
          return _fadeTransitionPage(
            child: _getEliteMasteryScreen(GameSubtype.accentShadowing, level),
            state: state,
          );
        },
      ),
      GoRoute(
        path: levelRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const AdventureLevelScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: adventureXPRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const AdventureXPScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: questCoinsRoute,
        pageBuilder: (context, state) => _fadeTransitionPage(
          child: const VowlCoinsScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: questSequenceRoute,
        pageBuilder: (context, state) {
          final sequenceId = state.uri.queryParameters['id'] ?? 'daily_duo';
          final user = di.sl<AuthBloc>().state.user;
          final quests = user != null
              ? DiscoveryHelper.getQuestsForSequence(sequenceId, user)
              : <GameQuest>[];
          return _fadeTransitionPage(
            child: QuestSequencePage(sequenceId: sequenceId, quests: quests),
            state: state,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    ),
  );

  static Widget _getSpeakingScreen(GameSubtype gameType, int level) {
    return BlocProvider<SpeakingBloc>(
      create: (context) => di.sl<SpeakingBloc>(),
      child: _getSpeakingScreenContent(gameType, level),
    );
  }

  static Widget _getSpeakingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.repeatSentence:
        return rs_game.RepeatSentenceScreen(level: level, gameType: gameType);
      case GameSubtype.speakMissingWord:
        return smw_game.SpeakMissingWordScreen(level: level, gameType: gameType);
      case GameSubtype.situationSpeaking:
        return ss_game.SituationSpeakingScreen(level: level, gameType: gameType);
      case GameSubtype.sceneDescriptionSpeaking:
        return sd_game.SceneDescriptionScreen(level: level, gameType: gameType);
      case GameSubtype.yesNoSpeaking:
        return yn_game.YesNoSpeakingScreen(level: level, gameType: gameType);
      case GameSubtype.speakSynonym:
        return ssyn_game.SpeakSynonymScreen(level: level, gameType: gameType);
      case GameSubtype.dialogueRoleplay:
        return dr_game.DialogueRoleplayScreen(level: level, gameType: gameType);
      case GameSubtype.pronunciationFocus:
        return pf_game.PronunciationFocusScreen(level: level, gameType: gameType);
      case GameSubtype.speakOpposite:
        return sp_opp_game.SpeakOppositeScreen(level: level, gameType: gameType);
      case GameSubtype.dailyExpression:
        return de_game.DailyExpressionScreen(level: level, gameType: gameType);
      default:
        return rs_game.RepeatSentenceScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getReadingScreen(GameSubtype gameType, int level) {
    return BlocProvider<ReadingBloc>(
      create: (context) => di.sl<ReadingBloc>(),
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
        return tfr_game.TrueFalseReadingScreen(level: level, gameType: gameType);
      case GameSubtype.sentenceOrderReading:
        return so_game.SentenceOrderReadingScreen(level: level, gameType: gameType);
      case GameSubtype.readingSpeedCheck:
        return rsc_game.ReadingSpeedCheckScreen(level: level, gameType: gameType);
      case GameSubtype.guessTitle:
        return gt_game.GuessTitleScreen(level: level, gameType: gameType);
      case GameSubtype.readAndMatch:
        return ram_game.ReadAndMatchScreen(level: level, gameType: gameType);
      case GameSubtype.paragraphSummary:
        return ps_game.ParagraphSummaryScreen(level: level, gameType: gameType);
      case GameSubtype.readingInference:
        return ri_game.ReadingInferenceScreen(level: level, gameType: gameType);
      case GameSubtype.readingConclusion:
        return rcm_game.ReadingConclusionScreen(level: level, gameType: gameType);
      case GameSubtype.clozeTest:
        return ct_game.ClozeTestScreen(level: level, gameType: gameType);
      case GameSubtype.skimmingScanning:
        return ss_game_read.SkimmingScanningScreen(level: level, gameType: gameType);
      default:
        return ra_game.ReadAndAnswerScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getWritingScreen(GameSubtype gameType, int level) {
    return BlocProvider<WritingBloc>(
      create: (context) => di.sl<WritingBloc>(),
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
        return ds_game.DescribeSituationScreen(level: level, gameType: gameType);
      case GameSubtype.fixTheSentence:
        return fts_game.FixTheSentenceScreen(level: level, gameType: gameType);
      case GameSubtype.shortAnswerWriting:
        return sa_game.ShortAnswerScreen(level: level, gameType: gameType);
      case GameSubtype.opinionWriting:
        return ow_game.OpinionWritingScreen(level: level, gameType: gameType);
      case GameSubtype.dailyJournal:
        return dj_game.DailyJournalScreen(level: level, gameType: gameType);
      case GameSubtype.summarizeStoryWriting:
        return ssw_game.SummarizeStoryWritingScreen(level: level, gameType: gameType);
      case GameSubtype.correctionWriting:
        return cw_game.CorrectionWritingScreen(level: level, gameType: gameType);
      case GameSubtype.writingEmail:
        return we_game.WritingEmailScreen(level: level, gameType: gameType);
      case GameSubtype.essayDrafting:
        return ed_game.EssayDraftingScreen(level: level, gameType: gameType);
      default:
        return sb_game.SentenceBuilderScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getGrammarScreen(GameSubtype gameType, int level) {
    return BlocProvider<GrammarBloc>(
      create: (context) => di.sl<GrammarBloc>(),
      child: _getGrammarScreenContent(gameType, level),
    );
  }

  static Widget _getGrammarScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.grammarQuest:
        return gq_game.GrammarQuestScreen(level: level, gameType: gameType);
      case GameSubtype.sentenceCorrection:
        return g_sc_game.SentenceCorrectionScreen(level: level, gameType: gameType);
      case GameSubtype.wordReorder:
        return g_wr_game.WordReorderScreen(level: level, gameType: gameType);
      case GameSubtype.tenseMastery:
        return g_tm_game.TenseMasteryScreen(level: level, gameType: gameType);
      case GameSubtype.partsOfSpeech:
        return g_ps_game.PartsOfSpeechScreen(level: level, gameType: gameType);
      case GameSubtype.subjectVerbAgreement:
        return g_sva_game.SubjectVerbAgreementScreen(level: level, gameType: gameType);
      case GameSubtype.articleInsertion:
        return g_ai_game.ArticleInsertionScreen(level: level, gameType: gameType);
      case GameSubtype.clauseConnector:
        return g_cc_game.ClauseConnectorScreen(level: level, gameType: gameType);
      case GameSubtype.questionFormatter:
        return g_qf_game.QuestionFormatterScreen(level: level, gameType: gameType);
      case GameSubtype.voiceSwap:
        return g_vs_game.VoiceSwapScreen(level: level, gameType: gameType);
      case GameSubtype.modifierPlacement:
        return g_mp_game.ModifierPlacementScreen(level: level, gameType: gameType);
      case GameSubtype.conditionals:
        return g_cd_game.ConditionalsScreen(level: level, gameType: gameType);
      case GameSubtype.directIndirectSpeech:
        return g_di_game.DirectIndirectSpeechScreen(level: level, gameType: gameType);
      case GameSubtype.pronounResolution:
        return g_pr_game.PronounResolutionScreen(level: level, gameType: gameType);
      case GameSubtype.punctuationMastery:
        return punc_game.PunctuationMasteryScreen(level: level, gameType: gameType);
      case GameSubtype.modalsSelection:
        return g_ms_game.ModalsSelectionScreen(level: level, gameType: gameType);
      case GameSubtype.prepositionChoice:
        return g_pc_game.PrepositionChoiceScreen(level: level, gameType: gameType);
      case GameSubtype.relativeClauses:
        return g_rc_game.RelativeClausesScreen(level: level, gameType: gameType);
      case GameSubtype.conjunctions:
        return g_cj_game.ConjunctionsScreen(level: level, gameType: gameType);
      default:
        return gq_game.GrammarQuestScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getListeningScreen(GameSubtype gameType, int level) {
    return BlocProvider<ListeningBloc>(
      create: (context) => di.sl<ListeningBloc>(),
      child: _getListeningScreenContent(gameType, level),
    );
  }

  static Widget _getListeningScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.audioFillBlanks:
        return l_afb_game.AudioFillBlanksScreen(level: level, gameType: gameType);
      case GameSubtype.audioMultipleChoice:
        return l_amc_game.AudioMultipleChoiceScreen(level: level, gameType: gameType);
      case GameSubtype.audioSentenceOrder:
        return l_aso_game.AudioSentenceOrderScreen(level: level, gameType: gameType);
      case GameSubtype.audioTrueFalse:
        return l_atf_game.AudioTrueFalseScreen(level: level, gameType: gameType);
      case GameSubtype.soundImageMatch:
        return l_sim_game.SoundImageMatchScreen(level: level, gameType: gameType);
      case GameSubtype.fastSpeechDecoder:
        return l_fsd_game.FastSpeechDecoderScreen(level: level, gameType: gameType);
      case GameSubtype.emotionRecognition:
        return l_er_game.EmotionRecognitionScreen(level: level, gameType: gameType);
      case GameSubtype.detailSpotlight:
        return l_ds_game.DetailSpotlightScreen(level: level, gameType: gameType);
      case GameSubtype.listeningInference:
        return l_li_game.ListeningInferenceScreen(level: level, gameType: gameType);
      case GameSubtype.ambientId:
        return l_ai_game.AmbientIdScreen(level: level, gameType: gameType);
      default:
        return l_afb_game.AudioFillBlanksScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getAccentScreen(GameSubtype gameType, int level) {
    return BlocProvider<AccentBloc>(
      create: (context) => di.sl<AccentBloc>(),
      child: _getAccentScreenContent(gameType, level),
    );
  }

  static Widget _getAccentScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.minimalPairs:
        return a_mp_game.MinimalPairsScreen(level: level, gameType: gameType);
      case GameSubtype.intonationMimic:
        return a_im_game.IntonationMimicScreen(level: level, gameType: gameType);
      case GameSubtype.syllableStress:
        return a_ss_game.SyllableStressScreen(level: level, gameType: gameType);
      case GameSubtype.wordLinking:
        return a_wl_game.WordLinkingScreen(level: level, gameType: gameType);
      case GameSubtype.shadowingChallenge:
        return a_sc_game.ShadowingChallengeScreen(level: level, gameType: gameType);
      case GameSubtype.vowelDistinction:
        return a_vd_game.VowelDistinctionScreen(level: level, gameType: gameType);
      case GameSubtype.consonantClarity:
        return a_cc_game.ConsonantClarityScreen(level: level, gameType: gameType);
      case GameSubtype.pitchPatternMatch:
        return a_ppm_game.PitchPatternMatchScreen(level: level, gameType: gameType);
      case GameSubtype.speedVariance:
        return a_sv_game.SpeedVarianceScreen(level: level, gameType: gameType);
      case GameSubtype.dialectDrill:
        return a_dd_game.DialectDrillScreen(level: level, gameType: gameType);
      default:
        return a_mp_game.MinimalPairsScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getRoleplayScreen(GameSubtype gameType, int level) {
    return BlocProvider<RoleplayBloc>(
      create: (context) => di.sl<RoleplayBloc>(),
      child: _getRoleplayScreenContent(gameType, level),
    );
  }

  static Widget _getRoleplayScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.branchingDialogue:
        return r_bd_game.BranchingDialogueScreen(level: level, gameType: gameType);
      case GameSubtype.situationalResponse:
        return r_sr_game.SituationalResponseScreen(level: level, gameType: gameType);
      case GameSubtype.jobInterview:
        return r_ji_game.JobInterviewScreen(level: level, gameType: gameType);
      case GameSubtype.medicalConsult:
        return r_mc_game.MedicalConsultScreen(level: level, gameType: gameType);
      case GameSubtype.gourmetOrder:
        return r_go_game.GourmetOrderScreen(level: level, gameType: gameType);
      case GameSubtype.travelDesk:
        return r_td_game.TravelDeskScreen(level: level, gameType: gameType);
      case GameSubtype.conflictResolver:
        return r_cr_game.ConflictResolverScreen(level: level, gameType: gameType);
      case GameSubtype.elevatorPitch:
        return r_ep_game.ElevatorPitchScreen(level: level, gameType: gameType);
      case GameSubtype.socialSpark:
        return r_sk_game.SocialSparkScreen(level: level, gameType: gameType);
      case GameSubtype.emergencyHub:
        return r_eh_game.EmergencyHubScreen(level: level, gameType: gameType);
      default:
        return r_bd_game.BranchingDialogueScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getVocabularyScreen(GameSubtype gameType, int level) {
    return BlocProvider<vocab.VocabularyBloc>(
      create: (context) => di.sl<vocab.VocabularyBloc>(),
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
        return v_cu_game.ContextualUsageScreen(level: level, gameType: gameType);
      case GameSubtype.collocations:
        return v_co_game.CollocationsScreen(level: level, gameType: gameType);
      default:
        return v_fc_game.FlashcardsScreen(level: level, gameType: gameType);
    }
  }

  static Widget _getEliteMasteryScreen(GameSubtype gameType, int level) {
    return BlocProvider<EliteMasteryBloc>(
      create: (context) => di.sl<EliteMasteryBloc>(),
      child: Builder(
        builder: (context) {
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
              return sb_elite.StoryBuilderScreen(level: level, gameType: gameType);
          }
        },
      ),
    );
  }


  static Widget _getKidsBlocWrapper(Widget child) {
    return BlocProvider<KidsBloc>(
      create: (context) => di.sl<KidsBloc>(),
      child: child,
    );
  }
}

class _StreamListenable extends ChangeNotifier {
  final Stream stream;
  late final StreamSubscription subscription;

  _StreamListenable(this.stream) {
    subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}

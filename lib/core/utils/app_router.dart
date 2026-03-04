import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/features/auth/presentation/pages/login_page.dart';
import 'package:voxai_quest/features/auth/presentation/pages/signup_page.dart';
import 'package:voxai_quest/features/auth/presentation/pages/verify_email_page.dart';
import 'package:voxai_quest/features/home/presentation/pages/home_screen.dart';
import 'package:voxai_quest/features/home/presentation/pages/main_wrapper.dart';
import 'package:voxai_quest/features/home/presentation/pages/category_games_page.dart';
import 'package:voxai_quest/features/home/presentation/pages/quest_library_page.dart';
import 'package:voxai_quest/features/home/presentation/pages/streak_screen.dart';
import 'package:voxai_quest/features/home/presentation/pages/voxin_mascot_screen.dart';

import 'package:voxai_quest/core/utils/injection_container.dart' as di;

// Game Map Imports with Consistent Aliases
// --- SPEAKING IMPORTS ---
import 'package:voxai_quest/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_map.dart'
    as rs_map;
import 'package:voxai_quest/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_screen.dart'
    as rs_game;
import 'package:voxai_quest/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_map.dart'
    as smw_map;
import 'package:voxai_quest/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart'
    as smw_game;
import 'package:voxai_quest/features/speaking/situation_speaking/presentation/pages/situation_speaking_map.dart'
    as ss_map;
import 'package:voxai_quest/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart'
    as ss_game;
import 'package:voxai_quest/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_map.dart'
    as sd_map;
import 'package:voxai_quest/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart'
    as sd_game;
import 'package:voxai_quest/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_map.dart'
    as yn_map;
import 'package:voxai_quest/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart'
    as yn_game;
import 'package:voxai_quest/features/speaking/speak_synonym/presentation/pages/speak_synonym_map.dart'
    as ssyn_map;
import 'package:voxai_quest/features/speaking/speak_synonym/presentation/pages/speak_synonym_screen.dart'
    as ssyn_game;
import 'package:voxai_quest/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_map.dart'
    as dr_map;
import 'package:voxai_quest/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart'
    as dr_game;
import 'package:voxai_quest/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_map.dart'
    as pf_map;
import 'package:voxai_quest/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart'
    as pf_game;
import 'package:voxai_quest/features/speaking/speak_opposite/presentation/pages/speak_opposite_map.dart'
    as sp_opp_map;
import 'package:voxai_quest/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart'
    as sp_opp_game;
import 'package:voxai_quest/features/speaking/daily_expression/presentation/pages/daily_expression_map.dart'
    as de_map;
import 'package:voxai_quest/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart'
    as de_game;

// --- READING IMPORTS ---
import 'package:voxai_quest/features/reading/read_and_answer/presentation/pages/read_and_answer_map.dart'
    as ra_map;
import 'package:voxai_quest/features/reading/read_and_answer/presentation/pages/read_and_answer_screen.dart'
    as ra_game;
import 'package:voxai_quest/features/reading/find_word_meaning/presentation/pages/find_word_meaning_map.dart'
    as fwm_map;
import 'package:voxai_quest/features/reading/find_word_meaning/presentation/pages/find_word_meaning_screen.dart'
    as fwm_game;
import 'package:voxai_quest/features/reading/true_false_reading/presentation/pages/true_false_reading_map.dart'
    as tfr_map;
import 'package:voxai_quest/features/reading/true_false_reading/presentation/pages/true_false_reading_screen.dart'
    as tfr_game;
import 'package:voxai_quest/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_map.dart'
    as so_map;
import 'package:voxai_quest/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_screen.dart'
    as so_game;
import 'package:voxai_quest/features/reading/reading_speed_check/presentation/pages/reading_speed_check_map.dart'
    as rsc_map;
import 'package:voxai_quest/features/reading/reading_speed_check/presentation/pages/reading_speed_check_screen.dart'
    as rsc_game;
import 'package:voxai_quest/features/reading/guess_title/presentation/pages/guess_title_map.dart'
    as gt_map;
import 'package:voxai_quest/features/reading/guess_title/presentation/pages/guess_title_screen.dart'
    as gt_game;
import 'package:voxai_quest/features/reading/read_and_match/presentation/pages/read_and_match_map.dart'
    as ram_map;
import 'package:voxai_quest/features/reading/read_and_match/presentation/pages/read_and_match_screen.dart'
    as ram_game;
import 'package:voxai_quest/features/reading/paragraph_summary/presentation/pages/paragraph_summary_map.dart'
    as ps_map;
import 'package:voxai_quest/features/reading/paragraph_summary/presentation/pages/paragraph_summary_screen.dart'
    as ps_game;
import 'package:voxai_quest/features/reading/reading_inference/presentation/pages/reading_inference_map.dart'
    as ri_map;
import 'package:voxai_quest/features/reading/reading_inference/presentation/pages/reading_inference_screen.dart'
    as ri_game;
import 'package:voxai_quest/features/reading/reading_conclusion/presentation/pages/reading_conclusion_map.dart'
    as rcm_map;
import 'package:voxai_quest/features/reading/reading_conclusion/presentation/pages/reading_conclusion_screen.dart'
    as rcm_game;

// --- WRITING IMPORTS ---
import 'package:voxai_quest/features/writing/sentence_builder/presentation/pages/sentence_builder_map.dart'
    as sb_map;
import 'package:voxai_quest/features/writing/sentence_builder/presentation/pages/sentence_builder_screen.dart'
    as sb_game;
import 'package:voxai_quest/features/writing/complete_sentence/presentation/pages/complete_sentence_map.dart'
    as cs_map;
import 'package:voxai_quest/features/writing/complete_sentence/presentation/pages/complete_sentence_screen.dart'
    as cs_game;
import 'package:voxai_quest/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_map.dart'
    as ds_map;
import 'package:voxai_quest/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_screen.dart'
    as ds_game;
import 'package:voxai_quest/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_map.dart'
    as fts_map;
import 'package:voxai_quest/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_screen.dart'
    as fts_game;
import 'package:voxai_quest/features/writing/short_answer_writing/presentation/pages/short_answer_writing_map.dart'
    as sa_map;
import 'package:voxai_quest/features/writing/short_answer_writing/presentation/pages/short_answer_writing_screen.dart'
    as sa_game;
import 'package:voxai_quest/features/writing/opinion_writing/presentation/pages/opinion_writing_map.dart'
    as ow_map;
import 'package:voxai_quest/features/writing/opinion_writing/presentation/pages/opinion_writing_screen.dart'
    as ow_game;
import 'package:voxai_quest/features/writing/daily_journal/presentation/pages/daily_journal_map.dart'
    as dj_map;
import 'package:voxai_quest/features/writing/daily_journal/presentation/pages/daily_journal_screen.dart'
    as dj_game;
import 'package:voxai_quest/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_map.dart'
    as ssw_map;
import 'package:voxai_quest/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_screen.dart'
    as ssw_game;
import 'package:voxai_quest/features/writing/writing_email/presentation/pages/writing_email_map.dart'
    as we_map;
import 'package:voxai_quest/features/writing/writing_email/presentation/pages/writing_email_screen.dart'
    as we_game;
import 'package:voxai_quest/features/writing/correction_writing/presentation/pages/correction_writing_map.dart'
    as cw_map;
import 'package:voxai_quest/features/writing/correction_writing/presentation/pages/correction_writing_screen.dart'
    as cw_game;
import 'package:voxai_quest/features/writing/essay_drafting/presentation/pages/essay_drafting_map.dart'
    as ed_map;
import 'package:voxai_quest/features/writing/essay_drafting/presentation/pages/essay_drafting_screen.dart'
    as ed_game;

// --- GRAMMAR IMPORTS ---
import 'package:voxai_quest/features/grammar/grammar_quest/presentation/pages/grammar_quest_map.dart'
    as gq_map;
import 'package:voxai_quest/features/grammar/grammar_quest/presentation/pages/grammar_quest_screen.dart'
    as gq_game;
import 'package:voxai_quest/features/grammar/tense_mastery/presentation/pages/tense_mastery_map.dart'
    as g_tm_map;
import 'package:voxai_quest/features/grammar/tense_mastery/presentation/pages/tense_mastery_screen.dart'
    as g_tm_game;
import 'package:voxai_quest/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_map.dart'
    as g_ps_map;
import 'package:voxai_quest/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_screen.dart'
    as g_ps_game;
import 'package:voxai_quest/features/grammar/word_reorder/presentation/pages/word_reorder_map.dart'
    as g_wr_map;
import 'package:voxai_quest/features/grammar/word_reorder/presentation/pages/word_reorder_screen.dart'
    as g_wr_game;
import 'package:voxai_quest/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_map.dart'
    as g_sva_map;
import 'package:voxai_quest/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_screen.dart'
    as g_sva_game;
import 'package:voxai_quest/features/grammar/sentence_correction/presentation/pages/sentence_correction_map.dart'
    as g_sc_map;
import 'package:voxai_quest/features/grammar/sentence_correction/presentation/pages/sentence_correction_screen.dart'
    as g_sc_game;
import 'package:voxai_quest/features/grammar/article_insertion/presentation/pages/article_insertion_map.dart'
    as g_ai_map;
import 'package:voxai_quest/features/grammar/article_insertion/presentation/pages/article_insertion_screen.dart'
    as g_ai_game;
import 'package:voxai_quest/features/grammar/clause_connector/presentation/pages/clause_connector_map.dart'
    as g_cc_map;
import 'package:voxai_quest/features/grammar/clause_connector/presentation/pages/clause_connector_screen.dart'
    as g_cc_game;
import 'package:voxai_quest/features/grammar/question_formatter/presentation/pages/question_formatter_map.dart'
    as g_qf_map;
import 'package:voxai_quest/features/grammar/question_formatter/presentation/pages/question_formatter_screen.dart'
    as g_qf_game;
import 'package:voxai_quest/features/grammar/voice_swap/presentation/pages/voice_swap_map.dart'
    as g_vs_map;
import 'package:voxai_quest/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart'
    as g_vs_game;

// --- LISTENING IMPORTS ---
import 'package:voxai_quest/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_map.dart'
    as l_afb_map;
import 'package:voxai_quest/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_screen.dart'
    as l_afb_game;
import 'package:voxai_quest/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_map.dart'
    as l_amc_map;
import 'package:voxai_quest/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_screen.dart'
    as l_amc_game;
import 'package:voxai_quest/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_map.dart'
    as l_aso_map;
import 'package:voxai_quest/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_screen.dart'
    as l_aso_game;
import 'package:voxai_quest/features/listening/audio_true_false/presentation/pages/audio_true_false_map.dart'
    as l_atf_map;
import 'package:voxai_quest/features/listening/audio_true_false/presentation/pages/audio_true_false_screen.dart'
    as l_atf_game;
import 'package:voxai_quest/features/listening/sound_image_match/presentation/pages/sound_image_match_map.dart'
    as l_sim_map;
import 'package:voxai_quest/features/listening/sound_image_match/presentation/pages/sound_image_match_screen.dart'
    as l_sim_game;
import 'package:voxai_quest/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_map.dart'
    as l_fsd_map;
import 'package:voxai_quest/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_screen.dart'
    as l_fsd_game;
import 'package:voxai_quest/features/listening/emotion_recognition/presentation/pages/emotion_recognition_map.dart'
    as l_er_map;
import 'package:voxai_quest/features/listening/emotion_recognition/presentation/pages/emotion_recognition_screen.dart'
    as l_er_game;
import 'package:voxai_quest/features/listening/detail_spotlight/presentation/pages/detail_spotlight_map.dart'
    as l_ds_map;
import 'package:voxai_quest/features/listening/detail_spotlight/presentation/pages/detail_spotlight_screen.dart'
    as l_ds_game;
import 'package:voxai_quest/features/listening/listening_inference/presentation/pages/listening_inference_map.dart'
    as l_li_map;
import 'package:voxai_quest/features/listening/listening_inference/presentation/pages/listening_inference_screen.dart'
    as l_li_game;
import 'package:voxai_quest/features/listening/ambient_id/presentation/pages/ambient_id_map.dart'
    as l_ai_map;
import 'package:voxai_quest/features/listening/ambient_id/presentation/pages/ambient_id_screen.dart'
    as l_ai_game;

// --- ACCENT IMPORTS ---
import 'package:voxai_quest/features/accent/minimal_pairs/presentation/pages/minimal_pairs_map.dart'
    as a_mp_map;
import 'package:voxai_quest/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart'
    as a_mp_game;
import 'package:voxai_quest/features/accent/intonation_mimic/presentation/pages/intonation_mimic_map.dart'
    as a_im_map;
import 'package:voxai_quest/features/accent/intonation_mimic/presentation/pages/intonation_mimic_screen.dart'
    as a_im_game;
import 'package:voxai_quest/features/accent/syllable_stress/presentation/pages/syllable_stress_map.dart'
    as a_ss_map;
import 'package:voxai_quest/features/accent/syllable_stress/presentation/pages/syllable_stress_screen.dart'
    as a_ss_game;
import 'package:voxai_quest/features/accent/word_linking/presentation/pages/word_linking_map.dart'
    as a_wl_map;
import 'package:voxai_quest/features/accent/word_linking/presentation/pages/word_linking_screen.dart'
    as a_wl_game;
import 'package:voxai_quest/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_map.dart'
    as a_sc_map;
import 'package:voxai_quest/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart'
    as a_sc_game;
import 'package:voxai_quest/features/accent/vowel_distinction/presentation/pages/vowel_distinction_map.dart'
    as a_vd_map;
import 'package:voxai_quest/features/accent/vowel_distinction/presentation/pages/vowel_distinction_screen.dart'
    as a_vd_game;
import 'package:voxai_quest/features/accent/consonant_clarity/presentation/pages/consonant_clarity_map.dart'
    as a_cc_map;
import 'package:voxai_quest/features/accent/consonant_clarity/presentation/pages/consonant_clarity_screen.dart'
    as a_cc_game;
import 'package:voxai_quest/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_map.dart'
    as a_ppm_map;
import 'package:voxai_quest/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_screen.dart'
    as a_ppm_game;
import 'package:voxai_quest/features/accent/speed_variance/presentation/pages/speed_variance_map.dart'
    as a_sv_map;
import 'package:voxai_quest/features/accent/speed_variance/presentation/pages/speed_variance_screen.dart'
    as a_sv_game;
import 'package:voxai_quest/features/accent/dialect_drill/presentation/pages/dialect_drill_map.dart'
    as a_dd_map;
import 'package:voxai_quest/features/accent/dialect_drill/presentation/pages/dialect_drill_screen.dart'
    as a_dd_game;

// --- ROLEPLAY IMPORTS ---
import 'package:voxai_quest/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_map.dart'
    as r_bd_map;
import 'package:voxai_quest/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_screen.dart'
    as r_bd_game;
import 'package:voxai_quest/features/roleplay/situational_response/presentation/pages/situational_response_map.dart'
    as r_sr_map;
import 'package:voxai_quest/features/roleplay/situational_response/presentation/pages/situational_response_screen.dart'
    as r_sr_game;
import 'package:voxai_quest/features/roleplay/job_interview/presentation/pages/job_interview_map.dart'
    as r_ji_map;
import 'package:voxai_quest/features/roleplay/job_interview/presentation/pages/job_interview_screen.dart'
    as r_ji_game;
import 'package:voxai_quest/features/roleplay/medical_consult/presentation/pages/medical_consult_map.dart'
    as r_mc_map;
import 'package:voxai_quest/features/roleplay/medical_consult/presentation/pages/medical_consult_screen.dart'
    as r_mc_game;
import 'package:voxai_quest/features/roleplay/gourmet_order/presentation/pages/gourmet_order_map.dart'
    as r_go_map;
import 'package:voxai_quest/features/roleplay/gourmet_order/presentation/pages/gourmet_order_screen.dart'
    as r_go_game;
import 'package:voxai_quest/features/roleplay/travel_desk/presentation/pages/travel_desk_map.dart'
    as r_td_map;
import 'package:voxai_quest/features/roleplay/travel_desk/presentation/pages/travel_desk_screen.dart'
    as r_td_game;
import 'package:voxai_quest/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_map.dart'
    as r_cr_map;
import 'package:voxai_quest/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_screen.dart'
    as r_cr_game;
import 'package:voxai_quest/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_map.dart'
    as r_ep_map;
import 'package:voxai_quest/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_screen.dart'
    as r_ep_game;
import 'package:voxai_quest/features/roleplay/social_spark/presentation/pages/social_spark_map.dart'
    as r_sk_map;
import 'package:voxai_quest/features/roleplay/social_spark/presentation/pages/social_spark_screen.dart'
    as r_sk_game;
import 'package:voxai_quest/features/roleplay/emergency_hub/presentation/pages/emergency_hub_map.dart'
    as r_eh_map;
import 'package:voxai_quest/features/roleplay/emergency_hub/presentation/pages/emergency_hub_screen.dart'
    as r_eh_game;

// --- VOCABULARY IMPORTS ---
import 'package:voxai_quest/features/vocabulary/flashcards/presentation/pages/flashcards_map.dart'
    as v_fc_map;
import 'package:voxai_quest/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart'
    as v_fc_game;
import 'package:voxai_quest/features/vocabulary/synonym_search/presentation/pages/synonym_search_map.dart'
    as v_ss_map;
import 'package:voxai_quest/features/vocabulary/synonym_search/presentation/pages/synonym_search_screen.dart'
    as v_ss_game;
import 'package:voxai_quest/features/vocabulary/antonym_search/presentation/pages/antonym_search_map.dart'
    as v_as_map;
import 'package:voxai_quest/features/vocabulary/antonym_search/presentation/pages/antonym_search_screen.dart'
    as v_as_game;
import 'package:voxai_quest/features/vocabulary/context_clues/presentation/pages/context_clues_map.dart'
    as v_cc_map;
import 'package:voxai_quest/features/vocabulary/context_clues/presentation/pages/context_clues_screen.dart'
    as v_cc_game;
import 'package:voxai_quest/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_map.dart'
    as v_pv_map;
import 'package:voxai_quest/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_screen.dart'
    as v_pv_game;
import 'package:voxai_quest/features/vocabulary/idioms/presentation/pages/idioms_map.dart'
    as v_id_map;
import 'package:voxai_quest/features/vocabulary/idioms/presentation/pages/idioms_screen.dart'
    as v_id_game;
import 'package:voxai_quest/features/vocabulary/academic_word/presentation/pages/academic_word_map.dart'
    as v_aw_map;
import 'package:voxai_quest/features/vocabulary/academic_word/presentation/pages/academic_word_screen.dart'
    as v_aw_game;
import 'package:voxai_quest/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_map.dart'
    as v_tv_map;
import 'package:voxai_quest/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_screen.dart'
    as v_tv_game;
import 'package:voxai_quest/features/vocabulary/word_formation/presentation/pages/word_formation_map.dart'
    as v_wf_map;
import 'package:voxai_quest/features/vocabulary/word_formation/presentation/pages/word_formation_screen.dart'
    as v_wf_game;
import 'package:voxai_quest/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_map.dart'
    as v_ps_map;
import 'package:voxai_quest/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_screen.dart'
    as v_ps_game;

import 'package:voxai_quest/features/premium/presentation/pages/premium_screen.dart';
import 'package:voxai_quest/features/profile/presentation/pages/profile_screen.dart';
import 'package:voxai_quest/features/settings/presentation/pages/settings_screen.dart';
import 'package:voxai_quest/features/leaderboard/presentation/pages/leaderboard_screen.dart';
import 'package:voxai_quest/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:voxai_quest/features/settings/presentation/pages/admin_dashboard.dart';
import 'package:voxai_quest/features/profile/presentation/pages/adventure_level_screen.dart';
import 'package:voxai_quest/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:voxai_quest/features/profile/presentation/pages/quest_coins_screen.dart';
import 'package:voxai_quest/core/presentation/pages/quest_sequence_page.dart';
import 'package:voxai_quest/features/splash/presentation/pages/splash_page.dart';
import 'dart:async';
import 'package:voxai_quest/core/presentation/widgets/auth_gate.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/games/placeholder_game_map.dart';
import 'package:voxai_quest/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:voxai_quest/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:voxai_quest/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:voxai_quest/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:voxai_quest/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:voxai_quest/features/vocabulary/presentation/bloc/vocabulary_bloc.dart'
    as v_bloc;
import 'package:voxai_quest/features/kids_zone/presentation/pages/sticker_book_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/mascot_selection_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/kids_zone_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/kids_level_map.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/alphabet_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/numbers_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/colors_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/shapes_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/animals_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/fruits_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/family_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/school_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/verbs_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/routine_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/emotions_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/prepositions_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/phonics_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/time_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/opposites_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/day_night_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/nature_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/home_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/food_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/games/transport_game_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/buddy_boutique_screen.dart';
import 'package:voxai_quest/features/kids_zone/presentation/pages/admin/kids_admin_screen.dart';
import 'package:voxai_quest/core/utils/discovery_helper.dart';

class AppRouter {
  static const String initialRoute = '/splash';
  static const String splashRoute = '/splash';
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String gameRoute = '/game';
  static const String premiumRoute = '/premium';
  static const String profileRoute = '/profile';
  static const String adminRoute = '/admin';
  static const String settingsRoute = '/settings';
  static const String leaderboardRoute = '/leaderboard';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String verifyEmailRoute = '/verify-email';
  static const String levelsRoute = '/levels';
  static const String categoryGamesRoute = '/category-games';
  static const String libraryRoute = '/library';
  static const String streakRoute = '/streak';
  static const String levelRoute = '/level-details';
  static const String adventureXPRoute = '/xp-details';
  static const String questCoinsRoute = '/coins-details';
  static const String questSequenceRoute = '/quest-sequence';
  static const String voxinMascotRoute = '/voxin-mascot';
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
  static const String kidsWritingRoute = '/kids-writing';
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
  static const String kidsBuddyBoutiqueRoute = '/kids-zone/boutique';
  static const String kidsAdminRoute = '/kids-admin';

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
      default:
        return Colors.blue;
    }
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

      if (isSplashRoute) {
        return null;
      }

      final isAuthRoute =
          isLoginRoute || isSignupRoute || isForgotPasswordRoute;

      if (!isAuthenticated) {
        if (!isAuthRoute) {
          return loginRoute;
        }
      } else {
        if (isAuthRoute) {
          return isVerified ? homeRoute : verifyEmailRoute;
        }
        if (!isVerified) {
          if (state.uri.path != verifyEmailRoute) {
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: settingsRoute,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: voxinMascotRoute,
        builder: (context, state) => const VoxinMascotScreen(),
      ),

      GoRoute(
        path: kidsZoneRoute,
        builder: (context, state) => const KidsZoneScreen(),
        routes: [
          GoRoute(
            path: 'boutique',
            name: 'kids-boutique',
            builder: (context, state) => const BuddyBoutiqueScreen(),
          ),
        ],
      ),
      GoRoute(
        path: kidsStickerBookRoute,
        builder: (context, state) => const StickerBookScreen(),
      ),
      GoRoute(
        path: kidsMascotSelectionRoute,
        builder: (context, state) => const MascotSelectionScreen(),
      ),
      GoRoute(
        path: kidsLevelMapRoute,
        builder: (context, state) {
          final gameType = state.pathParameters['gameType'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;

          return KidsLevelMap(
            gameType: gameType.isEmpty
                ? (extra?['gameType'] as String? ?? 'alphabet')
                : gameType,
            title: extra?['title'] as String? ?? getKidsGameTitle(gameType),
            primaryColor:
                extra?['primaryColor'] as Color? ?? getKidsGameColor(gameType),
          );
        },
      ),
      GoRoute(
        path: kidsAlphabetRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: AlphabetGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsNumbersRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: NumbersGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsColorsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: ColorsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsShapesRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: ShapesGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsAnimalsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: AnimalsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsFruitsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: FruitsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsFamilyRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: FamilyGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsSchoolRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: SchoolGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsVerbsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: VerbsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsRoutineRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: RoutineGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsEmotionsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: EmotionsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsPrepositionsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: PrepositionsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsPhonicsRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: PhonicsGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsTimeRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: TimeGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsOppositesRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: OppositesGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsDayNightRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: DayNightGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsNatureRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: NatureGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsHomeRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: HomeGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsFoodRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: FoodGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsTransportRoute,
        builder: (context, state) => BlocProvider(
          create: (context) => di.sl<KidsBloc>(),
          child: TransportGameScreen(level: state.extra as int? ?? 1),
        ),
      ),
      GoRoute(
        path: kidsAdminRoute,
        builder: (context, state) => const KidsAdminScreen(),
      ),

      GoRoute(
        path: '/game',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? 'reading';
          final level =
              int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
          final gameTypeStr =
              state.uri.queryParameters['gameType'] ??
              state.uri.queryParameters['subtype'];

          switch (category) {
            case 'reading':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.readAndAnswer,
                    )
                  : GameSubtype.readAndAnswer;
              return _getReadingScreen(gameType, level);
            case 'writing':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.sentenceBuilder,
                    )
                  : GameSubtype.sentenceBuilder;
              return _getWritingScreen(gameType, level);
            case 'speaking':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.repeatSentence,
                    )
                  : GameSubtype.repeatSentence;
              return _getSpeakingScreen(gameType, level);
            case 'grammar':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.grammarQuest,
                    )
                  : GameSubtype.grammarQuest;
              return _getGrammarScreen(gameType, level);
            case 'roleplay':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.branchingDialogue,
                    )
                  : GameSubtype.branchingDialogue;
              return _getRoleplayScreen(gameType, level);
            case 'accent':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.minimalPairs,
                    )
                  : GameSubtype.minimalPairs;
              return _getAccentScreen(gameType, level);
            case 'listening':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.audioMultipleChoice,
                    )
                  : GameSubtype.audioMultipleChoice;
              return _getListeningScreen(gameType, level);
            case 'vocabulary':
              final gameType = gameTypeStr != null
                  ? GameSubtype.values.firstWhere(
                      (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                      orElse: () => GameSubtype.flashcards,
                    )
                  : GameSubtype.flashcards;
              return _getVocabularyScreen(gameType, level);
            default:
              return _getReadingScreen(GameSubtype.readAndAnswer, level);
          }
        },
      ),

      GoRoute(
        path: '/levels',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['category'] ?? 'reading';
          final gameType = state.uri.queryParameters['gameType'];

          switch (categoryId) {
            case 'reading':
              if (gameType == 'readAndAnswer') {
                return const ra_map.ReadAndAnswerMap();
              }
              if (gameType == 'findWordMeaning') {
                return const fwm_map.FindWordMeaningMap();
              }
              if (gameType == 'trueFalseReading') {
                return const tfr_map.TrueFalseReadingMap();
              }
              if (gameType == 'sentenceOrderReading') {
                return const so_map.SentenceOrderReadingMap();
              }
              if (gameType == 'readingSpeedCheck') {
                return const rsc_map.ReadingSpeedCheckMap();
              }
              if (gameType == 'guessTitle') {
                return const gt_map.GuessTitleMap();
              }
              if (gameType == 'readAndMatch') {
                return const ram_map.ReadAndMatchMap();
              }
              if (gameType == 'paragraphSummary') {
                return const ps_map.ParagraphSummaryMap();
              }
              if (gameType == 'readingInference') {
                return const ri_map.ReadingInferenceMap();
              }
              if (gameType == 'readingConclusion') {
                return const rcm_map.ReadingConclusionMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'readingSelection',
                categoryId: categoryId,
              );
            case 'vocabulary':
              if (gameType == 'flashcards') {
                return const v_fc_map.FlashcardsMap();
              }
              if (gameType == 'synonymSearch') {
                return const v_ss_map.SynonymSearchMap();
              }
              if (gameType == 'antonymSearch') {
                return const v_as_map.AntonymSearchMap();
              }
              if (gameType == 'contextClues') {
                return const v_cc_map.ContextCluesMap();
              }
              if (gameType == 'phrasalVerbs') {
                return const v_pv_map.PhrasalVerbsMap();
              }
              if (gameType == 'idioms') {
                return const v_id_map.IdiomsMap();
              }
              if (gameType == 'academicWord') {
                return const v_aw_map.AcademicWordMap();
              }
              if (gameType == 'topicVocab') {
                return const v_tv_map.TopicVocabMap();
              }
              if (gameType == 'wordFormation') {
                return const v_wf_map.WordFormationMap();
              }
              if (gameType == 'prefixSuffix') {
                return const v_ps_map.PrefixSuffixMap();
              }

              return PlaceholderGameMap(
                gameType: gameType ?? 'vocabularyMastery',
                categoryId: categoryId,
              );
            case 'writing':
              if (gameType == 'sentenceBuilder') {
                return const sb_map.SentenceBuilderMap();
              }
              if (gameType == 'completeSentence') {
                return const cs_map.CompleteSentenceMap();
              }
              if (gameType == 'fixTheSentence') {
                return const fts_map.FixTheSentenceMap();
              }
              if (gameType == 'describeSituationWriting') {
                return const ds_map.DescribeSituationWritingMap();
              }
              if (gameType == 'shortAnswerWriting') {
                return const sa_map.ShortAnswerWritingMap();
              }
              if (gameType == 'opinionWriting') {
                return const ow_map.OpinionWritingMap();
              }
              if (gameType == 'dailyJournal') {
                return const dj_map.DailyJournalMap();
              }
              if (gameType == 'summarizeStoryWriting') {
                return const ssw_map.SummarizeStoryWritingMap();
              }
              if (gameType == 'correctionWriting') {
                return const cw_map.CorrectionWritingMap();
              }
              if (gameType == 'writingEmail') {
                return const we_map.WritingEmailMap();
              }
              if (gameType == 'essayDrafting') {
                return const ed_map.EssayDraftingMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'writingProject',
                categoryId: categoryId,
              );
            case 'speaking':
              if (gameType == 'repeatSentence') {
                return const rs_map.RepeatSentenceMap();
              }
              if (gameType == 'speakMissingWord') {
                return const smw_map.SpeakMissingWordMap();
              }
              if (gameType == 'situationSpeaking') {
                return const ss_map.SituationSpeakingMap();
              }
              if (gameType == 'sceneDescriptionSpeaking') {
                return const sd_map.SceneDescriptionSpeakingMap();
              }
              if (gameType == 'yesNoSpeaking') {
                return const yn_map.YesNoSpeakingMap();
              }
              if (gameType == 'speakSynonym') {
                return const ssyn_map.SpeakSynonymMap();
              }
              if (gameType == 'dialogueRoleplay') {
                return const dr_map.DialogueRoleplayMap();
              }
              if (gameType == 'pronunciationFocus') {
                return const pf_map.PronunciationFocusMap();
              }
              if (gameType == 'speakOpposite') {
                return const sp_opp_map.SpeakOppositeMap();
              }
              if (gameType == 'dailyExpression') {
                return const de_map.DailyExpressionMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'speakingChallenge',
                categoryId: categoryId,
              );
            case 'listening':
              if (gameType == 'audioFillBlanks') {
                return const l_afb_map.AudioFillBlanksMap();
              }
              if (gameType == 'audioMultipleChoice') {
                return const l_amc_map.AudioMultipleChoiceMap();
              }
              if (gameType == 'audioSentenceOrder') {
                return const l_aso_map.AudioSentenceOrderMap();
              }
              if (gameType == 'audioTrueFalse') {
                return const l_atf_map.AudioTrueFalseMap();
              }
              if (gameType == 'soundImageMatch') {
                return const l_sim_map.SoundImageMatchMap();
              }
              if (gameType == 'fastSpeechDecoder') {
                return const l_fsd_map.FastSpeechDecoderMap();
              }
              if (gameType == 'emotionRecognition') {
                return const l_er_map.EmotionRecognitionMap();
              }
              if (gameType == 'detailSpotlight') {
                return const l_ds_map.DetailSpotlightMap();
              }
              if (gameType == 'listeningInference') {
                return const l_li_map.ListeningInferenceMap();
              }
              if (gameType == 'ambientId') {
                return const l_ai_map.AmbientIdMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'listeningMastery',
                categoryId: categoryId,
              );
            case 'accent':
              if (gameType == 'minimalPairs') {
                return const a_mp_map.MinimalPairsMap();
              }
              if (gameType == 'intonationMimic') {
                return const a_im_map.IntonationMimicMap();
              }
              if (gameType == 'syllableStress') {
                return const a_ss_map.SyllableStressMap();
              }
              if (gameType == 'wordLinking') {
                return const a_wl_map.WordLinkingMap();
              }
              if (gameType == 'shadowingChallenge') {
                return const a_sc_map.ShadowingChallengeMap();
              }
              if (gameType == 'vowelDistinction') {
                return const a_vd_map.VowelDistinctionMap();
              }
              if (gameType == 'consonantClarity') {
                return const a_cc_map.ConsonantClarityMap();
              }
              if (gameType == 'pitchPatternMatch') {
                return const a_ppm_map.PitchPatternMatchMap();
              }
              if (gameType == 'speedVariance') {
                return const a_sv_map.SpeedVarianceMap();
              }
              if (gameType == 'dialectDrill') {
                return const a_dd_map.DialectDrillMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'accentDrill',
                categoryId: categoryId,
              );
            case 'roleplay':
              if (gameType == 'branchingDialogue') {
                return const r_bd_map.BranchingDialogueMap();
              }
              if (gameType == 'situationalResponse') {
                return const r_sr_map.SituationalResponseMap();
              }
              if (gameType == 'jobInterview') {
                return const r_ji_map.JobInterviewMap();
              }
              if (gameType == 'medicalConsult') {
                return const r_mc_map.MedicalConsultMap();
              }
              if (gameType == 'gourmetOrder') {
                return const r_go_map.GourmetOrderMap();
              }
              if (gameType == 'travelDesk') {
                return const r_td_map.TravelDeskMap();
              }
              if (gameType == 'conflictResolver') {
                return const r_cr_map.ConflictResolverMap();
              }
              if (gameType == 'elevatorPitch') {
                return const r_ep_map.ElevatorPitchMap();
              }
              if (gameType == 'socialSpark') {
                return const r_sk_map.SocialSparkMap();
              }
              if (gameType == 'emergencyHub') {
                return const r_eh_map.EmergencyHubMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'roleplayScenario',
                categoryId: categoryId,
              );
            case 'grammar':
              if (gameType == 'grammarQuest') {
                return const gq_map.GrammarQuestMap();
              }
              if (gameType == 'tenseMastery') {
                return const g_tm_map.TenseMasteryMap();
              }
              if (gameType == 'partsOfSpeech') {
                return const g_ps_map.PartsOfSpeechMap();
              }
              if (gameType == 'wordReorder') {
                return const g_wr_map.WordReorderMap();
              }
              if (gameType == 'subjectVerbAgreement') {
                return const g_sva_map.SubjectVerbAgreementMap();
              }
              if (gameType == 'sentenceCorrection') {
                return const g_sc_map.SentenceCorrectionMap();
              }
              if (gameType == 'articleInsertion') {
                return const g_ai_map.ArticleInsertionMap();
              }
              if (gameType == 'clauseConnector') {
                return const g_cc_map.ClauseConnectorMap();
              }
              if (gameType == 'questionFormatter') {
                return const g_qf_map.QuestionFormatterMap();
              }
              if (gameType == 'voiceSwap') {
                return const g_vs_map.VoiceSwapMap();
              }
              return PlaceholderGameMap(
                gameType: gameType ?? 'grammarQuest',
                categoryId: categoryId,
              );
            default:
              return CategoryGamesPage(categoryId: categoryId);
          }
        },
      ),
      GoRoute(
        path: categoryGamesRoute,
        builder: (context, state) => CategoryGamesPage(
          categoryId: state.uri.queryParameters['category'] ?? 'speaking',
        ),
      ),
      GoRoute(
        path: libraryRoute,
        builder: (context, state) => const QuestLibraryPage(),
      ),
      GoRoute(
        path: premiumRoute,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: streakRoute,
        builder: (context, state) => const StreakScreen(),
      ),
      GoRoute(
        path: adminRoute,
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: levelRoute,
        builder: (context, state) => const AdventureLevelScreen(),
      ),
      GoRoute(
        path: adventureXPRoute,
        builder: (context, state) => const AdventureXPScreen(),
      ),
      GoRoute(
        path: questCoinsRoute,
        builder: (context, state) => const VoxCoinsScreen(),
      ),
      GoRoute(
        path: questSequenceRoute,
        builder: (context, state) {
          final sequenceId = state.uri.queryParameters['id'] ?? 'daily_duo';
          final user = di.sl<AuthBloc>().state.user;
          final quests = user != null
              ? DiscoveryHelper.getQuestsForSequence(sequenceId, user)
              : _getQuestsForSequence(sequenceId);
          return QuestSequencePage(sequenceId: sequenceId, quests: quests);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    ),
  );

  static Widget _getSpeakingScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<SpeakingBloc>(),
      child: _getSpeakingScreenContent(gameType, level),
    );
  }

  static Widget _getSpeakingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.repeatSentence:
        return rs_game.RepeatSentenceScreen(level: level);
      case GameSubtype.speakMissingWord:
        return smw_game.SpeakMissingWordScreen(level: level);
      case GameSubtype.situationSpeaking:
        return ss_game.SituationSpeakingScreen(level: level);
      case GameSubtype.sceneDescriptionSpeaking:
        return sd_game.SceneDescriptionScreen(level: level);
      case GameSubtype.yesNoSpeaking:
        return yn_game.YesNoSpeakingScreen(level: level);
      case GameSubtype.speakSynonym:
        return ssyn_game.SpeakSynonymScreen(level: level);
      case GameSubtype.dialogueRoleplay:
        return dr_game.DialogueRoleplayScreen(level: level);
      case GameSubtype.pronunciationFocus:
        return pf_game.PronunciationFocusScreen(level: level);
      case GameSubtype.speakOpposite:
        return sp_opp_game.SpeakOppositeScreen(level: level);
      case GameSubtype.dailyExpression:
        return de_game.DailyExpressionScreen(level: level);
      default:
        return rs_game.RepeatSentenceScreen(level: level);
    }
  }

  static Widget _getReadingScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<ReadingBloc>(),
      child: _getReadingScreenContent(gameType, level),
    );
  }

  static Widget _getReadingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.readAndAnswer:
        return ra_game.ReadAndAnswerScreen(level: level);
      case GameSubtype.findWordMeaning:
        return fwm_game.FindWordMeaningScreen(level: level);
      case GameSubtype.trueFalseReading:
        return tfr_game.TrueFalseReadingScreen(level: level);
      case GameSubtype.sentenceOrderReading:
        return so_game.SentenceOrderScreen(level: level);
      case GameSubtype.readingSpeedCheck:
        return rsc_game.ReadingSpeedScreen(level: level);
      case GameSubtype.guessTitle:
        return gt_game.GuessTitleScreen(level: level);
      case GameSubtype.readAndMatch:
        return ram_game.ReadAndMatchScreen(level: level);
      case GameSubtype.paragraphSummary:
        return ps_game.ParagraphSummaryScreen(level: level);
      case GameSubtype.readingInference:
        return ri_game.ReadingInferenceScreen(level: level);
      case GameSubtype.readingConclusion:
        return rcm_game.ReadingConclusionScreen(level: level);
      default:
        return ra_game.ReadAndAnswerScreen(level: level);
    }
  }

  static Widget _getWritingScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<WritingBloc>(),
      child: _getWritingScreenContent(gameType, level),
    );
  }

  static Widget _getWritingScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.sentenceBuilder:
        return sb_game.SentenceBuilderScreen(level: level);
      case GameSubtype.completeSentence:
        return cs_game.CompleteSentenceScreen(level: level);
      case GameSubtype.describeSituationWriting:
        return ds_game.DescribeSituationScreen(level: level);
      case GameSubtype.fixTheSentence:
        return fts_game.FixTheSentenceScreen(level: level);
      case GameSubtype.shortAnswerWriting:
        return sa_game.ShortAnswerScreen(level: level);
      case GameSubtype.opinionWriting:
        return ow_game.OpinionWritingScreen(level: level);
      case GameSubtype.dailyJournal:
        return dj_game.DailyJournalScreen(level: level);
      case GameSubtype.summarizeStoryWriting:
        return ssw_game.SummarizeStoryWritingScreen(level: level);
      case GameSubtype.correctionWriting:
        return cw_game.CorrectionWritingScreen(level: level);
      case GameSubtype.writingEmail:
        return we_game.WritingEmailScreen(level: level);
      case GameSubtype.essayDrafting:
        return ed_game.EssayDraftingScreen(level: level);
      default:
        return sb_game.SentenceBuilderScreen(level: level);
    }
  }

  static Widget _getGrammarScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<GrammarBloc>(),
      child: _getGrammarScreenContent(gameType, level),
    );
  }

  static Widget _getGrammarScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.grammarQuest:
        return gq_game.GrammarQuestScreen(level: level);
      case GameSubtype.sentenceCorrection:
        return g_sc_game.SentenceCorrectionScreen(level: level);
      case GameSubtype.wordReorder:
        return g_wr_game.WordReorderScreen(level: level);
      case GameSubtype.tenseMastery:
        return g_tm_game.TenseMasteryScreen(level: level);
      case GameSubtype.partsOfSpeech:
        return g_ps_game.PartsOfSpeechScreen(level: level);
      case GameSubtype.subjectVerbAgreement:
        return g_sva_game.SubjectVerbAgreementScreen(level: level);
      case GameSubtype.articleInsertion:
        return g_ai_game.ArticleInsertionScreen(level: level);
      case GameSubtype.clauseConnector:
        return g_cc_game.ClauseConnectorScreen(level: level);
      case GameSubtype.questionFormatter:
        return g_qf_game.QuestionFormatterScreen(level: level);
      case GameSubtype.voiceSwap:
        return g_vs_game.VoiceSwapScreen(level: level);
      default:
        return gq_game.GrammarQuestScreen(level: level);
    }
  }

  static Widget _getListeningScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<ListeningBloc>(),
      child: _getListeningScreenContent(gameType, level),
    );
  }

  static Widget _getListeningScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.audioFillBlanks:
        return l_afb_game.AudioFillBlanksScreen(level: level);
      case GameSubtype.audioMultipleChoice:
        return l_amc_game.AudioMultipleChoiceScreen(level: level);
      case GameSubtype.audioSentenceOrder:
        return l_aso_game.AudioSentenceOrderScreen(level: level);
      case GameSubtype.audioTrueFalse:
        return l_atf_game.AudioTrueFalseScreen(level: level);
      case GameSubtype.soundImageMatch:
        return l_sim_game.SoundImageMatchScreen(level: level);
      case GameSubtype.fastSpeechDecoder:
        return l_fsd_game.FastSpeechDecoderScreen(level: level);
      case GameSubtype.emotionRecognition:
        return l_er_game.EmotionRecognitionScreen(level: level);
      case GameSubtype.detailSpotlight:
        return l_ds_game.DetailSpotlightScreen(level: level);
      case GameSubtype.listeningInference:
        return l_li_game.ListeningInferenceScreen(level: level);
      case GameSubtype.ambientId:
        return l_ai_game.AmbientIdScreen(level: level);
      default:
        return l_afb_game.AudioFillBlanksScreen(level: level);
    }
  }

  static Widget _getAccentScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<AccentBloc>(),
      child: _getAccentScreenContent(gameType, level),
    );
  }

  static Widget _getAccentScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.minimalPairs:
        return a_mp_game.MinimalPairsScreen(level: level);
      case GameSubtype.intonationMimic:
        return a_im_game.IntonationMimicScreen(level: level);
      case GameSubtype.syllableStress:
        return a_ss_game.SyllableStressScreen(level: level);
      case GameSubtype.wordLinking:
        return a_wl_game.WordLinkingScreen(level: level);
      case GameSubtype.shadowingChallenge:
        return a_sc_game.ShadowingChallengeScreen(level: level);
      case GameSubtype.vowelDistinction:
        return a_vd_game.VowelDistinctionScreen(level: level);
      case GameSubtype.consonantClarity:
        return a_cc_game.ConsonantClarityScreen(level: level);
      case GameSubtype.pitchPatternMatch:
        return a_ppm_game.PitchPatternMatchScreen(level: level);
      case GameSubtype.speedVariance:
        return a_sv_game.SpeedVarianceScreen(level: level);
      case GameSubtype.dialectDrill:
        return a_dd_game.DialectDrillScreen(level: level);
      default:
        return a_mp_game.MinimalPairsScreen(level: level);
    }
  }

  static Widget _getRoleplayScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<RoleplayBloc>(),
      child: _getRoleplayScreenContent(gameType, level),
    );
  }

  static Widget _getRoleplayScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.branchingDialogue:
        return r_bd_game.BranchingDialogueScreen(level: level);
      case GameSubtype.situationalResponse:
        return r_sr_game.SituationalResponseScreen(level: level);
      case GameSubtype.jobInterview:
        return r_ji_game.JobInterviewScreen(level: level);
      case GameSubtype.medicalConsult:
        return r_mc_game.MedicalConsultScreen(level: level);
      case GameSubtype.gourmetOrder:
        return r_go_game.GourmetOrderScreen(level: level);
      case GameSubtype.travelDesk:
        return r_td_game.TravelDeskScreen(level: level);
      case GameSubtype.conflictResolver:
        return r_cr_game.ConflictResolverScreen(level: level);
      case GameSubtype.elevatorPitch:
        return r_ep_game.ElevatorPitchScreen(level: level);
      case GameSubtype.socialSpark:
        return r_sk_game.SocialSparkScreen(level: level);
      case GameSubtype.emergencyHub:
        return r_eh_game.EmergencyHubScreen(level: level);
      default:
        return r_bd_game.BranchingDialogueScreen(level: level);
    }
  }

  static Widget _getVocabularyScreen(GameSubtype gameType, int level) {
    return BlocProvider(
      create: (context) => di.sl<v_bloc.VocabularyBloc>(),
      child: _getVocabularyScreenContent(gameType, level),
    );
  }

  static Widget _getVocabularyScreenContent(GameSubtype gameType, int level) {
    switch (gameType) {
      case GameSubtype.flashcards:
        return v_fc_game.FlashcardsScreen(level: level);
      case GameSubtype.synonymSearch:
        return v_ss_game.SynonymSearchScreen(level: level);
      case GameSubtype.antonymSearch:
        return v_as_game.AntonymSearchScreen(level: level);
      case GameSubtype.contextClues:
        return v_cc_game.ContextCluesScreen(level: level);
      case GameSubtype.idioms:
        return v_id_game.IdiomsScreen(level: level);
      case GameSubtype.phrasalVerbs:
        return v_pv_game.PhrasalVerbsScreen(level: level);
      case GameSubtype.academicWord:
        return v_aw_game.AcademicWordScreen(level: level);
      case GameSubtype.topicVocab:
        return v_tv_game.TopicVocabScreen(level: level);
      case GameSubtype.wordFormation:
        return v_wf_game.WordFormationScreen(level: level);
      case GameSubtype.prefixSuffix:
        return v_ps_game.PrefixSuffixScreen(level: level);
      default:
        return v_fc_game.FlashcardsScreen(level: level);
    }
  }

  static List<GameQuest> _getQuestsForSequence(String sequenceId) {
    return [
      const GameQuest(
        id: 'default_1',
        type: QuestType.speaking,
        subtype: GameSubtype.repeatSentence,
        instruction: 'Warm up with a quick repeat.',
        difficulty: 1,
      ),
    ];
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

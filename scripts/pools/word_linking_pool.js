// Word Linking: 600 unique phrases for connected speech practice
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  // Linking categories with combinatorial generation
  
  // Category 1: Consonant-to-vowel linking (C→V)
  const cv_phrases = [
    'pick_it_up','put_it_on','turn_it_off','take_it_out','let_it_go','get_it_done',
    'make_it_up','give_it_away','work_it_out','find_it_easy','keep_it_up','hold_it_in',
    'cut_it_open','set_it_down','mix_it_all','run_it_again','read_it_aloud','send_it_over',
    'bring_it_along','push_it_aside','call_it_off','pass_it_around','hand_it_over','check_it_out',
    'figure_it_out','sort_it_out','think_it_over','talk_it_over','write_it_up','look_it_up',
    'fill_it_in','cross_it_out','mark_it_up','clean_it_up','wash_it_off','wipe_it_away',
    'throw_it_out','pull_it_off','snap_it_on','plug_it_in','switch_it_on','lock_it_up',
    'open_it_up','close_it_off','shut_it_out','block_it_off','seal_it_up','wrap_it_up',
    'tie_it_up','hang_it_up','line_it_up','stack_it_up','build_it_up','break_it_apart',
    'tear_it_open','pack_it_away','fold_it_over','spread_it_out','lay_it_out','roll_it_up',
    'chop_it_up','slice_it_open','pour_it_out','stir_it_all','heat_it_up','cool_it_down',
    'warm_it_up','boil_it_over','fry_it_up','bake_it_all','toast_it_up','grill_it_all',
    'dress_it_up','fix_it_up','paint_it_on','sand_it_down','glue_it_on','tape_it_up',
    'pin_it_on','clip_it_on','hook_it_up','bolt_it_on','screw_it_in','nail_it_in',
    'load_it_up','drop_it_off','ship_it_out','store_it_away','file_it_away','save_it_up',
    'use_it_up','eat_it_all','drink_it_up','finish_it_all','test_it_out','try_it_on',
    'map_it_out','sketch_it_out','draft_it_up','plan_it_out','scope_it_out','price_it_up',
    'size_it_up','weigh_it_up','count_it_up','add_it_up','split_it_up','share_it_out',
    'deal_it_out','hand_it_in','turn_it_in','log_it_in','sign_it_in','clock_it_in',
    'ring_it_up','cash_it_in','trade_it_in','swap_it_out','change_it_up','flip_it_over',
  ];
  
  // Category 2: Vowel-to-vowel linking with /j/ or /w/ glide
  const vv_phrases = [
    'I_agree_entirely','she_always_eats','he_also_asked','we_often_argue','they_only_eat',
    'go_ahead_and_ask','I_am_aware','she_is_able','the_idea_is','to_a_extent',
    'say_anything','no_answer_yet','so_obvious','also_important','too_eager',
    'do_everything','two_apples','who_else_agrees','blue_ocean_view','new_apartment',
    'free_entry_always','three_other_options','see_anything_else','be_honest_always','we_are_here',
    'my_own_opinion','fly_away_soon','sky_above_us','why_always_argue','try_another_one',
    'how_about_eight','now_or_ever','allow_entry','wow_amazing','cow_and_horse',
    'the_end_arrived','a_interesting_idea','an_awful_error','the_answer_is','a_unusual_event',
    'may_I_enter','play_each_one','stay_up_all','pray_every_evening','say_it_again',
    'flow_into_each','grow_a_garden','throw_it_away','show_everyone','know_anything',
    'review_every_one','argue_about_it','continue_asking','value_everything','rescue_anyone',
    'pursue_every_lead','issue_another_one','tissue_or_napkin','statue_of_liberty','venue_and_event',
    'piano_and_violin','radio_announcer','video_everywhere','studio_apartment','patio_area',
    'to_each_and_all','go_out_and_explore','do_it_again_now','who_among_us','too_often_ignored',
    'co_operate_always','re_enter_again','pre_arrange_early','de_escalate_now','re_organize_it',
    'auto_update_soon','bio_engineer','geo_analysis','neo_classical','pseudo_academic',
    'free_agent','sea_air','tea_and_cakes','pea_and_carrot','bee_and_flower',
    'key_area','tree_aisle','three_eagles','knee_ache','ski_area',
    'free_and_easy','sea_eagle','tea_each_day','tree_above_us','bee_approaching',
    'He_opened_it','she_asked_again','we_answered','the_event','be_aware',
    'no_one_else','go_onto_it','so_amazingly','do_a_favor','to_a_friend',
    'I_owe_everyone','they_ought_to','we_own_everything','I_only_ask','she_overreacts',
    'blue_and_green','true_or_false','clue_about_it','glue_and_tape','due_at_eight',
    'new_and_old','few_are_left','knew_about_it','threw_it_away','drew_a_picture',
    'how_old_is','now_and_then','allow_others','bow_and_arrow','vow_of_silence',
    'my_uncle','fly_over','try_again','dry_air','sky_overhead',
    'boy_and_girl','toy_airplane','joy_of_living','ploy_or_trick','annoy_everyone',
    'day_after_day','way_out_east','say_anything','may_I_ask','pay_attention',
    'now_I_agree','how_about_us','wow_incredible','plow_ahead','brow_area',
  ];
  
  // Category 3: Assimilation patterns
  const assim_phrases = [
    'ten_boys','ten_men','ten_keys','in_bed','in_port','in_class',
    'green_bag','brown_paper','one_more','don\'t_know','want_to','got_to',
    'used_to','have_to','going_to','need_to','ought_to','has_to',
    'did_you','would_you','could_you','should_you','had_you','can_you',
    'miss_you','bless_you','dress_you','press_you','stress_you','address_you',
    'this_year','last_year','next_year','that_year','first_year','half_year',
    'won\'t_you','don\'t_you','can\'t_you','aren\'t_you','isn\'t_it','wasn\'t_it',
    'meet_you','greet_you','heat_you','seat_you','beat_you','treat_you',
    'what_you','that_you','let_you','get_you','hit_you','bit_you',
    'right_place','might_be','light_brown','night_bird','height_mark','fight_back',
    'not_possible','hot_plate','got_back','lot_bigger','spot_check','shot_put',
    'bread_basket','good_bye','bad_dream','odd_pair','sad_part','glad_tidings',
    'wide_path','ride_back','made_breakfast','side_panel','code_base','trade_balance',
    'big_chance','drug_company','bag_carrier','egg_cup','leg_cramp','rug_cleaner',
    'like_crazy','take_care','make_coffee','speak_clearly','break_contact','check_carefully',
    'love_baseball','five_brothers','have_been','give_back','live_broadcast','drive_badly',
    'half_price','chief_butler','safe_bet','life_blood','knife_blade','wife_beater',
    'breath_catch','health_benefit','growth_business','both_brothers','earth_bound','month_before',
    'raise_both','cheese_board','these_books','those_boys','whose_business','prize_bronze',
    'judge_both','large_bottle','bridge_building','edge_band','age_bracket','stage_background',
  ];
  
  // Category 4: Elision patterns (dropped sounds)
  const elision_phrases = [
    'next_door','first_time','last_night','best_man','most_people','just_now',
    'must_be','fast_food','post_box','rest_room','lost_cause','cost_cutting',
    'fact_finding','strict_rules','direct_route','perfect_pitch','object_lesson','subject_matter',
    'hand_bag','sand_castle','land_lord','band_practice','stand_point','grand_father',
    'old_man','cold_night','hold_back','gold_mine','bold_move','told_me',
    'mind_map','find_me','kind_of','blind_spot','behind_you','remind_me',
    'round_table','ground_floor','sound_proof','found_out','bound_for','around_here',
    'send_back','friend_ship','spend_money','lend_him','tend_to','end_up',
    'kept_quiet','slept_well','crept_along','wept_openly','swept_away','stepped_out',
    'helped_him','jumped_over','bumped_into','pumped_up','dumped_down','camped_outside',
    'looked_back','cooked_dinner','booked_tickets','hooked_onto','crooked_path','shook_hands',
    'robbed_them','grabbed_hold','stabbed_twice','rubbed_against','scrubbed_clean','throbbed_loudly',
    'laughed_about','coughed_badly','stuffed_full','puffed_away','bluffed_them','roughed_up',
    'wished_upon','pushed_through','washed_away','rushed_past','brushed_aside','polished_up',
    'changed_plans','managed_well','damaged_goods','engaged_fully','arranged_nicely','encouraged_them',
    'watched_over','matched_pairs','touched_gently','reached_out','attached_file','approached_slowly',
    'closed_down','raised_doubts','praised_highly','composed_music','proposed_changes','supposed_to',
    'loved_dearly','moved_swiftly','proved_wrong','improved_greatly','approved_plan','removed_quickly',
    'amazed_everyone','organized_well','realized_quickly','recognized_them','emphasized_strongly','harmonized_perfectly',
    'promised_faithfully','practiced_daily','noticed_immediately','balanced_carefully','influenced_deeply','experienced_firsthand',
  ];

  // Build pool
  for (const phrase of cv_phrases) {
    pool.push({
      instruction: 'Practice consonant-to-vowel linking.',
      interactionType: 'speaking',
      fields: { word: phrase.replace(/_/g, ' '), options: ['Linked','Separated'], correctAnswerIndex: 0, hint: 'Connect final consonant to next vowel smoothly.', phoneticHint: getIpa(phrase.replace(/_/g, ' ')) }
    });
  }
  for (const phrase of vv_phrases) {
    pool.push({
      instruction: 'Practice vowel-to-vowel linking.',
      interactionType: 'speaking',
      fields: { word: phrase.replace(/_/g, ' '), options: ['Linked','Separated'], correctAnswerIndex: 0, hint: 'Add a glide /j/ or /w/ between vowels.', phoneticHint: getIpa(phrase.replace(/_/g, ' ')) }
    });
  }
  for (const phrase of assim_phrases) {
    pool.push({
      instruction: 'Practice sound assimilation.',
      interactionType: 'speaking',
      fields: { word: phrase.replace(/_/g, ' '), options: ['Assimilated','Separate'], correctAnswerIndex: 0, hint: 'Sounds merge across word boundaries.', phoneticHint: getIpa(phrase.replace(/_/g, ' ')) }
    });
  }
  for (const phrase of elision_phrases) {
    pool.push({
      instruction: 'Practice sound elision.',
      interactionType: 'speaking',
      fields: { word: phrase.replace(/_/g, ' '), options: ['Elided','Full'], correctAnswerIndex: 0, hint: 'Some consonants are dropped in natural speech.', phoneticHint: getIpa(phrase.replace(/_/g, ' ')) }
    });
  }

  
  // === AUTO-EXPANDED ENTRIES ===
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"turn off all lights","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("turn off all lights")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"pick up some flowers","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("pick up some flowers")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"put on your jacket","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("put on your jacket")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"take out the trash","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("take out the trash")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"give up bad habits","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("give up bad habits")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"come in right now","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("come in right now")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"sit down right here","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("sit down right here")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"stand up straight please","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("stand up straight please")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"move on from this","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("move on from this")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"look out for danger","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("look out for danger")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"calm down a moment","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("calm down a moment")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"speak up louder please","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("speak up louder please")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"slow down a little","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("slow down a little")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"speed up the process","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("speed up the process")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"clean up your desk","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("clean up your desk")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"clear out old files","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("clear out old files")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"head off to work","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("head off to work")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"branch out from here","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("branch out from here")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"reach out for help","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("reach out for help")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"step aside for now","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("step aside for now")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"climb up the stairs","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("climb up the stairs")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"jump over the fence","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("jump over the fence")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"swim across the lake","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("swim across the lake")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"walk along the path","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("walk along the path")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"drive around the block","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("drive around the block")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"fly over the mountains","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("fly over the mountains")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"run along the beach","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("run along the beach")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"sail across the bay","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("sail across the bay")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"hike up the trail","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("hike up the trail")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"crawl under the fence","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("crawl under the fence")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"wade through the stream","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("wade through the stream")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"dash across the road","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("dash across the road")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"stroll along the pier","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("stroll along the pier")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"march down the street","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("march down the street")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"sprint across the field","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("sprint across the field")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"wander around town","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("wander around town")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"glide across the ice","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("glide across the ice")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"paddle along the river","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("paddle along the river")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"trek through the jungle","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("trek through the jungle")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"coast along the shore","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("coast along the shore")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"go on ahead now","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("go on ahead now")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"do it again tomorrow","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("do it again tomorrow")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"so I understand","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("so I understand")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"also I agree with","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("also I agree with")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"she always asks why","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("she always asks why")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"he often eats alone","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("he often eats alone")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"we usually arrive early","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("we usually arrive early")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"they always argue about","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("they always argue about")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"I only asked once","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("I only asked once")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"do all of them","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("do all of them")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"go over it again","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("go over it again")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"see if anyone knows","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("see if anyone knows")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"white board marker","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("white board marker")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"that person there","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("that person there")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"good morning class","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("good morning class")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"great band tonight","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("great band tonight")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"would be nice","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("would be nice")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"could be better","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("could be better")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"should be ready","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("should be ready")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"might be wrong","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("might be wrong")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"want more food","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("want more food")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"need more time","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("need more time")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"find more space","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("find more space")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"make more plans","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("make more plans")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"last month ago","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("last month ago")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"next month ahead","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("next month ahead")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"first month here","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("first month here")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"worst month ever","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("worst month ever")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"asked them politely","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("asked them politely")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"reached down carefully","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("reached down carefully")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"watched them quietly","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("watched them quietly")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"touched down softly","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("touched down softly")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"pushed forward bravely","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("pushed forward bravely")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"crashed down loudly","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("crashed down loudly")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"launched quickly today","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("launched quickly today")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"searched everywhere here","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("searched everywhere here")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"switched off suddenly","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("switched off suddenly")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"ditched class today","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("ditched class today")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"hitched a ride home","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("hitched a ride home")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"stitched up the wound","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("stitched up the wound")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"fetched the supplies","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("fetched the supplies")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"sketched a drawing","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("sketched a drawing")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"stretched out fully","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("stretched out fully")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"wretched old building","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("wretched old building")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"hatched a new plan","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("hatched a new plan")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"matched perfectly well","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("matched perfectly well")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"dispatched immediately now","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("dispatched immediately now")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"snatched away quickly","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("snatched away quickly")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"clutched tightly shut","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("clutched tightly shut")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"crutched along slowly","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("crutched along slowly")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"thatched roof cottage","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("thatched roof cottage")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"patched up nicely","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("patched up nicely")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"botched the attempt","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("botched the attempt")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"notched another win","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("notched another win")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"scotched the rumor","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("scotched the rumor")}});
  pool.push({"instruction":"Practice connected speech linking.","interactionType":"speaking","fields":{"word":"botched another try","options":["Linked","Separated"],"correctAnswerIndex":0,"hint":"Connect words smoothly in natural speech.","phoneticHint":getIpa("botched another try")}});
console.log(`  wordLinking pool: ${pool.length}`);
  return pool;
};

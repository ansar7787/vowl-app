import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_services/smart_reply_service.dart';
import 'package:vowl/core/utils/widgets/smart_reply_chip.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_exchange_stage.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_header.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';

class DialogueRoleplayScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const DialogueRoleplayScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialogueRoleplay,
  });

  @override
  State<DialogueRoleplayScreen> createState() => _DialogueRoleplayScreenState();
}

class _DialogueRoleplayScreenState extends State<DialogueRoleplayScreen>
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<DialogueRoleplayScreen>,
        SpeakingGameScreenMixin<DialogueRoleplayScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
        'speaking_games.dialogue_expert',
        fallback: 'DIALOGUE EXPERT!',
      );

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;
  Timer? _autoPlayTimer;
  Timer? _scrollTimer;

  late AnimationController _synapticController;
  final ValueNotifier<double> _timeVal = ValueNotifier(0.0);

  List<String> _acceptedSynonyms = [];
  final ValueNotifier<List<String>> _smartReplies = ValueNotifier([]);
  final ValueNotifier<String> _chosenReply = ValueNotifier("");
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initGameLifecycle();
    initSpeakingGame();

    _synapticController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        _timeVal.value = _synapticController.value;
      });
    _synapticController.repeat();

    final initialBlocState = context.read<SpeakingBloc>().state;
    if (initialBlocState is SpeakingLoaded &&
        !initialBlocState.answerStatus.isAnswered) {
      if (initialBlocState.currentIndex == 0) {
        di.sl<SmartReplyService>().clearConversation();
      }
      if (VowlMotion.lowAnimationModeOverride.value) {
        _triggerAutoPlay(initialBlocState.currentQuest);
      } else {
        _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) _triggerAutoPlay(initialBlocState.currentQuest);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = (mediaQuery?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;
    if (reduceMotion) {
      _synapticController.stop();
      _timeVal.value = 0.5;
    } else if (!_synapticController.isAnimating) {
      _synapticController.repeat();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _ttsTimer?.cancel();
    _scrollTimer?.cancel();
    _synapticController.dispose();
    _timeVal.dispose();
    _smartReplies.dispose();
    _chosenReply.dispose();
    _scrollController.dispose();
    _ttsFinished.dispose();
    disposeSpeakingGame();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (VowlMotion.lowAnimationModeOverride.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
      return;
    }
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _triggerAutoPlay(SpeakingQuest quest) async {
    if (quest.partnerDialogue != null) {
      soundService.playTts(quest.partnerDialogue!);

      // Fetch suggestions based on the partner's dialogue
      final smartReplyService = di.sl<SmartReplyService>();
      smartReplyService.addMessage(quest.partnerDialogue!, isLocalUser: false);

      final suggestions = await smartReplyService.getSuggestions();
      final fallbackOptions = quest.smartReplies ?? quest.acceptedSynonyms;
      if (mounted) {
        final List<String> finalReplies = [];

        // 1. Prioritize level-specific authored synonyms first
        if (fallbackOptions != null && fallbackOptions.isNotEmpty) {
          final List<String> availableSynonyms = List.from(fallbackOptions)
            ..shuffle();
          finalReplies.addAll(availableSynonyms);
        }

        // 2. Append suggested replies (up to 3) at the end
        final List<String> mlReplies = suggestions
            .where(
              (s) => s.trim().length > 1 && RegExp(r'[a-zA-Z]').hasMatch(s),
            )
            .toList();
        for (var reply in mlReplies) {
          if (!finalReplies.contains(reply)) {
            finalReplies.add(reply);
          }
        }

        _smartReplies.value = finalReplies;
        _ttsTimer?.cancel();
        if (VowlMotion.lowAnimationModeOverride.value) {
          _ttsFinished.value = true;
          _scrollToBottom();
        } else {
          _ttsTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              _ttsFinished.value = true;
              _scrollToBottom();
            }
          });
        }
      }
    } else {
      _ttsFinished.value = true;
      _scrollToBottom();
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, SpeakingQuest quest) {
    if (isAnsweredNotifier.value) return;

    final responseText = _chosenReply.value.isNotEmpty
        ? _chosenReply.value
        : (_acceptedSynonyms.isNotEmpty
            ? _acceptedSynonyms.first
            : (quest.sentence ?? "Yes"));

    if (nailedIt) {
      di.sl<SmartReplyService>().addMessage(responseText, isLocalUser: true);
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(
        quest: quest,
        userAnswer: '[Failed Dialogue]',
      );
    }
  }

  @override
  void onQuestionReset() {
    _smartReplies.value = [];
    _chosenReply.value = "";
    _ttsFinished.value = false;
    _ttsTimer?.cancel();
    _autoPlayTimer?.cancel();
    _scrollTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listenWhen: speakingListenWhen,
      listener: (context, state) {
        onSpeakingStateChanged(context, state);
        if (state is SpeakingLoaded) {
          if (state.currentIndex == 0) {
            di.sl<SmartReplyService>().clearConversation();
          }
          if (!state.answerStatus.isAnswered) {
            _smartReplies.value = [];
            _chosenReply.value = "";
            _ttsFinished.value = false;
            _ttsTimer?.cancel();
            _autoPlayTimer?.cancel();
            if (VowlMotion.lowAnimationModeOverride.value) {
              _triggerAutoPlay(state.currentQuest);
            } else {
              _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
                if (mounted) _triggerAutoPlay(state.currentQuest);
              });
            }
          }
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _acceptedSynonyms = quest.acceptedSynonyms ?? [];
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _timeVal,
              _smartReplies,
              _chosenReply,
              _ttsFinished,
            ]),
            builder: (context, _) {
              final expectedText = _chosenReply.value.isNotEmpty
                  ? _chosenReply.value
                  : (_acceptedSynonyms.isNotEmpty
                      ? _acceptedSynonyms.first
                      : "");

              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                isFinalFailure: state is SpeakingLoaded
                    ? state.isFinalFailure
                    : false,
                disablePadding: true,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () {},
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DialogueRoleplayHeader(
                                      key: const Key(
                                        'dialogue_roleplay_header',
                                      ),
                                      primaryColor: theme.primaryColor,
                                      instruction:
                                          InstructionHelper.getInstruction(
                                        quest,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),
                                    DialogueRoleplayExchangeStage(
                                      key: const Key(
                                        'dialogue_roleplay_exchange_stage',
                                      ),
                                      quest: quest,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      timeVal: _timeVal.value,
                                      isAnswered: isAnsweredNotifier.value,
                                      isCorrect:
                                          isCorrectNotifier.value ?? false,
                                      userDisplayAnswer:
                                          _chosenReply.value.isNotEmpty
                                              ? _chosenReply.value
                                              : context.tr(
                                                  'speaking_games.pick_a_reply',
                                                  fallback:
                                                      'Pick a response to speak!',
                                                ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_smartReplies.value.isNotEmpty &&
                                !isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: SizedBox(
                                    height: 58.h,
                                    child: ListView.builder(
                                      key: const Key(
                                        'dialogue_roleplay_smart_replies_list',
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                      ),
                                      clipBehavior: Clip.none,
                                      itemCount: _smartReplies.value.length,
                                      itemBuilder: (context, index) {
                                        final reply =
                                            _smartReplies.value[index];
                                        final isSelected =
                                            reply == _chosenReply.value;
                                        return SmartReplyChip(
                                          key: Key(
                                            'dialogue_roleplay_smart_reply_$index',
                                          ),
                                          text: reply,
                                          isPremium: true,
                                          isSelected: isSelected,
                                          primaryColor: theme.primaryColor,
                                          onTap: () {
                                            _chosenReply.value = reply;
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (!isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: AnimatedOpacity(
                                    opacity: _ttsFinished.value ? 1.0 : 0.4,
                                    duration: const Duration(milliseconds: 300),
                                    child: AbsorbPointer(
                                      absorbing: !_ttsFinished.value,
                                      child: Builder(
                                        builder: (context) {
                                          final currentSynonyms = {
                                            ..._acceptedSynonyms,
                                            ..._smartReplies.value,
                                          }.toList();

                                          return SpeakToConfirmOverlay(
                                            key: const Key(
                                              'dialogue_roleplay_speak_confirm_overlay',
                                            ),
                                            expectedText: expectedText,
                                            acceptedSynonyms: currentSynonyms,
                                            primaryColor: theme.primaryColor,
                                            isPositioned: false,
                                            hideExpectedText: true,
                                            allowSkip: false,
                                            title: 'SPEAK YOUR LINE',
                                            subtitle:
                                                'Say the selected option aloud',
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(
                                                  true,
                                                  quest,
                                                ),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(
                                                  false,
                                                  quest,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                          ],
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

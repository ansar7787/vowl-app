import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';

import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_customs_terminal.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_passport_book.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_stamp_station.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class TravelDeskScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TravelDeskScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.travelDesk,
  });

  @override
  State<TravelDeskScreen> createState() => _TravelDeskScreenState();
}

class _TravelDeskScreenState extends State<TravelDeskScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<TravelDeskScreen>,
        RoleplayGameScreenMixin<TravelDeskScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _rippleController;

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  // Custom drag feedback coordinates
  final ValueNotifier<int?> _hoveredIndex = ValueNotifier(null);

  late final Listenable _mergedListenable;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _mergedListenable = Listenable.merge([
      isAnsweredNotifier,
      isCorrectNotifier,
      showConfettiNotifier,
      _selectedIndex,
      _hoveredIndex,
      isFirstStagePassedNotifier,
    ]);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    initRoleplayGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_rippleController.isAnimating) _rippleController.stop();
    } else {
      if (!_rippleController.isAnimating) {
        _rippleController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _selectedIndex.dispose();
    _hoveredIndex.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _submitStamp(int index, int correctIndex, GameQuest quest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final isCorrect = index == correctIndex;

    _selectedIndex.value = index;

    _rippleController.forward(from: 0.0);

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      final userAnswer = quest.options != null && index < quest.options!.length
          ? quest.options![index]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      submitCorrectAnswer();
    } else {
      hapticService.error();
      soundService.playWrong();
      final userAnswer =
          (_selectedIndex.value != null &&
              quest.options != null &&
              _selectedIndex.value! < quest.options!.length)
          ? quest.options![_selectedIndex.value!]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;

    _hoveredIndex.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return ListenableBuilder(
          listenable: _mergedListenable,
          builder: (context, _) {
            return RoleplayBaseLayout(
              fullScreenContent: true,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                              SliverToBoxAdapter(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact =
                                        MediaQuery.of(context).size.height <
                                        600;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isCompact ? 5.h : 10.h,
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            child: TravelDeskCustomsTerminal(
                                              instruction:
                                                  InstructionHelper.getInstruction(
                                                    quest,
                                                  ),
                                              prompt: quest.prompt ?? "",
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                          SizedBox(
                                            height: isCompact ? 12.h : 16.h,
                                          ),

                                          // Biometric Passport Book (Full Width)
                                          TravelDeskPassportBook(
                                            options: quest.itinerary ?? options,
                                            color: theme.primaryColor,
                                            correctIndex:
                                                quest.correctAnswerIndex ?? 0,
                                            isDark: isDark,
                                            travelDocument:
                                                quest.travelDocuments,
                                            selectedIndex: _selectedIndex.value,
                                            hoveredIndex: _hoveredIndex.value,
                                            isAnswered:
                                                isAnsweredNotifier.value ||
                                                isFirstStagePassedNotifier
                                                    .value,
                                            isCorrect: isCorrectNotifier.value,
                                            rippleAnimation: _rippleController,
                                            onSubmitStamp:
                                                (index, correctIndex) =>
                                                    _submitStamp(
                                                      index,
                                                      correctIndex,
                                                      quest,
                                                    ),
                                            onHoverChanged: (index) {
                                              hapticService.selection();
                                              _hoveredIndex.value = index;
                                            },
                                            onHoverEnded: () {
                                              _hoveredIndex.value = null;
                                            },
                                            onDragStarted: () {},
                                          ),
                                          SizedBox(
                                            height: isCompact ? 16.h : 20.h,
                                          ),

                                          // Stamp slammed terminal console
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            switchOutCurve: Curves.easeOut,
                                            transitionBuilder:
                                                (child, animation) {
                                                  return SizeTransition(
                                                    sizeFactor: animation,
                                                    axisAlignment: -1.0,
                                                    child: FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                            child:
                                                (!isAnsweredNotifier.value &&
                                                    !isFirstStagePassedNotifier
                                                        .value)
                                                ? Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 16.w,
                                                        ),
                                                    child:
                                                        TravelDeskStampStation(
                                                          color: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                          onDragStarted: () {
                                                            hapticService
                                                                .selection();
                                                            soundService
                                                                .playHint();
                                                          },
                                                          onDragEnded: () {
                                                            _hoveredIndex
                                                                    .value =
                                                                null;
                                                          },
                                                        ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),

                                          SizedBox(
                                            height: isCompact ? 20.h : 40.h,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value &&
                                  _selectedIndex.value != null)
                                SliverToBoxAdapter(
                                  child: SpeakToConfirmOverlay(
                                    expectedText:
                                        options[_selectedIndex.value!],
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      context.read<RoleplayBloc>().add(
                                        const RoleplaySpeakConfirmed(5),
                                      );
                                      _submitVerbalEvaluation(true, quest);
                                    },
                                    onSkipped: () =>
                                        _submitVerbalEvaluation(false, quest),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

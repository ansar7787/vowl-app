import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_banquet_header.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_table_setting.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_plate_tray.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class GourmetOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GourmetOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.gourmetOrder,
  });

  @override
  State<GourmetOrderScreen> createState() => _GourmetOrderScreenState();
}

class _GourmetOrderScreenState extends State<GourmetOrderScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<GourmetOrderScreen>,
        RoleplayGameScreenMixin<GourmetOrderScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _steamController;
  late AnimationController _pulseController;

  final ValueNotifier<List<String>> _selectedItems = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();

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

    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    initRoleplayGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_steamController.isAnimating) _steamController.stop();
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_steamController.isAnimating) _steamController.repeat();
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _steamController.dispose();
    _pulseController.dispose();
    _selectedItems.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _onItemTapped(String item) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    soundService.playHint(); // Play synth note
    final current = List<String>.from(_selectedItems.value);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      current.add(item);
    }
    _selectedItems.value = current;
  }

  void _onItemDropped(String item) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    final current = List<String>.from(_selectedItems.value);
    if (!current.contains(item)) {
      hapticService.selection();
      soundService.playHint();
      current.add(item);
      _selectedItems.value = current;
    }
  }

  void _clearItems() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    _selectedItems.value = [];
  }

  void _submitAnswer(String correctAnswer, GameQuest quest) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        _selectedItems.value.isEmpty) {
      return;
    }

    final targets = correctAnswer
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    final current = _selectedItems.value
        .map((e) => e.trim().toLowerCase())
        .toList();

    bool isCorrect =
        targets.length == current.length &&
        targets.every((t) => current.contains(t));

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      submitWrongAnswer(
        quest: quest,
        userAnswer: _selectedItems.value.join(', '),
      );
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      _scrollToBottom();
      submitWrongAnswer(
        quest: quest,
        userAnswer: _selectedItems.value.join(', '),
      );
    }
  }

  @override
  void onQuestionReset() {
    _selectedItems.value = [];
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
        final prices = quest?.menuPrices ?? [];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
          ]),
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
                        return ValueListenableBuilder<List<String>>(
                          valueListenable: _selectedItems,
                          builder: (context, selectedItemsList, _) {
                            return RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: SizedBox(height: 24.h),
                                  ),
                                  SliverToBoxAdapter(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isCompact =
                                            MediaQuery.sizeOf(context).height <
                                            650;
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: isCompact ? 5.h : 10.h,
                                          ),
                                          child: Column(
                                            children: [
                                              GourmetOrderBanquetHeader(
                                                prompt: quest.prompt ?? "",
                                                instruction:
                                                    InstructionHelper.getInstruction(
                                                      quest,
                                                    ),
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                              ),
                                              SizedBox(
                                                height: isCompact ? 16.h : 24.h,
                                              ),

                                              // Floating Cloche Platter
                                              GourmetOrderTableSetting(
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered:
                                                    isAnsweredNotifier.value &&
                                                    (isCorrectNotifier.value !=
                                                            null ||
                                                        !isFirstStagePassedNotifier
                                                            .value),
                                                isCorrect:
                                                    isCorrectNotifier.value,
                                                selectedItems:
                                                    _selectedItems.value,
                                                steamAnimation:
                                                    _steamController,
                                                onItemDropped: _onItemDropped,
                                                onHapticFeedback:
                                                    hapticService.selection,
                                              ),
                                              SizedBox(
                                                height: isCompact ? 16.h : 24.h,
                                              ),

                                              // Tray of plate choices
                                              GourmetOrderPlateTray(
                                                options: options,
                                                prices: prices,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered:
                                                    isAnsweredNotifier.value &&
                                                    (isCorrectNotifier.value !=
                                                            null ||
                                                        !isFirstStagePassedNotifier
                                                            .value),
                                                isCorrect:
                                                    isCorrectNotifier.value,
                                                selectedItems:
                                                    _selectedItems.value,
                                                onItemTapped: _onItemTapped,
                                                onDragStarted: () {
                                                  hapticService.selection();
                                                  soundService
                                                      .playHint(); // Play synth note
                                                },
                                              ),
                                              SizedBox(
                                                height: isCompact ? 20.h : 28.h,
                                              ),

                                              // Trigger Action Buttons
                                              if (!isAnsweredNotifier.value &&
                                                  _selectedItems
                                                      .value
                                                      .isNotEmpty)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: ScaleButton(
                                                        onTap: _clearItems,
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    isCompact
                                                                    ? 16.w
                                                                    : 24.w,
                                                                vertical:
                                                                    isCompact
                                                                    ? 10.h
                                                                    : 12.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  30.r,
                                                                ),
                                                            border: Border.all(
                                                              color: theme
                                                                  .primaryColor
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .refresh_rounded,
                                                                color: theme
                                                                    .primaryColor,
                                                                size: isCompact
                                                                    ? 16.r
                                                                    : 18.r,
                                                              ),
                                                              SizedBox(
                                                                width: 6.w,
                                                              ),
                                                              Text(
                                                                "CLEAR PLATTER",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      isCompact
                                                                      ? 10.sp
                                                                      : 12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: theme
                                                                      .primaryColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: isCompact
                                                          ? 10.w
                                                          : 16.w,
                                                    ),
                                                    Expanded(
                                                      child: ScaleButton(
                                                        onTap: () => _submitAnswer(
                                                          quest.correctAnswer ??
                                                              "",
                                                          quest,
                                                        ),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    isCompact
                                                                    ? 20.w
                                                                    : 32.w,
                                                                vertical:
                                                                    isCompact
                                                                    ? 10.h
                                                                    : 12.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  30.r,
                                                                ),
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                theme
                                                                    .primaryColor,
                                                                theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.8,
                                                                    ),
                                                              ],
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.35,
                                                                    ),
                                                                blurRadius:
                                                                    isCompact
                                                                    ? 10
                                                                    : 15,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .restaurant_menu_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: isCompact
                                                                    ? 16.r
                                                                    : 18.r,
                                                              ),
                                                              SizedBox(
                                                                width: 6.w,
                                                              ),
                                                              Text(
                                                                "SERVE PLATTER",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      isCompact
                                                                      ? 10.sp
                                                                      : 12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                  letterSpacing:
                                                                      1.5,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ).animate().fadeIn(
                                                  duration: 300.ms,
                                                ),

                                              // Explanations cards post-selection
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
                                      !isAnsweredNotifier.value)
                                    SliverToBoxAdapter(
                                      child: SpeakToConfirmOverlay(
                                        expectedText:
                                            quest.correctAnswer ??
                                            _selectedItems.value.join(', '),
                                        primaryColor: theme.primaryColor,
                                        isPositioned: false,
                                        onConfirmed: () {
                                          context.read<RoleplayBloc>().add(
                                            const RoleplaySpeakConfirmed(5),
                                          );
                                          _submitVerbalEvaluation(true, quest);
                                        },
                                        onSkipped: () =>
                                            _submitVerbalEvaluation(
                                              false,
                                              quest,
                                            ),
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
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

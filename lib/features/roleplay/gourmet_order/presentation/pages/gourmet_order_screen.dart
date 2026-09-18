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
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_instruction.dart';
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

class _GourmetOrderScreenState extends State<GourmetOrderScreen>with TickerProviderStateMixin, RoleplayGameScreenMixin {
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
        
  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    initRoleplayGame();
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

  void _clearItems() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    _selectedItems.value = [];
  }

  void _submitAnswer(String correctAnswer) {
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
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
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
            _selectedItems,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null || !isFirstStagePassedNotifier.value),
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
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxHeight < 580;
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: isCompact
                                                      ? 5.h
                                                      : 10.h,
                                                ),
                                                child: Column(
                                                  children: [
                                                    GourmetOrderInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          InstructionHelper.getInstruction(
                                                            quest,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),
                                                    GourmetOrderBanquetHeader(
                                                      prompt:
                                                          quest.prompt ?? "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
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
                                                      onItemTapped:
                                                          _onItemTapped,
                                                      onHapticFeedback:
                                                          hapticService
                                                              .selection,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
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
                                                      onItemTapped:
                                                          _onItemTapped,
                                                      onDragStarted: () {
                                                        hapticService
                                                            .selection();
                                                        soundService
                                                            .playHint(); // Play synth note
                                                      },
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 28.h,
                                                    ),

                                                    // Trigger Action Buttons
                                                    if (!isAnsweredNotifier.value &&
                                                        _selectedItems
                                                            .value
                                                            .isNotEmpty)
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          ScaleButton(
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
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                border: Border.all(
                                                                  color: theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .refresh_rounded,
                                                                    color: theme
                                                                        .primaryColor,
                                                                    size:
                                                                        isCompact
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
                                                          SizedBox(
                                                            width: isCompact
                                                                ? 10.w
                                                                : 16.w,
                                                          ),
                                                          ScaleButton(
                                                            onTap: () =>
                                                                _submitAnswer(
                                                                  quest.correctAnswer ??
                                                                      "",
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
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .restaurant_menu_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size:
                                                                        isCompact
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
                                                        ],
                                                      ).animate().fadeIn(
                                                        duration: 300.ms,
                                                      ),

                                                    // Explanations cards post-selection
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (isFirstStagePassedNotifier.value &&
                                              !isAnsweredNotifier.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFirstStagePassedNotifier.value && !isAnsweredNotifier.value)
                              SpeakToConfirmOverlay(
                                expectedText:
                                    quest.correctAnswer ??
                                    _selectedItems.value.join(', '),
                                primaryColor: theme.primaryColor,
                                isPositioned: true,
                                onConfirmed: () {
                                  context.read<RoleplayBloc>().add(
                                    const RoleplaySpeakConfirmed(5),
                                  );
                                  _submitVerbalEvaluation(true);
                                },
                                onSkipped: () => _submitVerbalEvaluation(false),
                              ),
                          ],
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

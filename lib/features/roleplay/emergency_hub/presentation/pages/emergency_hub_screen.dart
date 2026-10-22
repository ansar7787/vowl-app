import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_telex_card.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_terminal_input.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_valve_chamber.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class EmergencyHubScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmergencyHubScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emergencyHub,
  });

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<EmergencyHubScreen>,
        RoleplayGameScreenMixin<EmergencyHubScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _pulseController;
  late TextEditingController _codeController;

  final ValueNotifier<double> _rotation = ValueNotifier(
    0.0,
  ); // Valve rotation progress (0.0 to 1.0)
  final ScrollController _scrollController = ScrollController();

  Timer? _scrollTimer;

  void _scrollToBottom() {
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false ||
        VowlMotion.lowAnimationModeOverride.value;
    if (reduceMotion) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      return;
    }
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _codeController = TextEditingController();

    initRoleplayGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;
    if (reduceMotion) {
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pulseController.dispose();
    _codeController.dispose();
    _rotation.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  double _lastHapticProgress = 0.0;

  // Trigonometry-based circular dial update
  void _onValveDragged(DragUpdateDetails details, Offset localCenter) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final Offset touchPos = details.localPosition;
    final double dx = touchPos.dx - localCenter.dx;
    final double dy = touchPos.dy - localCenter.dy;

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    // Convert angle starting from top-center (-pi/2) to decimal (0.0 to 1.0)
    double progress = (angle + math.pi / 2) / (2 * math.pi);
    if (progress > 1.0) progress -= 1.0;

    // Throttle haptics so it only clicks every ~5% rotation
    if ((progress - _lastHapticProgress).abs() > 0.05) {
      hapticService.selection();
      _lastHapticProgress = progress;
    }

    _rotation.value = progress.clamp(0.0, 1.0);
  }

  // Accessible fallback for screen readers or motor difficulties
  void _onValveAccessibleAlign() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    _rotation.value = 1.0;
  }

  void _submitCode(String input, String correctAnswer, GameQuest quest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final String cleanInput = input.trim().replaceAll(' ', '').toLowerCase();
    final String cleanCorrect = correctAnswer
        .trim()
        .replaceAll(' ', '')
        .toLowerCase();

    final bool codeMatches = cleanInput == cleanCorrect;

    if (codeMatches) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      submitWrongAnswer(quest: quest, userAnswer: input);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      _scrollToBottom();
      submitWrongAnswer(quest: quest, userAnswer: _codeController.text);
    }
  }

  @override
  void onQuestionReset() {
    _rotation.value = 0.0;
    _lastHapticProgress = 0.0;
    _codeController.clear();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _rotation,
            isFirstStagePassedNotifier,
            _codeController,
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
              onHint: () {
                hapticService.selection();
              },
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(
                      primaryColor: Theme.of(context).primaryColor,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: tokens.gameIncorrect.withValues(
                            alpha: 0.5,
                          ),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                              SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: kRoleplayMaxContentWidth,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final isCompact =
                                            MediaQuery.sizeOf(context).height < 700;
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: isCompact ? 6.h : 10.h,
                                          ),
                                          child: Column(
                                            children: [
                                              // Critical dispatcher prompt telex
                                              EmergencyHubTelexCard(
                                                key: const Key('emergency_hub_telex_card'),
                                                instruction:
                                                    InstructionHelper.getInstruction(
                                                      quest,
                                                    ),
                                                dispatcherQuestion:
                                                    quest.dispatcherQuestion ?? "",
                                                urgencyLevel:
                                                    quest.urgencyLevel ?? 3,
                                                isDark: isDark,
                                              ),
                                              SizedBox(
                                                height: isCompact ? 14.h : 20.h,
                                              ),

                                              // Retro terminal input text field
                                              EmergencyHubTerminalInput(
                                                key: const Key('emergency_hub_terminal_input'),
                                                controller: _codeController,
                                                correctAnswer:
                                                    quest.correctAnswer ?? "",
                                                isDark: isDark,
                                                onChanged: () {},
                                              ),
                                              SizedBox(
                                                height: isCompact ? 14.h : 20.h,
                                              ),

                                              // Mechanical safety valve chamber
                                              EmergencyHubValveChamber(
                                                key: const Key('emergency_hub_valve_chamber'),
                                                correctAnswer:
                                                    quest.correctAnswer ?? "",
                                                inputText: _codeController.text,
                                                isDark: isDark,
                                                rotation: _rotation.value,
                                                pulseAnimation: _pulseController,
                                                onValveDragged: _onValveDragged,
                                                onValveAccessibleAlign:
                                                    _onValveAccessibleAlign,
                                              ),
                                              SizedBox(
                                                height: isCompact ? 16.h : 24.h,
                                              ),

                                              // Dispatch lock confirm trigger button
                                              if (!isAnsweredNotifier.value &&
                                                  _codeController.text.isNotEmpty)
                                                Builder(
                                                  builder: (context) {
                                                    final bool isValveAligned =
                                                        _rotation.value >= 0.85;
                                                    final reduceMotion =
                                                        MediaQuery.disableAnimationsOf(context) ||
                                                        VowlMotion.lowAnimationModeOverride.value;
                                                    Widget launchBtn = ScaleButton(
                                                      key: const Key('emergency_hub_launch_button'),
                                                      onTap: isValveAligned
                                                          ? () => _submitCode(
                                                              _codeController.text,
                                                              quest.correctAnswer ??
                                                                  "",
                                                              quest,
                                                            )
                                                          : null,
                                                      child: AnimatedContainer(
                                                        duration: const Duration(
                                                          milliseconds: 300,
                                                        ),
                                                        curve: Curves.easeInOut,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                              vertical: isCompact
                                                                  ? 12.h
                                                                  : 15.h,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                28.r,
                                                              ),
                                                          color: isValveAligned
                                                              ? Colors.red.shade700
                                                              : (isDark
                                                                    ? Colors
                                                                          .grey
                                                                          .shade800
                                                                    : Colors
                                                                          .grey
                                                                          .shade400),
                                                          boxShadow: isValveAligned
                                                              ? [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .red
                                                                        .shade700
                                                                        .withValues(
                                                                          alpha:
                                                                              0.4,
                                                                        ),
                                                                    blurRadius: 12,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          4,
                                                                        ),
                                                                  ),
                                                                ]
                                                              : null,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              isValveAligned
                                                                  ? Icons
                                                                        .flash_on_rounded
                                                                  : Icons
                                                                        .lock_outline_rounded,
                                                              color: isValveAligned
                                                                  ? Colors.white
                                                                  : Colors.white70,
                                                              size: isCompact
                                                                  ? 18.r
                                                                  : 20.r,
                                                            ),
                                                            SizedBox(width: 8.w),
                                                            Flexible(
                                                              child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: AnimatedDefaultTextStyle(
                                                                  duration:
                                                                      const Duration(
                                                                        milliseconds:
                                                                            300,
                                                                      ),
                                                                  style: TextStyle(
                                                                    fontFamily:
                                                                        'Outfit',
                                                                    fontSize:
                                                                        isCompact
                                                                        ? 13.sp
                                                                        : 15.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        isValveAligned
                                                                        ? Colors
                                                                              .white
                                                                        : Colors
                                                                              .white70,
                                                                    letterSpacing:
                                                                        0.8,
                                                                  ),
                                                                  child: Text(
                                                                    isValveAligned
                                                                        ? "LAUNCH EMERGENCY BEACON"
                                                                        : "ALIGN VALVE TO LAUNCH",
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );

                                                    if (!reduceMotion) {
                                                      launchBtn = launchBtn.animate().fadeIn(
                                                        duration: 300.ms,
                                                      );
                                                    }
                                                    return launchBtn;
                                                  },
                                                ),

                                              // Review details
                                              SizedBox(
                                                height: isCompact ? 20.h : 40.h,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value)
                                SliverToBoxAdapter(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: kRoleplayMaxContentWidth,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                        ),
                                        child: SpeakToConfirmOverlay(
                                          expectedText:
                                              quest.correctAnswer ??
                                              _codeController.text,
                                          primaryColor: tokens.gameIncorrect,
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
                                    ),
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

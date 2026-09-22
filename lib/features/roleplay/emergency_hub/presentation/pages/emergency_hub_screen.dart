import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_instruction.dart';
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
    with TickerProviderStateMixin, RoleplayGameScreenMixin {
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

  @override
  void initState() {
    super.initState();
    isFirstStagePassedNotifier.addListener(() {
      if (isFirstStagePassedNotifier.value &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _codeController = TextEditingController();

    initRoleplayGame();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _codeController.dispose();
    _rotation.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

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

    hapticService.selection();
    _rotation.value = progress.clamp(0.0, 1.0);
  }

  void _submitCode(String input, String correctAnswer) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final String cleanInput = input.trim().replaceAll(' ', '').toLowerCase();
    final String cleanCorrect = correctAnswer
        .trim()
        .replaceAll(' ', '')
        .toLowerCase();

    // Check if code matches AND safety valve is rotated past 85% to pressurize the lock
    final bool codeMatches = cleanInput == cleanCorrect;
    final bool valveAligned = _rotation.value >= 0.85;

    final bool isCorrect = codeMatches && valveAligned;

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
    _rotation.value = 0.0;
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
                                              vertical: isCompact ? 5.h : 10.h,
                                            ),
                                            child: Column(
                                              children: [
                                                EmergencyHubInstruction(
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

                                                // Critical dispatcher prompt telex
                                                EmergencyHubTelexCard(
                                                  telex:
                                                      quest
                                                          .dispatcherQuestion ??
                                                      "AWAITING BROADCAST VECTOR DETAILS...",
                                                  urgencyLevel:
                                                      quest.urgencyLevel ?? 3,
                                                  isDark: isDark,
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 12.h
                                                      : 20.h,
                                                ),

                                                // Retro terminal input text field
                                                EmergencyHubTerminalInput(
                                                  controller: _codeController,
                                                  correctAnswer:
                                                      quest.correctAnswer ?? "",
                                                  isDark: isDark,
                                                  onChanged: () {},
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 12.h
                                                      : 20.h,
                                                ),

                                                // Mechanical safety valve chamber
                                                EmergencyHubValveChamber(
                                                  correctAnswer:
                                                      quest.correctAnswer ?? "",
                                                  inputText:
                                                      _codeController.text,
                                                  isDark: isDark,
                                                  rotation: _rotation.value,
                                                  pulseAnimation:
                                                      _pulseController,
                                                  onValveDragged:
                                                      _onValveDragged,
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 16.h
                                                      : 24.h,
                                                ),

                                                // Dispatch lock confirm trigger button
                                                if (!isAnsweredNotifier.value &&
                                                    _codeController
                                                        .text
                                                        .isNotEmpty)
                                                  ScaleButton(
                                                    onTap: () => _submitCode(
                                                      _codeController.text,
                                                      quest.correctAnswer ?? "",
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 48.w,
                                                            vertical: isCompact
                                                                ? 10.h
                                                                : 14.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30.r,
                                                            ),
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .redAccent,
                                                                Colors
                                                                    .deepOrangeAccent,
                                                              ],
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .redAccent
                                                                .withValues(
                                                                  alpha: 0.45,
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
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .flash_on_rounded,
                                                            color: Colors.white,
                                                            size: isCompact
                                                                ? 16.r
                                                                : 18.r,
                                                          ),
                                                          SizedBox(width: 8.w),
                                                          Text(
                                                            "LAUNCH EMERGENCY BEACON",
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
                                                              color:
                                                                  Colors.white,
                                                              letterSpacing: 2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ).animate().fadeIn(
                                                    duration: 300.ms,
                                                  ),

                                                // Review details
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

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
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
                                        _submitVerbalEvaluation(true);
                                      },
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false),
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

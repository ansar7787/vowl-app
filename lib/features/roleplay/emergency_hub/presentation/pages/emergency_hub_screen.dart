import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_instruction.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_telex_card.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_terminal_input.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_valve_chamber.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _pulseController;
  late TextEditingController _codeController;

  int _lastProcessedIndex = -1;
  final ValueNotifier<double> _rotation = ValueNotifier(
    0.0,
  ); // Valve rotation progress (0.0 to 1.0)
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _codeController = TextEditingController();

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _codeController.dispose();
    _rotation.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.dispatcherQuestion != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.dispatcherQuestion!);
      });
    }
  }

  // Trigonometry-based circular dial update
  void _onValveDragged(DragUpdateDetails details, Offset localCenter) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    final Offset touchPos = details.localPosition;
    final double dx = touchPos.dx - localCenter.dx;
    final double dy = touchPos.dy - localCenter.dy;

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    // Convert angle starting from top-center (-pi/2) to decimal (0.0 to 1.0)
    double progress = (angle + math.pi / 2) / (2 * math.pi);
    if (progress > 1.0) progress -= 1.0;

    _hapticService.selection();
    _rotation.value = progress.clamp(0.0, 1.0);
  }

  void _submitCode(String input, String correctAnswer) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

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
      _hapticService.selection();
      _isFirstStagePassed.value = true;
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _rotation.value = 0.0;
            _codeController.clear();
            _isFirstStagePassed.value = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'HERO DISPATCHER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _rotation,
            _isFirstStagePassed,
            _codeController,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: Colors.redAccent.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
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
                                                    EmergencyHubInstruction(
                                                      instruction:
                                                          quest.instruction,
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
                                                          quest.urgencyLevel ??
                                                          3,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 12.h
                                                          : 20.h,
                                                    ),

                                                    // Retro terminal input text field
                                                    EmergencyHubTerminalInput(
                                                      controller:
                                                          _codeController,
                                                      correctAnswer:
                                                          quest.correctAnswer ??
                                                          "",
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
                                                          quest.correctAnswer ??
                                                          "",
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
                                                    if (!_isAnswered.value &&
                                                        _codeController
                                                            .text
                                                            .isNotEmpty)
                                                      ScaleButton(
                                                        onTap: () => _submitCode(
                                                          _codeController.text,
                                                          quest.correctAnswer ??
                                                              "",
                                                        ),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    48.w,
                                                                vertical:
                                                                    isCompact
                                                                    ? 10.h
                                                                    : 14.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  30.r,
                                                                ),
                                                            gradient: const LinearGradient(
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
                                                                      alpha:
                                                                          0.45,
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
                                                                    .flash_on_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: isCompact
                                                                    ? 16.r
                                                                    : 18.r,
                                                              ),
                                                              SizedBox(
                                                                width: 8.w,
                                                              ),
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
                                                                  color: Colors
                                                                      .white,
                                                                  letterSpacing:
                                                                      2,
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
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (_isFirstStagePassed.value &&
                                              !_isAnswered.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isFirstStagePassed.value && !_isAnswered.value)
                              SpeakToConfirmOverlay(
                                expectedText:
                                    quest.correctAnswer ?? _codeController.text,
                                primaryColor: Colors.redAccent,
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

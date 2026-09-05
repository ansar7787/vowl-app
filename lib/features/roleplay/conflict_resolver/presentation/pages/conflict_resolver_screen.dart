import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
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
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_instruction.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_conflict_card.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_dial_console.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class ConflictResolverScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConflictResolverScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conflictResolver,
  });

  @override
  State<ConflictResolverScreen> createState() => _ConflictResolverScreenState();
}

class _ConflictResolverScreenState extends State<ConflictResolverScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _waveController;
  late AnimationController _pulseController;

  int _lastProcessedIndex = -1;
  final ValueNotifier<double> _rotation = ValueNotifier(
    0.0,
  ); // Slider score level (0.0 to 1.0)
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _rotation.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(InstructionHelper.getInstruction(quest));
    if (quest.scene != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.scene!);
      });
    }
  }

  // Realistic Physical dial rotation updater utilizing trigonometry
  void _onDialDragged(DragUpdateDetails details, Offset localDialCenter) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    final Offset touchPos = details.localPosition;
    final double dx = touchPos.dx - localDialCenter.dx;
    final double dy = touchPos.dy - localDialCenter.dy;

    // Calculate angle in radians (-pi to pi)
    double angle = math.atan2(dy, dx);

    // Normalize to 0 to 2pi
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    // Convert angle to progress scale (0.0 to 1.0)
    // -pi/2 (top center) is 0.0
    double progress = (angle + math.pi / 2) / (2 * math.pi);
    if (progress > 1.0) progress -= 1.0;

    _hapticService.selection();
    _rotation.value = progress.clamp(0.0, 1.0);
  }

  void _submitAnswer(double target) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    // 0.12 empathy tolerance proximity check
    bool isCorrect = (_rotation.value - target).abs() < 0.12;

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
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _rotation.value = 0.0;
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
            title: 'PEACE RESOLVER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final double empathyTarget = quest?.empathyScore ?? 0.75;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _rotation,
            _isFirstStagePassed,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  _isAnswered.value &&
                  (_isCorrect.value != null || !_isFirstStagePassed.value),
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
                              thumbColor: theme.primaryColor.withValues(
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
                                                    ConflictResolverInstruction(
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
                                                    ConflictResolverConflictCard(
                                                      scene: quest.scene ?? "",
                                                      escalationLevel:
                                                          quest
                                                              .escalationLevel ??
                                                          5,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      rotation: _rotation.value,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),

                                                    // Circular audio dials
                                                    ConflictResolverDialConsole(
                                                      targetValue:
                                                          empathyTarget,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      rotation: _rotation.value,
                                                      waveAnimation:
                                                          _waveController,
                                                      onDialDragged:
                                                          _onDialDragged,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 28.h,
                                                    ),

                                                    // Submit control button
                                                    if (!_isAnswered.value)
                                                      ScaleButton(
                                                        onTap: () =>
                                                            _submitAnswer(
                                                              empathyTarget,
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
                                                                    .security_rounded,
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
                                                                "LOCK HARMONIC FREQUENCY",
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
                                                      ).animate().fadeIn(
                                                        duration: 300.ms,
                                                      ),

                                                    // Post-answer review cards
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
                                    quest.correctAnswer ??
                                    "De-escalating conflict",
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

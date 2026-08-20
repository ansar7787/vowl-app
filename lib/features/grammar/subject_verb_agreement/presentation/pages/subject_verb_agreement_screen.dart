import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/widgets/subject_verb_agreement_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_jigsaw_wrapper.dart';

class SubjectVerbAgreementScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SubjectVerbAgreementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.subjectVerbAgreement,
  });

  @override
  State<SubjectVerbAgreementScreen> createState() =>
      _SubjectVerbAgreementScreenState();
}

class _SubjectVerbAgreementScreenState
    extends State<SubjectVerbAgreementScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  Offset _ringOffset = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _pendingJigsaw = false;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onConnect(int targetIndex, int correctIndex) {
    if (_isAnswered || _pendingJigsaw) return;

    bool isCorrect = targetIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _ringOffset = Offset(targetIndex == 0 ? -120.w : 120.w, 0.0);
        _pendingJigsaw = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _ringOffset = Offset(targetIndex == 0 ? -120.w : 120.w, 0.0);
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    setState(() => _pendingJigsaw = false);
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingJigsaw = false;
              _ringOffset = Offset.zero;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'AGREEMENT MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["Is", "Are"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          cleanTargetSentence = sentence
              .replaceAll('[', '')
              .replaceAll(']', '');
        }

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: false, // Stack needs finite space to anchor to bottom
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxHeight < 580;

                                return Column(
                          children: [
                            SizedBox(height: isCompact ? 4.h : 10.h),
                            isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: SubjectVerbAgreementInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : SubjectVerbAgreementInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: isCompact ? 10.h : 24.h),

                            // Atmospheric Harmony Hub
                            Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(
                                      isCompact ? 14.r : 24.r,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 20.r : 32.r,
                                      ),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 40,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      quest.question ??
                                          "Complete the agreement...",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: isCompact ? 16.sp : 22.sp,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 800.ms)
                                .slideY(begin: 0.1, end: 0),

                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 30.w),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Tuner Rails
                                    Container(
                                      height: isCompact ? 3.h : 4.h,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.primaryColor.withValues(
                                              alpha: 0.0,
                                            ),
                                            theme.primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            theme.primaryColor.withValues(
                                              alpha: 0.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Verb Terminals
                                    GestureDetector(
                                      onTap: () => _onConnect(
                                        0,
                                        quest.correctAnswerIndex ?? 0,
                                      ),
                                      child: _buildVerbTerminal(
                                        0,
                                        options[0],
                                        theme.primaryColor,
                                        Alignment.centerLeft,
                                        quest.correctAnswerIndex ?? 0,
                                        isCompact,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _onConnect(
                                        1,
                                        quest.correctAnswerIndex ?? 0,
                                      ),
                                      child: _buildVerbTerminal(
                                        1,
                                        options[1],
                                        theme.primaryColor,
                                        Alignment.centerRight,
                                        quest.correctAnswerIndex ?? 0,
                                        isCompact,
                                      ),
                                    ),

                                    // The Quantum Core (Harmony Slider)
                                    GestureDetector(
                                      onPanUpdate: _isAnswered || _pendingJigsaw
                                          ? null
                                          : (details) {
                                              final double newDx =
                                                  (_ringOffset.dx +
                                                          details.delta.dx)
                                                      .clamp(
                                                        isCompact
                                                            ? -100.w
                                                            : -130.w,
                                                        isCompact
                                                            ? 100.w
                                                            : 130.w,
                                                      );
                                              setState(() {
                                                _ringOffset = Offset(
                                                  newDx,
                                                  0.0,
                                                );
                                              });
                                              _checkHarmony(
                                                quest.correctAnswerIndex ?? 0,
                                              );
                                            },
                                      onPanEnd: _isAnswered || _pendingJigsaw
                                          ? null
                                          : (details) {
                                              setState(
                                                () => _ringOffset = Offset.zero,
                                              );
                                            },
                                      child: Transform.translate(
                                        offset: _ringOffset,
                                        child: _buildQuantumCore(
                                          theme.primaryColor,
                                          isCompact,
                                        ),
                                      ),
                                    ).animate().scale(
                                      duration: 400.ms,
                                      curve: Curves.easeOutBack,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      DynamicJigsawWrapper(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                      ),
                    SizedBox(height: (_isAnswered || _pendingJigsaw) ? 160.h : 60.h),
                  ],
                ),
                ),
              ],
            ),
        );
      },
    );
  }

  void _checkHarmony(int correctIndex) {
    final double threshold = 110.w;
    if (_ringOffset.dx < -threshold) {
      _onConnect(0, correctIndex);
    } else if (_ringOffset.dx > threshold) {
      _onConnect(1, correctIndex);
    }
  }

  Widget _buildVerbTerminal(
    int index,
    String verb,
    Color primaryColor,
    Alignment alignment,
    int correctIndex,
    bool isCompact,
  ) {
    final isCorrect =
        (_isAnswered || _pendingJigsaw) &&
        _isCorrect != false &&
        index == correctIndex;
    final isWrong = _isAnswered && _isCorrect == false && index != correctIndex;
    final terminalSize = isCompact ? 80.r : 110.r;

    return Align(
      alignment: alignment,
      child:
          Container(
                width: terminalSize,
                height: terminalSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect
                      ? Colors.greenAccent.withValues(alpha: 0.1)
                      : (isWrong
                            ? Colors.redAccent.withValues(alpha: 0.1)
                            : Colors.transparent),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.greenAccent
                        : (isWrong
                              ? Colors.redAccent
                              : primaryColor.withValues(alpha: 0.2)),
                    width: isCompact ? 2.r : 2.5.r,
                  ),
                ),
                child: Center(
                  child: Text(
                    verb.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 13.sp : 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isCorrect
                          ? Colors.greenAccent
                          : (isWrong ? Colors.redAccent : primaryColor),
                    ),
                  ),
                ),
              )
              .animate(target: isCorrect ? 1 : 0)
              .shimmer(duration: 1.seconds)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
    );
  }

  Widget _buildQuantumCore(Color primaryColor, bool isCompact) {
    final Color coreColor = (_isAnswered || _pendingJigsaw)
        ? (_isCorrect != false ? Colors.greenAccent : Colors.redAccent)
        : primaryColor;
    final coreSize = isCompact ? 50.r : 70.r;
    final innerSize = isCompact ? 14.r : 20.r;

    return Container(
      width: coreSize,
      height: coreSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: coreColor,
        boxShadow: [
          BoxShadow(
            color: coreColor.withValues(alpha: 0.4),
            blurRadius: isCompact ? 14 : 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
      ),
    );
  }
}

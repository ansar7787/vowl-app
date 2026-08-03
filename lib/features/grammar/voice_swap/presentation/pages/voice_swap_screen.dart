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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_instruction.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_toggle.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_result.dart';
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';

class VoiceSwapScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VoiceSwapScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.voiceSwap,
  });

  @override
  State<VoiceSwapScreen> createState() => _VoiceSwapScreenState();
}

class _VoiceSwapScreenState extends State<VoiceSwapScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isPassive = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(GameQuest? quest) {
    if (_isAnswered || _isFirstStagePassed || quest == null) return;

    final selectedVoice = _isPassive ? "Passive" : "Active";
    bool isCorrect =
        selectedVoice.toLowerCase() ==
        (quest.correctAnswerCategory?.toLowerCase() ??
            quest.correctAnswer?.toLowerCase());

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isFirstStagePassed = true;
      });
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(SubmitAnswer(false));
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
              _isFirstStagePassed = false;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            // FIX: was `state.lastAnswerCorrect != null` and `state.lastAnswerCorrect`
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
            title: 'VOICE CRYSTALLIZED!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 580;

                    return Stack(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: isCompact ? 4.h : 10.h),
                            isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: VoiceSwapInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : VoiceSwapInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: isCompact ? 8.h : 20.h),

                            // Context Card
                            Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isCompact ? 14.r : 22.r,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 16.r : 24.r,
                                      ),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      quest.sentence ?? "",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: isCompact ? 15.sp : 20.sp,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2, end: 0),

                            SizedBox(height: 60.h),

                            // Voice Toggle
                            VoiceSwapToggle(
                              isPassive: _isPassive,
                              isAnswered: _isAnswered,
                              primaryColor: theme.primaryColor,
                              isDark: isDark,
                              onToggle: (val) => setState(() => _isPassive = val),
                            ),

                            if (_isAnswered) ...[
                              SizedBox(height: isCompact ? 12.h : 32.h),
                              VoiceSwapResult(
                                isCorrect: _isCorrect == true,
                                quest: quest,
                                isDark: isDark,
                              ),
                            ],

                            const Spacer(),

                            if (!_isAnswered)
                              ScaleButton(
                                    onTap: () => _submitAnswer(quest),
                                    child: Container(
                                      width: double.infinity,
                                      height: isCompact ? 48.h : 65.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          isCompact ? 14.r : 20.r,
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            theme.primaryColor,
                                            theme.primaryColor.withValues(
                                              alpha: 0.8,
                                            ),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: isCompact ? 12 : 20,
                                            offset: Offset(0, isCompact ? 4 : 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "ENGAGE TRANSMUTER",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 13.sp : 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: isCompact ? 2 : 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .shimmer(
                                    duration: 2.seconds,
                                    color: Colors.white24,
                                  ),

                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        ),
                        if (_isFirstStagePassed && !_isAnswered)
                          TypeToConfirmOverlay(
                            expectedText: quest.correctAnswerCategory ?? quest.correctAnswer ?? '',
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitVerbalEvaluation(true),
                            onSkipped: () => _submitVerbalEvaluation(false),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

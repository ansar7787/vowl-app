import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_instruction.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_tube.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_result.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_self_evaluation_card.dart';

class ParagraphSummaryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ParagraphSummaryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.paragraphSummary,
  });

  @override
  State<ParagraphSummaryScreen> createState() => _ParagraphSummaryScreenState();
}

class _ParagraphSummaryScreenState extends State<ParagraphSummaryScreen> {
  final _hapticService = di.sl<HapticService>();

  double _pinchWidth = 1.0;
  bool _isDistilled = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onPinchUpdate(double scale) {
    if (_isAnswered || _isDistilled) return;
    setState(() {
      _pinchWidth = scale.clamp(0.4, 1.0);
      if (_pinchWidth < 0.6) {
        _hapticService.selection();
      }
    });
  }

  void _onPinchEnd() {
    if (_isAnswered || _isDistilled) return;
    if (_pinchWidth < 0.55) {
      _hapticService.heavy();
      setState(() {
        _isDistilled = true;
        _pinchWidth = 0.45;
      });
    } else {
      setState(() => _pinchWidth = 1.0);
    }
  }

  void _submitSelfEvalAnswer(bool isCorrect, ReadingQuest quest) {
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isDistilled = false;
              _pinchWidth = 1.0;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SYNTHESIS EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            ParagraphSummaryInstruction(
                              primaryColor: theme.primaryColor,
                              instruction: quest.instruction,
                            ),
                            SizedBox(height: 24.h),
                            GestureDetector(
                              onScaleUpdate: (details) =>
                                  _onPinchUpdate(details.scale),
                              onScaleEnd: (details) => _onPinchEnd(),
                              child: ParagraphSummaryTube(
                                passage: quest.passage ?? "",
                                keywords: quest.keywords ?? [],
                                color: theme.primaryColor,
                                isDark: isDark,
                                pinchWidth: _pinchWidth,
                                isDistilled: _isDistilled,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _isDistilled
                                  ? "DISTILLATION COMPLETE! THINK OF THE CORE SUMMARY AND REVEAL:"
                                  : "PINCH/SQUEEZE THE TUBE TO DISTILL CORE CONCEPTS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: _isDistilled
                                    ? Colors.greenAccent
                                    : theme.primaryColor.withValues(alpha: 0.6),
                                fontSize: 11.sp,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isDistilled) ...[
                              SizedBox(height: 24.h),
                              ReadingSelfEvaluationCard(
                                correctAnswer: quest.correctAnswer ?? "",
                                explanation: quest.explanation,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                              ),
                            ],
                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ParagraphSummaryResult(
                                quest: quest,
                                isCorrect: _isCorrect == true,
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 60.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

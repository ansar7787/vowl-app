import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_instruction.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_foggy_mirror.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_result.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_self_evaluation_card.dart';

class ReadingInferenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingInference,
  });

  @override
  State<ReadingInferenceScreen> createState() => _ReadingInferenceScreenState();
}

class _ReadingInferenceScreenState extends State<ReadingInferenceScreen> {
  final _hapticService = di.sl<HapticService>();

  final List<Offset> _rubPoints = [];
  double _clarity = 0.0;
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

  void _onRub(Offset point) {
    if (_isAnswered) return;
    setState(() {
      _rubPoints.add(point);
      _clarity = (_rubPoints.length / 100).clamp(0.0, 1.0);
      if (_rubPoints.length % 5 == 0) {
        _hapticService.selection();
      }
    });
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
              _rubPoints.clear();
              _clarity = 0.0;
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
            title: context.tr('reading_games.hidden_layer_synced', fallback: 'HIDDEN LAYER SYNCED!'),
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
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
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
                            ReadingInferenceInstruction(
                              primaryColor: theme.primaryColor,
                              instruction: quest.instruction,
                            ),
                            SizedBox(height: 32.h),

                            ReadingInferenceFoggyMirror(
                              passage: quest.passage ?? "",
                              color: theme.primaryColor,
                              isDark: isDark,
                              isAnswered: _isAnswered,
                              rubPoints: _rubPoints,
                              clarity: _clarity,
                              onRub: _onRub,
                            ),
                            SizedBox(height: 32.h),

                            Text(
                              quest.question?.toUpperCase() ??
                                  "INFER THE HIDDEN TRUTH",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                color: theme.primaryColor,
                                letterSpacing: 1.5,
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
                            SizedBox(height: 24.h),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _clarity >= 0.3 ? 1.0 : 0.3,
                              child: AbsorbPointer(
                                absorbing: _clarity < 0.3 || _isAnswered,
                                child: ReadingSelfEvaluationCard(
                                  correctAnswer: quest.correctAnswer ?? "",
                                  explanation: quest.explanation,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                                ),
                              ),
                            ),

                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ReadingInferenceResult(
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_instruction.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_tube.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_option_rack.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_result.dart';
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';

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
  final _soundService = di.sl<SoundService>();

  double _pinchWidth = 1.0;
  bool _isDistilled = false;
  String? _selectedOption;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _phase1Passed = false;
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

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    final isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    setState(() {
      _selectedOption = selected;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() => _phase1Passed = true);
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitPhase2Evaluation(bool nailedIt) {
    if (_isAnswered && _isCorrect != null) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<ReadingBloc>().add(SubmitAnswer(false));
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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
              _isDistilled = false;
              _phase1Passed = false;
              _pinchWidth = 1.0;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
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
              : Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                                  ? "DISTILLATION COMPLETE! SELECT THE CORE SUMMARY:"
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
                            if (_isDistilled) ...[
                              SizedBox(height: 24.h),
                              ParagraphSummaryOptionRack(
                                options: quest.options ?? [],
                                correctAnswer: quest.correctAnswer ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                                selectedOption: _selectedOption,
                                isAnswered: _isAnswered,
                                onTapOption: (opt) =>
                                    _submitAnswer(opt, quest.correctAnswer ?? ""),
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
                    if (_phase1Passed && (!_isAnswered || _isCorrect == null))
                      TypeToConfirmOverlay(
                        expectedText: quest.correctAnswer ?? '',
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitPhase2Evaluation(true),
                        onSkipped: () => _submitPhase2Evaluation(false),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

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
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_choice_instruction.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_path_painter.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class PrepositionChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrepositionChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prepositionChoice,
  });

  @override
  State<PrepositionChoiceScreen> createState() =>
      _PrepositionChoiceScreenState();
}

class _PrepositionChoiceScreenState extends State<PrepositionChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  List<Offset> _points = [];
  int _targetNode = -1;
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

  void _onPathEnd(int nodeIndex, int correctIndex) {
    if (_isAnswered || _pendingJigsaw) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _targetNode = nodeIndex;
        _pendingJigsaw = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetNode = nodeIndex;
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

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final parts = template.contains("____")
        ? template.split("____")
        : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8.w : 12.w,
                        vertical: isCompact ? 2.h : 4.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected != null
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        selected ?? "      ",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 16.sp : 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    )
                    .animate(target: selected != null ? 1 : 0)
                    .shimmer(duration: 2.seconds),
          ),
        );
      }
    }
    return spans;
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
              _targetNode = -1;
              _pendingJigsaw = false;
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
            title: 'SPATIAL PRO!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest
            : null;
        final options = quest?.options ?? ["IN", "ON", "AT", "UNDER"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.sentenceWithBlank ?? quest.question ?? "";
          String fullSentence = sentence;
          if (sentence.contains("___") && _targetNode != -1) {
            fullSentence = sentence.replaceFirst(
              RegExp(r'_{3,}'),
              options[_targetNode],
            );
          }
          cleanTargetSentence = fullSentence
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
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
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            (isCompact ? 30.h : 40.h) +
                            (isCompact ? 50.h : 80.h) +
                            (isCompact ? 160.h : 260.h) +
                            40.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 5
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(4.0, 15.0)
                            : 4.0;
                        final double gapMiddle = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(6.0, 20.0)
                            : 6.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2.5).clamp(10.0, 30.0)
                            : 10.0;

                        return Column(
                          children: [
                            SizedBox(height: gapTop),
                            isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: PrepositionChoiceInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : PrepositionChoiceInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: gapMiddle),

                            if (quest.prepositionCategory != null) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "CATEGORY: ${quest.prepositionCategory!.toUpperCase()}",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("IN (General) ", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor.withValues(alpha: 0.5))),
                                        Text("> ON (Specific) ", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor.withValues(alpha: 0.7))),
                                        Text("> AT (Very Specific)", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms),
                              SizedBox(height: isCompact ? 12.h : 20.h),
                            ],

                            // Context Card
                            Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(
                                      isCompact ? 14.r : 22.r,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 18.r : 28.r,
                                      ),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: isCompact ? 15.sp : 20.sp,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          height: 1.5,
                                        ),
                                        children: _buildSentenceWithBlank(
                                          quest.sentenceWithBlank ??
                                              quest.question ??
                                              "____ sentence.",
                                          (_isAnswered || _pendingJigsaw) &&
                                                  _targetNode != -1
                                              ? options[_targetNode]
                                              : null,
                                          theme.primaryColor,
                                          isDark,
                                          isCompact,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2, end: 0),

                            // Result Feedback
                            if (_isAnswered) ...[
                              SizedBox(height: isCompact ? 8.h : 24.h),
                              _buildResult(
                                quest,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ],

                            // Path Canvas
                            Expanded(
                              child: _buildPathCanvas(
                                options,
                                quest.correctAnswerIndex ?? 0,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ),

                            SizedBox(height: gapBottom),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      TypeToConfirmOverlay(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                        displayText: "Type the full sentence to lock it in",
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

  Widget _buildPathCanvas(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final startPoint = Offset(
          constraints.maxWidth / 2,
          isCompact ? 20.h : 40.h,
        );
        final List<Offset> nodePoints = [];
        final int count = options.length;
        final double bottomY =
            constraints.maxHeight - (isCompact ? 40.h : 100.h);

        if (count <= 3) {
          nodePoints.addAll(
            [
              Offset(isCompact ? 50.w : 80.w, bottomY),
              Offset(constraints.maxWidth / 2, bottomY),
              Offset(constraints.maxWidth - (isCompact ? 50.w : 80.w), bottomY),
            ].take(count),
          );
        } else {
          nodePoints.addAll([
            Offset(
              isCompact ? 60.w : 90.w,
              bottomY - (isCompact ? 50.h : 100.h),
            ),
            Offset(
              constraints.maxWidth - (isCompact ? 60.w : 90.w),
              bottomY - (isCompact ? 50.h : 100.h),
            ),
            Offset(isCompact ? 60.w : 90.w, bottomY),
            Offset(constraints.maxWidth - (isCompact ? 60.w : 90.w), bottomY),
          ]);
        }

        return GestureDetector(
          onPanUpdate: (details) {
            if (_isAnswered || _pendingJigsaw) return;
            setState(() {
              _points.add(details.localPosition);
            });
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  (isCompact ? 30.r : 50.r)) {
                _onPathEnd(i, correctIndex);
              }
            }
          },
          onPanEnd: (_) => setState(() => _points = []),
          child: CustomPaint(
            size: Size.infinite,
            painter: PrepositionPathPainter(
              points: _points,
              startPoint: startPoint,
              nodes: nodePoints,
              options: options,
              primaryColor: primaryColor,
              isAnswered: _isAnswered || _pendingJigsaw,
              isCorrect: _isCorrect ?? false,
              targetNode: _targetNode,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12.r : 24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: displayColor,
              size: isCompact ? 24.r : 40.r,
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              correct
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 12.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (!isCompact && quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}

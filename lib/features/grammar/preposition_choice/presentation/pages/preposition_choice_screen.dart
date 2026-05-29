import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_choice_instruction.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_path_painter.dart';

class PrepositionChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrepositionChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prepositionChoice,
  });

  @override
  State<PrepositionChoiceScreen> createState() => _PrepositionChoiceScreenState();
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

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onPathEnd(int nodeIndex, int correctIndex) {
    if (_isAnswered) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _targetNode = nodeIndex;
    });
    context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
  }

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
  ) {
    final parts = template.contains("____")
        ? template.split("____")
        : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ).animate(target: selected != null ? 1 : 0).shimmer(duration: 2.seconds),
        ));
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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _points = [];
              _targetNode = -1;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
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
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["IN", "ON", "AT", "UNDER"];

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
              : Column(
                  children: [
                    SizedBox(height: 10.h),
                    PrepositionChoiceInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 20.h),

                    // Context Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.fredoka(
                              fontSize: 20.sp,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.5,
                            ),
                            children: _buildSentenceWithBlank(
                              quest.sentenceWithBlank ?? quest.question ?? "____ sentence.",
                              _isAnswered && _targetNode != -1 ? options[_targetNode] : null,
                              theme.primaryColor,
                              isDark,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                    // Result Feedback
                    if (_isAnswered) ...[
                      SizedBox(height: 24.h),
                      _buildResult(quest, theme.primaryColor, isDark),
                    ],

                    // Path Canvas
                    Expanded(
                      child: _buildPathCanvas(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPathCanvas(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 40.h);
      final List<Offset> nodePoints = [];
      final int count = options.length;
      final double bottomY = constraints.maxHeight - 100.h;

      if (count <= 3) {
        nodePoints.addAll([
          Offset(80.w, bottomY),
          Offset(constraints.maxWidth / 2, bottomY),
          Offset(constraints.maxWidth - 80.w, bottomY),
        ].take(count));
      } else {
        nodePoints.addAll([
          Offset(90.w, bottomY - 100.h),
          Offset(constraints.maxWidth - 90.w, bottomY - 100.h),
          Offset(90.w, bottomY),
          Offset(constraints.maxWidth - 90.w, bottomY),
        ]);
      }

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _points.add(details.localPosition);
          });
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 50.r) {
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
            isAnswered: _isAnswered,
            isCorrect: _isCorrect ?? false,
            targetNode: _targetNode,
            isDark: isDark,
          ),
        ),
      );
    });
  }

  Widget _buildResult(GrammarQuest quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
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
              size: 40.r,
            ),
            SizedBox(height: 12.h),
            Text(
              correct ? "CORRECT!" : "INCORRECT",
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
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

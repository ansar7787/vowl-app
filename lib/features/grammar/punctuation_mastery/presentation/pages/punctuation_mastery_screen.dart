import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/widgets/punctuation_mastery_instruction.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/widgets/punctuation_sticker_sheet.dart';

class PunctuationMasteryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PunctuationMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.punctuationMastery,
  });

  @override
  State<PunctuationMasteryScreen> createState() => _PunctuationMasteryScreenState();
}

class _PunctuationMasteryScreenState extends State<PunctuationMasteryScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final Map<int, String> _placedStickers = {};
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

  void _onStick(int index, String mark) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _placedStickers[index] = mark);
  }

  void _submitAnswer(GameQuest quest) {
    if (_isAnswered) return;

    final words = (quest.sentence ?? "").split(" ");
    String result = "";
    for (int i = 0; i < words.length; i++) {
      result += words[i];
      if (_placedStickers.containsKey(i)) {
        result += _placedStickers[i]!;
      }
      if (i < words.length - 1) result += " ";
    }

    bool isCorrect = result.trim().toLowerCase() == (quest.correctAnswer ?? "").trim().toLowerCase();

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
    });
    context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
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
              _placedStickers.clear();
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
            title: 'PUNCTUATION PRO!',
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
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final marks = [".", ",", "!", "?", ";", ":"];

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

                    return Column(
                      children: [
                        SizedBox(height: isCompact ? 4.h : 10.h),
                        isCompact
                            ? SizedBox(
                                height: 25.h,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: PunctuationMasteryInstruction(primaryColor: theme.primaryColor),
                                ),
                              )
                            : PunctuationMasteryInstruction(primaryColor: theme.primaryColor),
                        SizedBox(height: isCompact ? 8.h : 20.h),

                        // Context Card with Sticker Slots
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isCompact ? 14.r : 22.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(isCompact ? 18.r : 28.r),
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: _buildStickerSentence(
                              quest.sentence ?? "Missing sentence.",
                              theme.primaryColor,
                              isDark,
                              isCompact,
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                        // Result
                        if (_isAnswered) ...[
                          SizedBox(height: isCompact ? 12.h : 32.h),
                          _buildResult(quest, theme.primaryColor, isDark, isCompact),
                        ],

                        SizedBox(height: isCompact ? 16.h : 48.h),

                        // Sticker Sheet
                        if (!_isAnswered)
                          PunctuationStickerSheet(
                            marks: marks,
                            primaryColor: theme.primaryColor,
                          ),

                        const Spacer(),

                        // Submit Button
                        if (!_isAnswered)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ScaleButton(
                              onTap: () => _submitAnswer(quest),
                              child: Container(
                                width: double.infinity,
                                height: isCompact ? 48.h : 65.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor,
                                      theme.primaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(alpha: 0.4),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "FINALIZE ARCHITECTURE",
                                    style: TextStyle(
                                      fontFamily: 'Outfit', 
                                      fontSize: isCompact ? 13.sp : 16.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: isCompact ? 12.h : 40.h),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildStickerSentence(String sentence, Color primaryColor, bool isDark, bool isCompact) {
    final words = sentence.split(" ");
    final double slotSize = isCompact ? 26.r : 34.r;
    final double wordFontSize = isCompact ? 15.sp : 20.sp;
    final double markFontSize = isCompact ? 15.sp : 20.sp;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4.w,
      runSpacing: isCompact ? 6.h : 12.h,
      children: List.generate(words.length * 2, (index) {
        if (index % 2 == 0) {
          return Text(
            words[index ~/ 2],
            style: TextStyle(
              fontFamily: 'Outfit', 
              fontSize: wordFontSize,
              color: isDark ? Colors.white : Colors.black87,
            ),
          );
        } else {
          final slotIndex = index ~/ 2;
          final mark = _placedStickers[slotIndex];
          return DragTarget<String>(
            onAcceptWithDetails: (details) => _onStick(slotIndex, details.data),
            builder: (context, candidateData, rejectedData) {
              final isHighlight = candidateData.isNotEmpty;
              return Container(
                width: slotSize,
                height: slotSize,
                decoration: BoxDecoration(
                  color: mark != null
                      ? primaryColor
                      : (isHighlight
                          ? primaryColor.withValues(alpha: 0.3)
                          : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHighlight || mark != null
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.15),
                    width: isHighlight ? 2 : 1.5,
                    style: mark != null ? BorderStyle.none : BorderStyle.solid,
                  ),
                  boxShadow: [
                    if (mark != null)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Center(
                  child: mark != null
                      ? GestureDetector(
                          onTap: () {
                            if (_isAnswered) return;
                            _hapticService.selection();
                            setState(() => _placedStickers.remove(slotIndex));
                          },
                          child: Text(
                            mark,
                            style: TextStyle(
                              fontFamily: 'Outfit', 
                              fontSize: markFontSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ).animate().shimmer(duration: 2.seconds),
                        )
                      : (isHighlight
                          ? Icon(Icons.add, color: primaryColor, size: isCompact ? 14.r : 18.r)
                          : null),
                ),
              )
              .animate(target: mark != null ? 1 : 0)
              .scale(duration: 300.ms, curve: Curves.easeOutBack);
            },
          );
        }
      }),
    );
  }

  Widget _buildResult(GameQuest quest, Color primaryColor, bool isDark, bool isCompact) {
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
              correct ? "CORRECT!" : "INCORRECT",
              style: TextStyle(
                fontFamily: 'Outfit', 
                fontSize: isCompact ? 12.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              "CORRECT SENTENCE:",
              style: TextStyle(
                fontFamily: 'Outfit', 
                fontSize: isCompact ? 10.sp : 12.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: isCompact ? 3.h : 6.h),
            Text(
              quest.correctAnswer ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit', 
                fontSize: isCompact ? 14.sp : 20.sp,
                fontWeight: FontWeight.w600,
                color: displayColor,
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
